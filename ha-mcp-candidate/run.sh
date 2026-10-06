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

# `AdapterSettings::default()` turns Roon discovery on. Keep this candidate
# isolated from playback services even when its Supervisor /data volume is
# fresh or reused; the candidate exists only to verify the HA MCP read path.
export UHC_CONFIG_DIR=/data/uhc-ha-mcp-candidate
export UHC_DATA_DIR=/data/uhc-ha-mcp-candidate
mkdir -p "$UHC_CONFIG_DIR/unified-hifi"
cat > "$UHC_CONFIG_DIR/unified-hifi/app-settings.json" <<'SETTINGS'
{"adapters":{"roon":false,"upnp":false,"openhome":false,"lms":false,"hqplayer":false,"spotify":false,"applemusic":false,"musicassistant":false,"mqtt":false}}
SETTINGS

exec /app/unified-hifi-control
