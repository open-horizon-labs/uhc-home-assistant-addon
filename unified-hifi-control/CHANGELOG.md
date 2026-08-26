# Changelog

## Unreleased

- **Zones and controllers now appear as Home Assistant entities on their
  own.** With the Mosquitto broker add-on installed, the Supervisor hands
  this add-on the broker's address and credentials, and Unified Hi-Fi
  Control starts publishing over MQTT discovery — no broker details to
  type in, no YAML. Previously the add-on gave you the UI panel and no
  entities, with nothing explaining why.
- Broker settings you enter yourself in UHC's Settings always win, and are
  never overwritten by the add-on.
- New `publish_to_home_assistant` option (default `true`) to opt out.
- The add-on log now says which broker was used, or why none was.

## 3.7.0-alpha.1

- **Embedded dashboard panel (Ingress).** Open Unified Hi-Fi Control directly
  inside the Home Assistant sidebar — no separate port, no extra login. Direct
  access on the configured port keeps working exactly as before.
- Updated to Unified Hi-Fi Control 3.7.0-alpha.1: Library-first web UI with
  zones strip, streaming adapters (Spotify, Apple Music, Music Assistant —
  Alpha), guided Spotify setup with a built-in secure tunnel, MQTT discovery,
  and Roon/LMS zone grouping.
- Alpha build for testing; expect rough edges and report issues at
  https://github.com/open-horizon-labs/unified-hifi-control/issues

## 3.6.0

- Initial add-on release (host networking, persistent /data config).
