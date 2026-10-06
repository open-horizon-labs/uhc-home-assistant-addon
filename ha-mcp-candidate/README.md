# UHC HA MCP Candidate

This is a temporary, isolated add-on definition for validating the Home Assistant MCP read path from UHC PR #767. It is not a production replacement or an update channel.

The candidate has its own slug (`uhc_ha_mcp_candidate`), Supervisor `/data` volume, and host port (`8089`). It is amd64-only and pins the branch-built candidate image `muness/unified-hifi-control:feat-ha-mcp-state-read`. It requests only `homeassistant_api: true` so UHC can use the existing Supervisor token and fixed `http://supervisor/core/api` endpoints. The wrapper writes an isolated UHC configuration with playback, discovery, and MQTT adapters disabled; this is necessary because the upstream default enables Roon discovery.

The manifest intentionally omits the `homeassistant_config` map, ingress, and MQTT service. Its wrapper does not call Home Assistant REST endpoints itself; it only starts UHC with `UHC_ADDON=1`, the configured port, and controller authentication enabled. It therefore cannot install or update the UHC integration, dismiss notifications, or modify Home Assistant configuration during startup. Verification should call `ha_read_states` only; do not call `ha_control_entity`.

## Local headless validation (2026-10-06)

UHC source commit `d3d22b313e5745c29bc6c5c1cb0236b7bbba37a5` was built on `9950x-columbus` as a static x86_64-musl binary (SHA-256 `3e665131013e8b8e74e298b28314b66e79f3fd65890f324d95b0c5ed1fdfbe9a`). A local amd64 candidate add-on image was assembled from that base plus this add-on's wrapper as `uhc-ha-mcp-addon-candidate:minimal-d3d22b3`, manifest digest `sha256:80dc8186c18f4ff5d7095d10b7d1744edf922d6c315a4aea1c5b8464f2f840fa`. This digest is local to the builder; the image was not pushed to a registry and is not installable through the Supervisor store.

The image started with every playback/discovery/MQTT adapter disabled and mDNS disabled. Its real UHC MCP endpoint advertised `ha_read_states` and `ha_control_entity`; an isolated fake Supervisor served an exact `light.garage` GET, and the MCP read returned the expected entity ID, friendly name, state, and `ok` status. The test did not call `ha_control_entity`; the fake Supervisor rejected POST requests. This verifies the binary, wrapper, controller-authenticated MCP path, and read adapter against a fixture. It does not verify the full UI (the local headless image has no embedded WASM assets), a real Supervisor token, the actual Home Assistant host, an installed add-on, or physical devices.

## Installation status

Do not install this candidate over the production add-on or treat it as a release artifact. The branch image tag is mutable and the local image digest above is not published. A repeatable Supervisor installation still needs an immutable registry image/release and review of that exact image; live read-only validation remains pending. The user's authenticated Home Assistant UI shows the existing UHC repository configured, but no candidate branch release is available there yet.
