#!/bin/sh
# Minimal read-validation wrapper. It deliberately does not install the UHC
# Home Assistant integration, make Supervisor REST calls, or configure MQTT.
set -eu

OPTIONS_FILE=/data/options.json
if [ -f "$OPTIONS_FILE" ]; then
    UHC_PORT="$(jq -r '.port // 8089' "$OPTIONS_FILE")"
    RUST_LOG="$(jq -r '.log_level // "info"' "$OPTIONS_FILE")"
else
    UHC_PORT=8089
    RUST_LOG=info
fi

export UHC_PORT RUST_LOG UHC_ADDON=1 UHC_REQUIRE_CONTROLLER_AUTH=1 UHC_MDNS_DISABLE=1 FIRMWARE_AUTO_UPDATE=false

exec /app/unified-hifi-control
