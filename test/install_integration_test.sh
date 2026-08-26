#!/bin/sh
# Proves run.sh's Home Assistant integration install (#613) against a stub
# config directory: fresh install, no-op when current, upgrade, refusal to
# clobber a newer or a user-owned or an edited copy, opt-out, and every
# non-fatal failure path.
#
# Run it the way production runs run.sh - busybox sh + jq on Alpine, as a
# non-root user so file permissions actually apply:
#
#   docker run --rm -v "$PWD:/work:ro" alpine:3.20 sh -c \
#     'apk add -q jq && adduser -D -H tester && \
#      su tester -s /bin/sh -c "sh /work/test/install_integration_test.sh /work"'
set -u

REPO="${1:-/work}"
RUN_SH="${REPO}/unified-hifi-control/run.sh"
WORK="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() { chmod -R u+w "$WORK" 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Harness: rewrite run.sh's four absolute paths to the stub tree and stop it
# just before it would exec the UHC binary, printing what it decided.
# ---------------------------------------------------------------------------
build_script() {
    sed \
        -e "s|^OPTIONS_FILE=/data/options.json|OPTIONS_FILE=${1}/options.json|" \
        -e "s|^INTEGRATION_SOURCE=/app/custom_components/unified_hifi_control|INTEGRATION_SOURCE=${1}/image/custom_components/unified_hifi_control|" \
        -e "s|^HA_CONFIG_DIR=/homeassistant|HA_CONFIG_DIR=${1}/homeassistant|" \
        -e "s|^exec /app/unified-hifi-control|printf 'RESULT status=%s version=%s detail=%s addon=%s\\n' \"\$UHC_HA_INTEGRATION_STATUS\" \"\$UHC_HA_INTEGRATION_VERSION\" \"\$UHC_HA_INTEGRATION_DETAIL\" \"\$UHC_ADDON\"|" \
        "$RUN_SH" >"${1}/run.sh"
}

# make_case <name> <bundled version> [options json]
make_case() {
    CASE="${WORK}/$1"
    rm -rf "$CASE"
    mkdir -p "${CASE}/image/custom_components/unified_hifi_control" "${CASE}/homeassistant"
    printf '{"domain":"unified_hifi_control","version":"%s"}\n' "$2" \
        >"${CASE}/image/custom_components/unified_hifi_control/manifest.json"
    printf 'MARKER bundled %s\n' "$2" \
        >"${CASE}/image/custom_components/unified_hifi_control/__init__.py"
    OPTIONS_JSON="${3:-}"
    [ -n "$OPTIONS_JSON" ] || OPTIONS_JSON='{}'
    printf '%s\n' "$OPTIONS_JSON" >"${CASE}/options.json"
    build_script "$CASE"
    DEST="${CASE}/homeassistant/custom_components/unified_hifi_control"
}

run_case() {
    # SUPERVISOR_TOKEN deliberately unset: the MQTT block must still be inert
    # and must not affect the integration result.
    (cd "$CASE" && sh ./run.sh) >"${CASE}/out.log" 2>&1
    RC=$?
    RESULT="$(grep '^RESULT ' "${CASE}/out.log" || true)"
}

check() {
    if [ "$2" = "$3" ]; then
        PASS=$((PASS + 1))
        printf 'ok   %s\n' "$1"
    else
        FAIL=$((FAIL + 1))
        printf 'FAIL %s\n     expected: %s\n     actual:   %s\n' "$1" "$3" "$2"
    fi
}

check_contains() {
    if printf '%s' "$2" | grep -qF -- "$3"; then
        PASS=$((PASS + 1))
        printf 'ok   %s\n' "$1"
    else
        FAIL=$((FAIL + 1))
        printf 'FAIL %s\n     expected to contain: %s\n     actual: %s\n' "$1" "$3" "$2"
    fi
}

status_of() { printf '%s' "$RESULT" | sed -n 's/^RESULT status=\([^ ]*\).*/\1/p'; }

