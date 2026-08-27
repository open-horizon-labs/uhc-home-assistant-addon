#!/bin/sh
# Maps the add-on's Supervisor-managed options (/data/options.json) to the
# environment variables unified-hifi-control reads directly. This image has
# no s6-overlay/bashio (it wraps the plain muness/unified-hifi-control
# runtime image), so the mapping is done by hand with jq.
set -eu

OPTIONS_FILE=/data/options.json

# jq's `//` yields its right side for `false` as well as for null, so
# `.foo // true` reads an explicit `false` back as `true` and silently
# ignores the opt-out. Compare against `false` instead: only that value
# turns the option off, while null/absent still defaults on.
bool_option_default_true() {
    jq -r --arg key "$1" \
        'if .[$key] == false then "false" else "true" end' \
        "$OPTIONS_FILE" 2>/dev/null || echo "true"
}

if [ -f "$OPTIONS_FILE" ]; then
    UHC_PORT="$(jq -r '.port // 8088' "$OPTIONS_FILE")"
    RUST_LOG="$(jq -r '.log_level // "info"' "$OPTIONS_FILE")"
    REQUIRE_CONTROLLER_AUTH="$(jq -r '.require_controller_auth // false' "$OPTIONS_FILE")"
    PUBLISH_TO_HOME_ASSISTANT="$(bool_option_default_true publish_to_home_assistant)"
    INSTALL_INTEGRATION="$(bool_option_default_true install_integration)"
else
    echo "run.sh: ${OPTIONS_FILE} not found, using defaults" >&2
    UHC_PORT=8088
    RUST_LOG=info
    REQUIRE_CONTROLLER_AUTH=false
    PUBLISH_TO_HOME_ASSISTANT=true
    INSTALL_INTEGRATION=true
fi

export UHC_PORT
export RUST_LOG

if [ "$REQUIRE_CONTROLLER_AUTH" = "true" ]; then
    export UHC_REQUIRE_CONTROLLER_AUTH=1
fi

# Tell UHC it is running as the Home Assistant add-on (#613). UHC uses this
# to pick add-on-appropriate defaults - most importantly, not switching the
# MQTT publisher on by itself, because under the add-on the custom
# integration installed below is the way zones reach Home Assistant.
export UHC_ADDON=1

# Ingress (Tier 2, #581): tell UHC it may honor Supervisor-proxied ingress
# requests. This is gate 1 of 3 — UHC additionally requires the TCP peer to
# be on the Supervisor's proxy network (172.30.32.0/23) and a well-formed
# X-Ingress-Path header before it treats a request as ingress, so setting
# this here does not weaken the direct-port posture.
export UHC_INGRESS=1

# ---------------------------------------------------------------------------
# Home Assistant custom integration install (#613)
# ---------------------------------------------------------------------------
#
# An add-on cannot register entities: only an integration running inside Home
# Assistant core can. But an add-on *can* put that integration where core
# will find it. `custom_components/unified_hifi_control` is baked into the
# UHC image this add-on is built FROM, so the copy installed here is always
# the one that shipped with this UHC version. config.yaml maps Home
# Assistant's own config directory at /homeassistant, and this block copies
# the integration in when it is absent or older than the bundled one.
#
# Every path here is best-effort. A missing, unmapped or read-only config
# directory logs one line and falls through: UHC still starts, its web UI
# still works, and nothing about the rest of the add-on depends on this.
INTEGRATION_SOURCE=/app/custom_components/unified_hifi_control
HA_CONFIG_DIR=/homeassistant
INTEGRATION_DEST="${HA_CONFIG_DIR}/custom_components/unified_hifi_control"
# Written by this script into the copy it installs. Its absence is how we
# recognise a copy somebody else put there (HACS, a manual copy) and leave
# it alone.
STAMP_NAME=.installed_by_uhc_addon
SUMS_NAME=.uhc_addon_checksums

# Reported to UHC so its Settings page can say the same thing the log says.
UHC_HA_INTEGRATION_STATUS=unavailable
UHC_HA_INTEGRATION_VERSION=""
UHC_HA_INTEGRATION_DETAIL=""

