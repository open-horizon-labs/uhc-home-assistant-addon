# Changelog

## Unreleased

- **Your zones are Home Assistant media players now — no broker, no HACS,
  no copying files.** The add-on installs the Unified Hi-Fi Control
  integration into Home Assistant itself. Restart Home Assistant once after
  installing the add-on and UHC is waiting under **Settings → Devices &
  services → Discovered**; click Configure and you are done. The add-on log
  says exactly what it did and reminds you about the restart.
- It keeps the integration up to date on every start, and never overwrites a
  newer copy, a copy you installed yourself through HACS, or one you have
  edited. `install_integration: false` turns the whole thing off.
- **MQTT is no longer switched on for you.** It was never needed for
  entities, and publishing every zone to a broker nobody asked for is not a
  sensible default. When the Mosquitto add-on is installed the broker
  details are still filled in for you, so switching MQTT on stays one click
  with nothing to type — it just does not happen by itself any more.
- If you already had MQTT running, it keeps running. Nothing is torn down.
- The "publishing, but Home Assistant isn't receiving it" warning now only
  appears if you turned MQTT on yourself. It was never fair to warn people
  about a setting they did not choose.

- **Says when Home Assistant isn't listening.** Installing this add-on with
  the Mosquitto broker builds only half the bridge: Home Assistant's own
  **MQTT integration** still has to be added by hand, and until it is, you
  get no entities at all — even though Unified Hi-Fi Control is connected to
  the broker and publishing every zone. Nothing said so; the MQTT status read
  as a clean success. UHC now checks with Home Assistant directly and, when
  the integration is missing, says so in **Settings → MQTT / Home Assistant**
  with the click path: **Settings → Devices & services → Add integration →
  MQTT**. With the Mosquitto add-on installed it normally fills the broker in
  for you.
- When it genuinely cannot check — running outside Home Assistant, for
  instance — it says that too, rather than guessing either way.
- Nothing to restart after adding the integration: UHC notices Home Assistant
  arriving on the broker and re-sends every zone within a few seconds.
- DOCS: the MQTT integration is now step 2 of the setup rather than a footnote.

## 3.7.0-alpha.9

- **Playing something you browsed to a while ago now just works.** Roon
  invalidates the handles it gives us for items, and playback would fail with
  "the item key is no longer valid — search or browse again". It now quietly
  retraces your path, gets a fresh handle and plays, instead of asking you to
  start over.

## 3.7.0-alpha.8

- **Home Assistant now tells you to restart.** Installing the integration
  needs one Home Assistant restart to take effect, and that was only
  mentioned in the add-on log. You now get a notification in Home Assistant
  itself, and it clears on its own once the restart is done.
- Corrected the README, which still claimed the add-on had no dashboard
  embedding and did not install the integration.

## 3.7.0-alpha.7

- **Your zones become Home Assistant devices, by themselves.** The app now
  installs its own Home Assistant integration for you. Restart Home Assistant
  once after updating, and Unified Hi-Fi Control appears under Discovered —
  add it and every zone shows up as a media player you can control, group and
  browse. No MQTT broker, no HACS, nothing to copy.
- MQTT no longer switches itself on. It stays available for setups that want
  it (broker details are still filled in for you), and anything already
  publishing keeps working exactly as before.

## 3.7.0-alpha.6

- **Tells you when Home Assistant isn't listening.** Publishing to a broker
  that nothing consumes used to look like success. The MQTT section now says
  plainly whether Home Assistant's own MQTT integration is set up, and how to
  add it — and when you do, your zones appear within seconds without a
  restart.
- Fixed album art showing as a broken image in the embedded panel on the
  Zones, HQPlayer and Spotify pages and in the zone picker.

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