# ---------------------------------------------------------------------------
# 1. Fresh install
# ---------------------------------------------------------------------------
make_case fresh 1.2.0
run_case
check "fresh: run.sh exits 0" "$RC" "0"
check "fresh: status" "$(status_of)" "installed"
check "fresh: __init__.py copied" "$(cat "${DEST}/__init__.py" 2>/dev/null)" "MARKER bundled 1.2.0"
check "fresh: stamp written" "$(cat "${DEST}/.installed_by_uhc_addon" 2>/dev/null)" "version=1.2.0"
check "fresh: checksums written" "$([ -s "${DEST}/.uhc_addon_checksums" ] && echo yes)" "yes"
check "fresh: no staging left behind" "$(ls -d "${DEST}".uhc-* 2>/dev/null | wc -l | tr -d ' ')" "0"
check_contains "fresh: log names the version" "$(cat "${CASE}/out.log")" "version 1.2.0"
check_contains "fresh: log demands one HA restart" "$(cat "${CASE}/out.log")" "RESTART HOME ASSISTANT ONCE"
check_contains "fresh: log says where UHC then appears" "$(cat "${CASE}/out.log")" "Devices & services > Discovered"
check_contains "fresh: exports addon marker" "$RESULT" "addon=1"

# ---------------------------------------------------------------------------
# 2. Already current: second run is a no-op
# ---------------------------------------------------------------------------
FIRST_INODE="$(ls -i "${DEST}/__init__.py" | awk '{print $1}')"
run_case
check "current: status" "$(status_of)" "current"
check "current: file was not rewritten" \
    "$(ls -i "${DEST}/__init__.py" | awk '{print $1}')" "$FIRST_INODE"
check_contains "current: log says up to date" "$(cat "${CASE}/out.log")" "already up to date"
check_contains "current: log does not nag about restarting" \
    "$(grep -c 'RESTART HOME ASSISTANT' "${CASE}/out.log")" "0"

# Home Assistant's own __pycache__ must not read as a user edit.
mkdir -p "${DEST}/__pycache__"
printf 'compiled\n' >"${DEST}/__pycache__/__init__.cpython-312.pyc"
run_case
check "current: __pycache__ is not an edit" "$(status_of)" "current"

# ---------------------------------------------------------------------------
# 3. Older installed copy is upgraded
# ---------------------------------------------------------------------------
make_case upgrade 1.3.0
mkdir -p "$DEST"
printf '{"domain":"unified_hifi_control","version":"1.2.0"}\n' >"${DEST}/manifest.json"
printf 'MARKER bundled 1.2.0\n' >"${DEST}/__init__.py"
(cd "$DEST" && find . -type f ! -name '.uhc_addon_checksums' ! -name '.installed_by_uhc_addon' \
    -exec sha256sum {} \; >.uhc_addon_checksums)
printf 'version=1.2.0\n' >"${DEST}/.installed_by_uhc_addon"
run_case
check "upgrade: status" "$(status_of)" "updated"
check "upgrade: content replaced" "$(cat "${DEST}/__init__.py")" "MARKER bundled 1.3.0"
check "upgrade: stamp advanced" "$(cat "${DEST}/.installed_by_uhc_addon")" "version=1.3.0"
check_contains "upgrade: log names both versions" "$(cat "${CASE}/out.log")" "1.2.0 -> 1.3.0"
check_contains "upgrade: log demands one HA restart" "$(cat "${CASE}/out.log")" "RESTART HOME ASSISTANT ONCE"

# A pre-release of the same core version is older than the release.
make_case prerelease 1.4.0
mkdir -p "$DEST"
printf '{"version":"1.4.0-alpha.2"}\n' >"${DEST}/manifest.json"
printf 'MARKER bundled 1.4.0-alpha.2\n' >"${DEST}/__init__.py"
(cd "$DEST" && find . -type f ! -name '.uhc_addon_checksums' ! -name '.installed_by_uhc_addon' \
    -exec sha256sum {} \; >.uhc_addon_checksums)
printf 'version=1.4.0-alpha.2\n' >"${DEST}/.installed_by_uhc_addon"
run_case
check "prerelease: release beats pre-release of same core" "$(status_of)" "updated"

# ---------------------------------------------------------------------------
# 4. Newer installed copy is refused
# ---------------------------------------------------------------------------
make_case newer 1.2.0
mkdir -p "$DEST"
printf '{"version":"2.0.0"}\n' >"${DEST}/manifest.json"
printf 'MARKER user has 2.0.0\n' >"${DEST}/__init__.py"
(cd "$DEST" && find . -type f ! -name '.uhc_addon_checksums' ! -name '.installed_by_uhc_addon' \
    -exec sha256sum {} \; >.uhc_addon_checksums)
printf 'version=2.0.0\n' >"${DEST}/.installed_by_uhc_addon"
run_case
check "newer: status" "$(status_of)" "skipped_newer"
check "newer: content untouched" "$(cat "${DEST}/__init__.py")" "MARKER user has 2.0.0"
check_contains "newer: log explains" "$(cat "${CASE}/out.log")" "leaving it alone"

