# Changelog

## 3.7.0-alpha.5

- **The embedded panel actually loads now.** alpha.4's attempt to fix it made
  things worse: the panel's program file was corrupted in transit and Home
  Assistant returned "502: Bad Gateway" instead of the app. Fixed, and covered
  by a test so it cannot regress silently again.

## 3.7.0-alpha.4

- **Honest broker status.** The MQTT section now shows whether Unified Hi-Fi
  Control is actually connected to your broker, not just that it is trying. A
  broker that never answers reads as a problem, with the address and the
  reason (wrong name, nothing listening, or bad username/password) instead of
  a green "Publishing".

## 3.7.0-alpha.3

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

## 3.7.0-alpha.2

- **Fixes the embedded panel.** In alpha.1 the panel loaded its shell but never
  came alive — no zones, no music sources, and no error explaining why. The web
  app's WebAssembly bundle was requested from the wrong address behind the
  Ingress proxy and quietly failed to load. It now loads correctly.

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
