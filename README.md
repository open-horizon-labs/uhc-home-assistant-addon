# Unified Hi-Fi Control — Home Assistant Add-on Repository

Home Assistant add-on repository for
[Unified Hi-Fi Control](https://github.com/open-horizon-labs/unified-hifi-control) —
a bridge connecting Roon, LMS, UPnP/OpenHome, and HQPlayer to one control
surface (web UI, hardware knobs, Claude/MCP).

## Add this repository

[![Add add-on repository to my Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fopen-horizon-labs%2Fuhc-home-assistant-addon)

Or manually, in Home Assistant: **Settings → Add-ons → Add-on Store →
⋮ (top right) → Repositories**, then add:

```
https://github.com/open-horizon-labs/uhc-home-assistant-addon
```

Install **Unified Hi-Fi Control** from the store afterward. Full install
walkthrough, including where to find the one-time controller bootstrap
token on first start, is in
[`unified-hifi-control/DOCS.md`](unified-hifi-control/DOCS.md).

## What's here

| Add-on | Description |
|---|---|
| [`unified-hifi-control/`](unified-hifi-control/) | The bridge, packaged as a Supervisor-managed container. Requires host networking for Roon/mDNS discovery. Embeds in the HA dashboard via ingress, and installs the UHC integration so your zones become `media_player` entities. |

## Scope

Installing this add-on gives you three things:

- **The bridge itself**, running as a Supervisor-managed container.
- **The UI in your dashboard**, through ingress — a **Hi-Fi Control**
  sidebar entry authenticated by your Home Assistant session. The direct
  tab at `http://<your-ha-host>:8088` keeps working for LAN devices,
  hardware controllers, and MCP clients.
- **Your zones as entities**: the add-on installs the Unified Hi-Fi
  Control integration into Home Assistant for you. Restart Home Assistant
  once and it appears under **Settings → Devices & services →
  Discovered**. No MQTT broker, no HACS, nothing to copy.

Running UHC somewhere other than Home Assistant (QNAP, Docker, bare
metal)? Install the integration from the
[main repository](https://github.com/open-horizon-labs/unified-hifi-control)
instead — this add-on is only for Home Assistant hosts.

## Versioning

The add-on's `config.yaml` `version` and the `build.yaml` base image tag
track [unified-hifi-control releases](https://github.com/open-horizon-labs/unified-hifi-control/releases).
See [`unified-hifi-control` repo's docs/gh-release.md](https://github.com/open-horizon-labs/unified-hifi-control/blob/v4/docs/gh-release.md#home-assistant-add-on-version-bumps)
for the bump procedure.

The add-on consumes a published Docker image, not a Git branch. Every
architecture is pinned to the same explicit UHC release as `config.yaml`;
`latest` is deliberately unsupported because it would make an unchanged
add-on version install different code over time. The current 3.7 alpha pin
remains until the first multi-architecture `4.0.0-alpha.N` image is published.

## License

[PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/),
matching the main [unified-hifi-control](https://github.com/open-horizon-labs/unified-hifi-control)
project. Contact the maintainer for commercial licensing.
