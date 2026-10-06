#!/bin/sh
# Minimal read-validation wrapper. It deliberately does not install the UHC
# Home Assistant integration, make Supervisor REST calls, or configure MQTT.
set -eu

OPTIONS_FILE=/data/options.json
if [ -f "$OPTIONS_FILE" ]; then
    UHC_PORT="$(jq -r '.port // 8089' "$OPTIONS_FILE")"
    RUST_LOG="$(jq -r '.log_level // "info"' "$OPTIONS_FILE")"
    REQUIRE_CONTROLLER_AUTH="$(jq -r '.require_controller_auth // true' "$OPTIONS_FILE")"
else
    UHC_PORT=8089
    RUST_LOG=info
    REQUIRE_CONTROLLER_AUTH=true
fi

export UHC_PORT RUST_LOG UHC_ADDON=1
if [ "$REQUIRE_CONTROLLER_AUTH" = true ]; then
    export UHC_REQUIRE_CONTROLLER_AUTH=1
fi

exec /app/unified-hifi-control
