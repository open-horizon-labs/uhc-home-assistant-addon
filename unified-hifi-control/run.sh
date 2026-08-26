#!/bin/sh
# Maps the add-on's Supervisor-managed options (/data/options.json) to the
# environment variables unified-hifi-control reads directly. This image has
# no s6-overlay/bashio (it wraps the plain muness/unified-hifi-control
# runtime image), so the mapping is done by hand with jq.
set -eu

OPTIONS_FILE=/data/options.json

if [ -f "$OPTIONS_FILE" ]; then
    UHC_PORT="$(jq -r '.port // 8088' "$OPTIONS_FILE")"
    RUST_LOG="$(jq -r '.log_level // "info"' "$OPTIONS_FILE")"
    REQUIRE_CONTROLLER_AUTH="$(jq -r '.require_controller_auth // false' "$OPTIONS_FILE")"
    # NOT `.publish_to_home_assistant // true`: jq's `//` yields its right
    # side for `false` as well as for null, so the alternative form would
    # read an explicit `false` back as `true` and ignore the opt-out
    # entirely. Compare against `false` so only that value turns it off,
    # while null/absent still defaults on.
    PUBLISH_TO_HOME_ASSISTANT="$(jq -r 'if .publish_to_home_assistant == false then "false" else "true" end' "$OPTIONS_FILE")"
else
    echo "run.sh: ${OPTIONS_FILE} not found, using defaults" >&2
    UHC_PORT=8088
    RUST_LOG=info
    REQUIRE_CONTROLLER_AUTH=false
    PUBLISH_TO_HOME_ASSISTANT=true
fi

export UHC_PORT
export RUST_LOG

if [ "$REQUIRE_CONTROLLER_AUTH" = "true" ]; then
    export UHC_REQUIRE_CONTROLLER_AUTH=1
fi

# Ingress (Tier 2, #581): tell UHC it may honor Supervisor-proxied ingress
# requests. This is gate 1 of 3 — UHC additionally requires the TCP peer to
# be on the Supervisor's proxy network (172.30.32.0/23) and a well-formed
# X-Ingress-Path header before it treats a request as ingress, so setting
# this here does not weaken the direct-port posture.
export UHC_INGRESS=1

# MQTT auto-configuration (#605). config.yaml declares `services: [mqtt:want]`,
# so when an MQTT broker add-on (Mosquitto) is installed the Supervisor will
# hand this add-on the broker's host, port, and a set of credentials minted
# for it. Exporting them as UHC_MQTT_* is what makes zones and controllers
# show up as Home Assistant entities without the user typing broker details
# into UHC's settings page.
#
# Everything below is best-effort and must never stop UHC from starting: no
# broker installed is the common case, not an error. Each failure path logs
# one line and falls through, and every command that can fail is either the
# condition of an `if` or guarded with `|| true`, because this script runs
# under `set -eu`.
#
# UHC decides what to do with these variables. It will not overwrite broker
# settings the user saved themselves, and re-exporting the same values on
# every restart is a no-op there — so this block does not need to track
# whether it has run before.
if [ "$PUBLISH_TO_HOME_ASSISTANT" != "true" ]; then
    echo "run.sh: publish_to_home_assistant is off; not configuring MQTT" >&2
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
        echo "run.sh: no MQTT broker available from the Supervisor; Home Assistant entities will not be published. Install the Mosquitto broker add-on to enable them." >&2
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
        echo "run.sh: MQTT broker from the Supervisor: ${MQTT_HOST}:${MQTT_PORT:-default}" >&2
    fi
fi

# UHC_CONFIG_DIR is already set to /data via the Dockerfile ENV.
exec /app/unified-hifi-control