manifest_version() {
    [ -f "$1" ] || return 0
    jq -r '.version // empty' "$1" 2>/dev/null || true
}

# Compare two manifest versions, printing lt/eq/gt (or eq when either side is
# unparseable, so an unreadable version never triggers an overwrite).
# Ordering is the semver one: numeric on the dotted core, and a release
# outranks any pre-release of the same core ("1.2.0" > "1.2.0-alpha.2").
version_cmp() {
    if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
        echo eq
        return 0
    fi
    jq -rn --arg a "$1" --arg b "$2" '
        def vkey:
            (split("-")) as $parts
            | (($parts[0] | split(".") | map(tonumber? // 0)) + [0, 0, 0])[0:3] as $core
            | $core
              + [ (if ($parts | length) > 1 then 0 else 1 end) ]
              + [ ($parts[1:] | join("-")) ];
        ($a | vkey) as $ka | ($b | vkey) as $kb
        | if $ka < $kb then "lt" elif $ka > $kb then "gt" else "eq" end
    ' 2>/dev/null || echo eq
}

# True when the installed copy still matches the checksums recorded when this
# add-on installed it. Files Home Assistant adds itself (__pycache__) are not
# listed, so they do not count as edits; a changed or deleted shipped file
# does.
integration_untouched() {
    [ -f "${1}/${SUMS_NAME}" ] || return 1
    (cd "$1" && sha256sum -c "$SUMS_NAME") >/dev/null 2>&1
}

# Copy INTEGRATION_SOURCE into place via a staging directory, so a failure
# part-way through never leaves Home Assistant loading half an integration.
write_integration() {
    _version="$1"
    _staging="${INTEGRATION_DEST}.uhc-staging"
    _previous="${INTEGRATION_DEST}.uhc-previous"

    rm -rf "$_staging" "$_previous" 2>/dev/null || true
    mkdir -p "$_staging" 2>/dev/null || return 1
    cp -a "${INTEGRATION_SOURCE}/." "${_staging}/" 2>/dev/null || return 1

    (
        cd "$_staging" || exit 1
        # SC2094: the redirect creates the sums file before find walks the
        # tree, but `! -name` excludes it, so it is written and never read.
        # shellcheck disable=SC2094
        find . -type f ! -name "$STAMP_NAME" ! -name "$SUMS_NAME" \
            -exec sha256sum {} \; >"$SUMS_NAME"
    ) 2>/dev/null || return 1
    printf 'version=%s\n' "$_version" >"${_staging}/${STAMP_NAME}" 2>/dev/null || return 1

    if [ -e "$INTEGRATION_DEST" ]; then
        mv "$INTEGRATION_DEST" "$_previous" 2>/dev/null || return 1
    fi
    if ! mv "$_staging" "$INTEGRATION_DEST" 2>/dev/null; then
        # Put back whatever was there before rather than leaving nothing.
        [ -e "$_previous" ] && mv "$_previous" "$INTEGRATION_DEST" 2>/dev/null
        return 1
    fi
    rm -rf "$_previous" 2>/dev/null || true
    return 0
}

install_integration() {
    if [ "$INSTALL_INTEGRATION" != "true" ]; then
        UHC_HA_INTEGRATION_STATUS=skipped_disabled
        echo "run.sh: install_integration is off; not touching Home Assistant's custom_components." >&2
        return 0
    fi

    if [ ! -f "${INTEGRATION_SOURCE}/manifest.json" ]; then
        UHC_HA_INTEGRATION_STATUS=unavailable
        UHC_HA_INTEGRATION_DETAIL="this UHC image does not bundle the integration"
        echo "run.sh: this UHC image does not bundle the Home Assistant integration; install it through HACS instead." >&2
        return 0
    fi

    SOURCE_VERSION="$(manifest_version "${INTEGRATION_SOURCE}/manifest.json")"
    UHC_HA_INTEGRATION_VERSION="$SOURCE_VERSION"

    if [ ! -d "$HA_CONFIG_DIR" ]; then
        UHC_HA_INTEGRATION_STATUS=skipped_unmapped
        UHC_HA_INTEGRATION_DETAIL="${HA_CONFIG_DIR} is not mapped"
        echo "run.sh: ${HA_CONFIG_DIR} is not mapped, so the Home Assistant integration cannot be installed. UHC starts normally." >&2
        return 0
    fi

    if [ ! -w "$HA_CONFIG_DIR" ]; then
        UHC_HA_INTEGRATION_STATUS=skipped_readonly
        UHC_HA_INTEGRATION_DETAIL="${HA_CONFIG_DIR} is read-only"
        echo "run.sh: ${HA_CONFIG_DIR} is read-only, so the Home Assistant integration cannot be installed. UHC starts normally." >&2
        return 0
    fi

    if [ ! -d "$INTEGRATION_DEST" ]; then
        if ! mkdir -p "${HA_CONFIG_DIR}/custom_components" 2>/dev/null; then
            UHC_HA_INTEGRATION_STATUS=failed
            UHC_HA_INTEGRATION_DETAIL="could not create ${HA_CONFIG_DIR}/custom_components"
            echo "run.sh: could not create ${HA_CONFIG_DIR}/custom_components; the Home Assistant integration was not installed. UHC starts normally." >&2
            return 0
        fi
        if write_integration "$SOURCE_VERSION"; then
            UHC_HA_INTEGRATION_STATUS=installed
            echo "run.sh: installed the Unified Hi-Fi Control integration (version ${SOURCE_VERSION:-unknown}) into ${INTEGRATION_DEST}." >&2
            announce_restart
        else
            UHC_HA_INTEGRATION_STATUS=failed
            UHC_HA_INTEGRATION_DETAIL="could not write ${INTEGRATION_DEST}"
            echo "run.sh: could not write ${INTEGRATION_DEST}; the Home Assistant integration was not installed. UHC starts normally." >&2
        fi
        return 0
    fi

    INSTALLED_VERSION="$(manifest_version "${INTEGRATION_DEST}/manifest.json")"

    if [ ! -f "${INTEGRATION_DEST}/${STAMP_NAME}" ]; then
        UHC_HA_INTEGRATION_STATUS=skipped_foreign
        UHC_HA_INTEGRATION_VERSION="$INSTALLED_VERSION"
        UHC_HA_INTEGRATION_DETAIL="an existing copy this add-on did not install"
        echo "run.sh: ${INTEGRATION_DEST} already exists and was not installed by this add-on (version ${INSTALLED_VERSION:-unknown}); leaving it alone. Delete it if you want the add-on to manage it." >&2
        return 0
    fi

    if ! integration_untouched "$INTEGRATION_DEST"; then
        UHC_HA_INTEGRATION_STATUS=skipped_modified
        UHC_HA_INTEGRATION_VERSION="$INSTALLED_VERSION"
        UHC_HA_INTEGRATION_DETAIL="the installed copy has local edits"
        echo "run.sh: ${INTEGRATION_DEST} has been edited since the add-on installed it; leaving it alone." >&2
        return 0
    fi

    case "$(version_cmp "$SOURCE_VERSION" "$INSTALLED_VERSION")" in
        eq)
            UHC_HA_INTEGRATION_STATUS=current
            echo "run.sh: the Unified Hi-Fi Control integration in Home Assistant is already up to date (version ${INSTALLED_VERSION:-unknown})." >&2
            ;;
        lt)
            UHC_HA_INTEGRATION_STATUS=skipped_newer
            UHC_HA_INTEGRATION_VERSION="$INSTALLED_VERSION"
            UHC_HA_INTEGRATION_DETAIL="the installed copy is newer"
            echo "run.sh: Home Assistant already has a newer Unified Hi-Fi Control integration (${INSTALLED_VERSION} > ${SOURCE_VERSION}); leaving it alone." >&2
            ;;
        *)
            if write_integration "$SOURCE_VERSION"; then
                UHC_HA_INTEGRATION_STATUS=updated
                echo "run.sh: updated the Unified Hi-Fi Control integration in Home Assistant (${INSTALLED_VERSION:-unknown} -> ${SOURCE_VERSION:-unknown})." >&2
                announce_restart
            else
                UHC_HA_INTEGRATION_STATUS=failed
                UHC_HA_INTEGRATION_VERSION="$INSTALLED_VERSION"
                UHC_HA_INTEGRATION_DETAIL="could not write ${INTEGRATION_DEST}"
                echo "run.sh: could not update ${INTEGRATION_DEST}; the previous copy is still in place. UHC starts normally." >&2
            fi
            ;;
    esac
    return 0
}

