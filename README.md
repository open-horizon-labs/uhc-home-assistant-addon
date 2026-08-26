# Unified Hi-Fi Control — Home Assistant Add-on Repository

Home Assistant add-on repository for
[Unified Hi-Fi Control](https://github.com/open-horizon-labs/unified-hifi-control) —
a bridge connecting Roon, LMS, UPnP/OpenHome, and HQPlayer to one control
surface (web UI, hardware knobs, Claude/MCP).

## Add this repository

In Home Assistant: **Settings → Add-ons → Add-on Store → ⋮ (top right) →
Repositories**, then add:

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
| [`unified-hifi-control/`](unified-hifi-control/) | The bridge, packaged as a Supervisor-managed container. Requires host networking for Roon/mDNS discovery. Tier 1: UI opens in its own tab, no HA ingress/embedding yet. |

## Scope

This is the **Tier 1** add-on: installable from the store, no ingress. UI
embedding inside the HA dashboard (ingress, HA-session auth) is tracked as
Tier 2 in the main repository and depends on this add-on shipping first.

For the entity-level integration (media players, sensors inside HA), see
the [HACS integration](https://github.com/open-horizon-labs/unified-hifi-control)
in the main repository — it is separate from, and complementary to, this
add-on.

## Versioning

The add-on's `config.yaml` `version` and the `build.yaml` base image tag
track [unified-hifi-control releases](https://github.com/open-horizon-labs/unified-hifi-control/releases).
See [`unified-hifi-control` repo's docs/gh-release.md](https://github.com/open-horizon-labs/unified-hifi-control/blob/v3/docs/gh-release.md#home-assistant-add-on-version-bumps)
for the bump procedure.

## License

[PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/),
matching the main [unified-hifi-control](https://github.com/open-horizon-labs/unified-hifi-control)
project. Contact the maintainer for commercial licensing.