# ---------------------------------------------------------------------------
# 5. A copy the add-on did not install (HACS / manual) is never touched
# ---------------------------------------------------------------------------
make_case foreign 9.9.9
mkdir -p "$DEST"
printf '{"version":"0.0.1"}\n' >"${DEST}/manifest.json"
printf 'MARKER installed by HACS\n' >"${DEST}/__init__.py"
run_case
check "foreign: status" "$(status_of)" "skipped_foreign"
check "foreign: content untouched even though ours is newer" \
    "$(cat "${DEST}/__init__.py")" "MARKER installed by HACS"

# ---------------------------------------------------------------------------
# 6. An edited copy of ours is never overwritten
# ---------------------------------------------------------------------------
make_case modified 9.9.9
mkdir -p "$DEST"
printf '{"version":"1.0.0"}\n' >"${DEST}/manifest.json"
printf 'MARKER original\n' >"${DEST}/__init__.py"
(cd "$DEST" && find . -type f ! -name '.uhc_addon_checksums' ! -name '.installed_by_uhc_addon' \
    -exec sha256sum {} \; >.uhc_addon_checksums)
printf 'version=1.0.0\n' >"${DEST}/.installed_by_uhc_addon"
printf 'MARKER hand-edited by the user\n' >"${DEST}/__init__.py"
run_case
check "modified: status" "$(status_of)" "skipped_modified"
check "modified: edit survives" "$(cat "${DEST}/__init__.py")" "MARKER hand-edited by the user"

# ---------------------------------------------------------------------------
# 7. Opt-out. jq's `//` treats an explicit false as empty, so this is the
#    case that proves the option is actually respected.
# ---------------------------------------------------------------------------
make_case optout 1.2.0 '{"install_integration": false}'
run_case
check "opt-out: status" "$(status_of)" "skipped_disabled"
check "opt-out: nothing created" "$([ -e "$DEST" ] && echo created || echo absent)" "absent"

make_case optin_explicit 1.2.0 '{"install_integration": true}'
run_case
check "explicit true: status" "$(status_of)" "installed"

make_case optout_absent 1.2.0 '{"port": 8088}'
run_case
check "option absent: defaults to installing" "$(status_of)" "installed"

# The same trap on the MQTT option.
make_case mqtt_optout 1.2.0 '{"publish_to_home_assistant": false}'
run_case
check_contains "publish_to_home_assistant false is respected" \
    "$(cat "${CASE}/out.log")" "publish_to_home_assistant is off"

# ---------------------------------------------------------------------------
# 8. Failure modes are non-fatal
# ---------------------------------------------------------------------------
make_case readonly 1.2.0
chmod 555 "${CASE}/homeassistant"
run_case
check "read-only: run.sh still exits 0" "$RC" "0"
check "read-only: status" "$(status_of)" "skipped_readonly"
check_contains "read-only: log says UHC starts anyway" "$(cat "${CASE}/out.log")" "UHC starts normally"
chmod 755 "${CASE}/homeassistant"

make_case unmapped 1.2.0
rmdir "${CASE}/homeassistant"
run_case
check "unmapped: run.sh still exits 0" "$RC" "0"
check "unmapped: status" "$(status_of)" "skipped_unmapped"
check_contains "unmapped: log says UHC starts anyway" "$(cat "${CASE}/out.log")" "UHC starts normally"

make_case no_bundle 1.2.0
rm -rf "${CASE}/image/custom_components"
run_case
check "no bundled integration: run.sh still exits 0" "$RC" "0"
check "no bundled integration: status" "$(status_of)" "unavailable"
check_contains "no bundled integration: log points at HACS" "$(cat "${CASE}/out.log")" "HACS"

make_case no_options 1.2.0
rm -f "${CASE}/options.json"
run_case
check "no options.json: still installs by default" "$(status_of)" "installed"

# custom_components exists but is a file, so mkdir -p must fail cleanly.
make_case blocked 1.2.0
printf 'not a directory\n' >"${CASE}/homeassistant/custom_components"
run_case
check "blocked path: run.sh still exits 0" "$RC" "0"
check "blocked path: status" "$(status_of)" "failed"
check_contains "blocked path: log says UHC starts anyway" "$(cat "${CASE}/out.log")" "UHC starts normally"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
