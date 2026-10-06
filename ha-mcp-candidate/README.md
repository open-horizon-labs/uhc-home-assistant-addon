# UHC HA MCP Candidate

This is a temporary, isolated add-on definition for validating the Home Assistant MCP read path from UHC PR #767. It is not a production replacement or an update channel.

The candidate has its own slug (`uhc_ha_mcp_candidate`), Supervisor `/data` volume, and host port (`8089`). It supports amd64 and aarch64 and pins the UHC multi-platform base image built from PR #767 by manifest digest in `build.yaml`. It requests only `homeassistant_api: true` so UHC can use the existing Supervisor token and fixed `http://supervisor/core/api` endpoints. The wrapper writes an isolated UHC configuration with playback, discovery, and MQTT adapters disabled; this is necessary because the upstream default enables Roon discovery.

The manifest intentionally omits the `homeassistant_config` map, ingress, and MQTT service. Its wrapper does not call Home Assistant REST endpoints itself; it only starts UHC with `UHC_ADDON=1`, the configured port, and controller authentication enabled. It therefore cannot install or update the UHC integration, dismiss notifications, or modify Home Assistant configuration during startup. Verification should call `ha_read_states` only; do not call `ha_control_entity`.

## Local headless validation (2026-10-06)

UHC source commit `d3d22b313e5745c29bc6c5c1cb0236b7bbba37a5` was built on `9950x-columbus` for x86_64-musl and aarch64-musl; the arm64 UHC binary SHA-256 is `45074bc718216e3c400b825ee93c632cff09e6f59f60553c4cd3a702353bfec2`. Both platforms were pushed under the commit-specific tag `muness/unified-hifi-control:ha-mcp-read-candidate-d3d22b313e57`. Its OCI index digest is `sha256:33c8b030849826cbe7b44c2b3cb884d43743890cbd4c6c086dbd229f704faa6e`; inspection confirmed linux/amd64 and linux/arm64 manifests. The candidate recipe pins this exact index digest. The full candidate add-on wrapper image was assembled and tested locally for both platforms; Supervisor builds the add-on image from the reviewed branch recipe and this pinned base.

The pinned base and candidate wrapper image started with every playback/discovery/MQTT adapter disabled and mDNS disabled. Both platform variants advertised `ha_read_states` and `ha_control_entity`; an isolated fake Supervisor served an exact `light.garage` GET, and the MCP read returned the expected entity ID, friendly name, state, and `ok` status. The ARM64 wrapper image was `sha256:df8c4aabb44387ca7b49cfa22084e7cea07ce23ccc57a385459d733d38004882`. The test did not call `ha_control_entity`; the fake Supervisor rejected POST requests. This verifies the binaries, wrapper, controller-authenticated MCP path, and read adapter against a fixture. It does not verify the actual Home Assistant host, an installed add-on, or physical devices.

## Installation status

Keep this candidate separate from the production add-on and treat it only as a validation build. The descriptive UHC tag is mutable, but the candidate recipe uses the published content digest. The add-on branch itself is not a release. The installed Supervisor version is `2026.09.3` and includes the fix that accepts slash-containing branch names. The authenticated Home Assistant UI has the candidate branch source configured. Installation and live read-only validation remain unverified until the distinct candidate app is installed and `ha_read_states` is called against the live Supervisor.
