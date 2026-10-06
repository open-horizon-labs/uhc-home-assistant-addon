#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
config="$root/ha-mcp-candidate/config.yaml"
build="$root/ha-mcp-candidate/build.yaml"
run="$root/ha-mcp-candidate/run.sh"

contains() { grep -Fqx -- "$2" "$1"; }
contains "$config" 'slug: uhc_ha_mcp_candidate'
contains "$config" 'homeassistant_api: true'
contains "$config" '  port: 8089'
contains "$config" '  - amd64'
! grep -Eq '^  - (aarch64|armv7|armhf|i386)$' "$config"
! grep -Eq '^(map:|ingress:|services:)' "$config"
! grep -Eq '^[[:space:]]+- type: homeassistant_config' "$config"
contains "$build" '  amd64: docker.io/muness/unified-hifi-control:feat-ha-mcp-state-read'
! grep -Fq 'latest' "$build"
contains "$run" 'export UHC_PORT RUST_LOG UHC_ADDON=1 UHC_REQUIRE_CONTROLLER_AUTH=1 UHC_MDNS_DISABLE=1 FIRMWARE_AUTO_UPDATE=false'
! grep -Eq '(^|[[:space:]])curl([[:space:]]|$)|api/services|persistent_notification|custom_components' "$run"

printf '%s\n' 'HA MCP candidate manifest is isolated and read-only at startup.'
