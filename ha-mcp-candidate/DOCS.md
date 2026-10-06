# UHC HA MCP Candidate

This temporary test add-on exists only to validate the read-only Home Assistant MCP state path from UHC PR #767.

It uses its own add-on slug and port 8089. It does not install the UHC Home Assistant integration, mount Home Assistant's configuration directory, configure MQTT, or call service endpoints during startup. The wrapper requires controller authentication, disables mDNS announcements and firmware polling, and its fresh private data volume leaves music provider adapters disabled. The candidate still advertises the separate `ha_control_entity` MCP tool; do not invoke that tool during read-only validation.

The add-on requests the Supervisor-managed `homeassistant_api` permission and uses UHC's existing Supervisor token for exact or bounded state reads. It is amd64-only and uses a branch candidate image. Do not install it over the production add-on or treat this configuration as a release artifact.