# Home Assistant only loads custom integrations at startup, so a freshly
# installed one is invisible until a restart. The add-on log is the wrong
# place to say so -- nobody reads an add-on log to discover a pending step --
# so raise a notification inside Home Assistant itself, the way the rest of
# HA surfaces "action needed". Fixed notification_id so repeated starts
# replace the notice instead of stacking copies.
NOTIFICATION_ID=unified_hifi_control_restart_required

# Every call here is best-effort: no token, no core API, an HTTP failure or a
# slow response must never delay or fail the add-on. Hence `|| true` and a
# short timeout on each.
ha_api() {
    _method="$1"
    _path="$2"
    _body="${3:-}"
    [ -n "${SUPERVISOR_TOKEN:-}" ] || return 1
    if [ -n "$_body" ]; then
        curl -sSL --fail --max-time 10 -X "$_method" \
            -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$_body" \
            "http://supervisor/core/api/${_path}" >/dev/null 2>&1
    else
        curl -sSL --fail --max-time 10 -X "$_method" \
            -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
            "http://supervisor/core/api/${_path}" 2>/dev/null
    fi
}

announce_restart() {
    echo "run.sh: RESTART HOME ASSISTANT ONCE to pick it up (Settings > System > Restart). After the restart, Unified Hi-Fi Control appears under Settings > Devices & services > Discovered." >&2

    _message="Unified Hi-Fi Control installed its Home Assistant integration. **Restart Home Assistant once** to finish setting it up: Settings → System → Restart.

After the restart it appears under Settings → Devices & services → Discovered, and your zones become media players you can control, group and browse.

This notice clears itself once the restart is done."
    _payload="$(jq -n --arg t "Unified Hi-Fi Control: restart to finish setup" \
                      --arg m "$_message" \
                      --arg i "$NOTIFICATION_ID" \
                      '{title:$t, message:$m, notification_id:$i}' 2>/dev/null)" || return 0
    if ha_api POST "services/persistent_notification/create" "$_payload"; then
        echo "run.sh: raised a Home Assistant notification about the required restart." >&2
    else
        echo "run.sh: could not raise the restart notification in Home Assistant (see the line above for the step)." >&2
    fi
    return 0
}

