# Changelog

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
