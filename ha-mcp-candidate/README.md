# UHC HA MCP Candidate

This is a temporary, isolated add-on definition for validating the Home Assistant MCP read path from UHC PR #767. It is not a production replacement or an update channel.

The candidate has its own slug (`uhc_ha_mcp_candidate`), Supervisor `/data` volume, and host port (`8089`). It is amd64-only and pins the branch-built candidate image `muness/unified-hifi-control:feat-ha-mcp-state-read`. It requests only `homeassistant_api: true` so UHC can use the existing Supervisor token and fixed `http://supervisor/core/api` endpoints.

The manifest intentionally omits the `homeassistant_config` map, ingress, and MQTT service. Its wrapper does not call Home Assistant REST endpoints itself; it only starts UHC with `UHC_ADDON=1`, the configured port, and controller authentication enabled. It therefore cannot install or update the UHC integration, dismiss notifications, or modify Home Assistant configuration during startup. Verification should call `ha_read_states` only; do not call `ha_control_entity`.

To use it, first wait for the UHC PR branch Docker candidate build to publish the pinned branch tag. Add this repository to a separate test Home Assistant Supervisor only after confirming that host has no add-on with this slug or port. The current add-on slug, image tag, configuration, and service must remain untouched. No test Supervisor host is currently configured in homelab-infra, so installation and live MCP verification remain pending an isolated target.