# Once Home Assistant has actually loaded the integration, the restart has
# happened and the notice is stale -- clear it rather than leaving the user
# to dismiss a to-do they already did.
clear_restart_notice() {
    _config="$(ha_api GET "config")" || return 0
    printf '%s' "$_config" \
        | jq -e '.components // [] | index("unified_hifi_control")' >/dev/null 2>&1 || return 0
    _payload="$(jq -n --arg i "$NOTIFICATION_ID" '{notification_id:$i}' 2>/dev/null)" || return 0
    ha_api POST "services/persistent_notification/dismiss" "$_payload" || true
    return 0
}

# `|| true` because a stray non-zero from anything inside must not take the
# add-on down with it under `set -eu`.
install_integration || true
clear_restart_notice || true

export UHC_HA_INTEGRATION_STATUS
export UHC_HA_INTEGRATION_VERSION
export UHC_HA_INTEGRATION_DETAIL

# ---------------------------------------------------------------------------
# MQTT broker details from the Supervisor (#605, re-scoped by #613)
# ---------------------------------------------------------------------------
#
# config.yaml declares `services: [mqtt:want]`, so when an MQTT broker add-on
# (Mosquitto) is installed the Supervisor hands this add-on the broker's
# host, port, and a set of credentials minted for it. Exporting them as
# UHC_MQTT_* means the broker fields in UHC's Settings are filled in already.
#
# What changed in #613: filling them in is no longer the same thing as
# turning publishing on. Under the add-on (UHC_ADDON=1) UHC saves these
# details but leaves the MQTT publisher switched off, because the custom
# integration installed above already delivers zones to Home Assistant with
# no broker involved. Publishing to a broker nobody asked for is not a
# default worth having; a one-click opt-in with nothing to type is. An
# install that already had MQTT running from a previous version keeps
# running - UHC only applies this to a broker configuration it has not seen
# before.
#
# Everything below is best-effort and must never stop UHC from starting: no
# broker installed is the common case, not an error. Each failure path logs
# one line and falls through, and every command that can fail is either the
# condition of an `if` or guarded with `|| true`, because this script runs
# under `set -eu`.
if [ "$PUBLISH_TO_HOME_ASSISTANT" != "true" ]; then
    echo "run.sh: publish_to_home_assistant is off; not passing broker details to UHC" >&2
