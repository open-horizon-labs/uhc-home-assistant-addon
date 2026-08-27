# Unified Hi-Fi Control

_Bridge Roon, LMS, UPnP/OpenHome, and HQPlayer to one control surface —
web UI, hardware knobs, and Claude/MCP — as a Home Assistant add-on._

![Supports amd64 Architecture][amd64-shield]
![Supports aarch64 Architecture][aarch64-shield]

## About

[Unified Hi-Fi Control](https://github.com/open-horizon-labs/unified-hifi-control)
is a source-agnostic hi-fi control bridge. This add-on packages it to run
as a Supervisor-managed container on your Home Assistant box: no separate
server, no manual Docker Compose, no terminal.

The UI is reachable two ways, and both work at once: a **Hi-Fi Control**
entry in the Home Assistant sidebar that opens the full UI inside the
dashboard (authenticated by your HA session), and its own browser tab at
`http://<your-ha-host>:8088` for other devices on the LAN, hardware
controllers, and MCP clients. See [DOCS.md](DOCS.md) for the full install
walkthrough.

It also installs the Unified Hi-Fi Control **integration** into Home
Assistant for you, so your zones become `media_player` entities. Restart
Home Assistant once after installing the add-on and UHC appears under
**Settings → Devices & services → Discovered**. No MQTT broker, no HACS.

## Installation

See the full walkthrough in [DOCS.md](DOCS.md). Short version: add
`https://github.com/open-horizon-labs/uhc-home-assistant-addon` as an
add-on repository under **Settings → Add-ons** (called **Apps** in newer
Home Assistant releases) **→ ⋮ → Repositories**, then install **Unified
Hi-Fi Control** from the list.

## Support

- [Main project issues](https://github.com/open-horizon-labs/unified-hifi-control/issues)
- [This add-on's issues](https://github.com/open-horizon-labs/uhc-home-assistant-addon/issues)

[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