elif [ -z "${SUPERVISOR_TOKEN:-}" ]; then
    echo "run.sh: no SUPERVISOR_TOKEN available; skipping MQTT auto-configuration" >&2
else
    # --fail turns a non-200 (including the 400 the Supervisor returns when
    # no MQTT service is provisioned) into a non-zero exit and empty output.
    # --max-time keeps a wedged Supervisor from delaying startup indefinitely.
    MQTT_SERVICE="$(curl -sSL --fail --max-time 10 \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        http://supervisor/services/mqtt 2>/dev/null || true)"

    # Tolerate malformed or unexpected JSON the same way as a failed request:
    # jq exits non-zero, `|| true` absorbs it, and the host ends up empty.
    MQTT_HOST=""
    if [ -n "$MQTT_SERVICE" ]; then
        MQTT_HOST="$(printf '%s' "$MQTT_SERVICE" | jq -r '.data.host // empty' 2>/dev/null || true)"
    fi

    if [ -z "$MQTT_HOST" ]; then
        echo "run.sh: no MQTT broker available from the Supervisor. That is fine - MQTT is optional, and the Home Assistant integration does not use it." >&2
    else
        MQTT_PORT="$(printf '%s' "$MQTT_SERVICE" | jq -r '.data.port // empty' 2>/dev/null || true)"
        MQTT_USERNAME="$(printf '%s' "$MQTT_SERVICE" | jq -r '.data.username // empty' 2>/dev/null || true)"
        MQTT_PASSWORD="$(printf '%s' "$MQTT_SERVICE" | jq -r '.data.password // empty' 2>/dev/null || true)"
        MQTT_SSL="$(printf '%s' "$MQTT_SERVICE" | jq -r '.data.ssl // false' 2>/dev/null || true)"

        export UHC_MQTT_HOST="$MQTT_HOST"
        if [ -n "$MQTT_PORT" ]; then
            export UHC_MQTT_PORT="$MQTT_PORT"
        fi
        if [ -n "$MQTT_USERNAME" ]; then
            export UHC_MQTT_USERNAME="$MQTT_USERNAME"
        fi
        if [ -n "$MQTT_PASSWORD" ]; then
            export UHC_MQTT_PASSWORD="$MQTT_PASSWORD"
        fi
        if [ -n "$MQTT_SSL" ]; then
            export UHC_MQTT_TLS="$MQTT_SSL"
        fi

        # Host and port only — the credentials stay out of the log.
        echo "run.sh: MQTT broker details from the Supervisor are ready in UHC's Settings (${MQTT_HOST}:${MQTT_PORT:-default}); publishing stays off until you turn it on." >&2
    fi
fi

# UHC_CONFIG_DIR is already set to /data via the Dockerfile ENV.
exec /app/unified-hifi-control
