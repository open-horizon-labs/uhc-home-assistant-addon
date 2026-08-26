# Unified Hi-Fi Control — Home Assistant Add-on

Runs the [Unified Hi-Fi Control](https://github.com/open-horizon-labs/unified-hifi-control)
bridge (Roon, LMS, UPnP/OpenHome, HQPlayer) as a Supervisor-managed
container on your Home Assistant box, with its own web UI. The UI is
reachable two ways, and both work at the same time:

- **Ingress (embedded)**: a **Hi-Fi Control** entry appears in the HA
  sidebar and opens the full UHC UI inside the Home Assistant dashboard,
  authenticated by your HA session — no extra port, no bootstrap prompt.
- **Direct (fallback)**: the UI also stays available in its own browser
  tab at `http://<your-ha-host>:8088`, exactly as in the Tier 1 add-on —
  useful for other devices on the LAN, hardware knobs, and MCP clients
  that don't go through Home Assistant.

Your zones and controllers also appear as Home Assistant **entities**
automatically, as long as you have the **Mosquitto broker** add-on
installed. See [Home Assistant entities](#home-assistant-entities) below.

## Install

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Click the **⋮** menu (top right) → **Repositories**.
3. Add this URL and click **Add**:

   ```
   https://github.com/open-horizon-labs/uhc-home-assistant-addon
   ```

4. Close the dialog. The store refreshes; scroll down (or search) for
   **Unified Hi-Fi Control** under the new repository section.
5. Click into it, then click **Install**. The first install builds the
   add-on image locally on your HA host — on a Raspberry Pi this can take
   a few minutes.
6. Once installed, click **Start**.

## Ingress vs. direct mode

This add-on runs with `host_network: true` — the container shares your HA
host's network stack directly instead of Docker's isolated bridge network.
That's required because **Roon** discovery (SOOD) and
**LMS/UPnP/OpenHome/Chromecast** discovery (mDNS/SSDP) rely on broadcast
and multicast packets that don't cross Docker's NAT boundary.

**Ingress** (the embedded **Hi-Fi Control** sidebar panel) proxies your
browser through the Supervisor to the add-on's port. Inside ingress:

- Your Home Assistant login is the authentication — UHC trusts requests
  proxied by the Supervisor and never shows the bootstrap prompt there.
- No port needs to be reachable from the browser's network; remote access
  solutions that expose HA (Nabu Casa, VPN) get the UHC UI for free.

**Direct mode** (`http://<your-ha-host>:8088`) keeps working unchanged as
a fallback and for non-browser clients (hardware knobs, MCP agents, the
HACS integration). Direct requests keep the full controller-auth posture:
the ingress trust applies only to connections arriving from the
Supervisor's own proxy network carrying its `X-Ingress-Path` header, so a
LAN client cannot impersonate ingress by setting headers.

**Caveat**: ingress connects to port `8088` specifically (`ingress_port`
is fixed; this add-on has no bashio to discover a dynamic port). If you
change the `port` option, the sidebar panel stops working until you set it
back — direct mode keeps working on the new port.

## Home Assistant entities

Each of your zones shows up as a `media_player` entity and each hardware
controller as its own device — no YAML, nothing to type into Unified Hi-Fi
Control. Two things have to be in place, and only the first is automatic:

1. **The Mosquitto broker add-on**, installed and started. Home Assistant's
   Supervisor then hands this add-on the broker's address and a set of
   credentials of its own, and the add-on passes them straight to Unified
   Hi-Fi Control on start.
2. **Home Assistant's own MQTT integration**, which you add yourself:
   **Settings → Devices & services → Add integration → MQTT**. When the
   Mosquitto add-on is installed this normally fills the broker details in
   for you, so it is a couple of clicks.

Step 2 is easy to miss, and missing it looks exactly like nothing being
wrong. Unified Hi-Fi Control will happily connect to the broker and publish
every zone, and Home Assistant will show **no entities at all**, because
without that integration nothing on the Home Assistant side is reading the
broker. It is not offered under "Discovered" — you have to add it.

Nothing needs restarting after you add it. Unified Hi-Fi Control notices
Home Assistant arriving on the broker and re-sends everything within a few
seconds.

**If no entities appear:**

1. Check **Settings → Devices & services → MQTT**. If it says "No entries",
   that is your answer — add the integration as described above.
2. Install the **Mosquitto broker** add-on (Settings → Add-ons → Add-on
   Store → Mosquitto broker) and start it, if you have not already.
3. Open Unified Hi-Fi Control's **Settings → MQTT / Home Assistant**. It
   says which of the two halves is missing, in plain words.
4. Check the add-on's **Log** tab. One of these lines tells you where you
   stand:

   | Log line | What it means |
   |---|---|
   | `MQTT broker from the Supervisor: …` | The broker was found and handed over. |
   | `no MQTT broker available from the Supervisor` | No broker add-on is installed, or it isn't started. |
   | `MQTT configured from environment (Home Assistant add-on); publisher enabled` | UHC is publishing. |
   | `Home Assistant's MQTT integration is NOT set up` | The broker side is fine; step 2 above is what is missing. |
   | `Home Assistant's MQTT integration is set up; discovery is being consumed` | Both halves are in place. |
   | `MQTT configured from your saved settings` | You entered broker details yourself; those are being used instead. |

### Using your own broker instead

If you'd rather point Unified Hi-Fi Control at a broker of your own, enter
it under **Settings → MQTT / Home Assistant** in the UHC UI. **Broker
settings you save yourself always win**: from that point on the add-on
stops handing over the Supervisor's broker, and updates or restarts will
not overwrite what you entered.

### Turning it off

Set `publish_to_home_assistant` to `false` in the add-on's Configuration
tab and restart. The add-on then stops handing over any broker details.

Note this only stops the *hand-over*. If entities were already being
published, a broker Unified Hi-Fi Control already saved stays saved — turn
**Enable MQTT/Home Assistant** off in UHC's Settings to actually stop
publishing.

## First-time setup: finding the bootstrap token

**If you only use the embedded sidebar panel, you can skip this section**
— inside ingress your HA session is the authentication and the bootstrap
prompt never appears. The token matters for direct mode
(`http://<your-ha-host>:8088`).

On first start, the bridge generates a one-time **controller bootstrap
token** used to claim ownership of the web UI (so a random device on your
LAN can't take over your Roon/LMS pairing before you do). Here's how to
find it:

1. In the add-on's page, click the **Log** tab (the add-on log panel).
2. Look for a line like:

   ```
   UHC controller bootstrap token (display once; do not put it in a tunnel URL): <token>
   ```

3. Copy `<token>`.
4. Open the web UI at `http://<your-ha-host>:8088`, and paste the token
   when prompted to claim the browser session.

**The token is only ever shown once, in the add-on log panel, and is not
stored anywhere else.** If you miss it, restart the add-on (Settings →
Add-ons → Unified Hi-Fi Control → Restart) to generate a new one — a
fresh restart re-issues the bootstrap token.

Do not paste the token into a remote-access tunnel URL, a support ticket,
or share it publicly: anyone holding it can claim controller access until
you re-pair.

## Options

| Option | Description | Default |
|---|---|---|
| `port` | HTTP port for the web UI/API. Change only if 8088 conflicts with another service (for example, HQPlayer, which also defaults to 8088). | `8088` |
| `log_level` | Log verbosity: `trace`, `debug`, `info`, `warn`, `error`. | `info` |
| `require_controller_auth` | When `true`, provider pairing/account actions require the bootstrap token instead of trusting any LAN client. | `false` |
| `publish_to_home_assistant` | Hand the Supervisor's MQTT broker to Unified Hi-Fi Control on start, so zones and controllers appear as Home Assistant entities. Set to `false` to keep the add-on from touching UHC's MQTT settings. See [Home Assistant entities](#home-assistant-entities). | `true` |

Changing an option requires a **Restart** of the add-on to take effect
(Configuration tab → Save, then Info tab → Restart).

## Persistence across updates

Settings, provider pairings, and Roon extension state live in the add-on's
private `/data` directory, which the Supervisor keeps across add-on
restarts and version updates. Uninstalling the add-on removes this data;
there is currently no export/import flow, so treat provider re-pairing as
a possible step after a full uninstall/reinstall.

## Roon pairing

With the add-on running and `host_network: true` in effect, your Roon Core
should see a new extension advertising itself once you open the web UI
(Roon → Settings → Extensions, or the notification bell). Approve it there
— pairing state then persists in `/data` as described above.

## Troubleshooting

- **No zones/devices show up**: confirm `host_network: true` is in effect
  (this is fixed in the add-on and not user-configurable) and that your HA
  host and the target devices are on the same LAN segment/VLAN — mDNS and
  SOOD discovery do not cross VLANs or Wi-Fi client isolation.
- **Port 8088 already in use**: if HQPlayer or another service on the same
  host also uses 8088, change the `port` option, restart the add-on, and
  browse to the new port.
- **No entities in Home Assistant**: see
  [Home Assistant entities](#home-assistant-entities) — the usual cause is
  that no MQTT broker add-on is installed.
- **Lost the bootstrap token**: restart the add-on from the Info tab; a
  fresh token is written to the log on the next start.
- **Add-on won't build/install**: check the Supervisor's own log
  (Settings → System → Logs → Supervisor) for image pull failures — the
  add-on build depends on being able to reach Docker Hub to pull the
  `muness/unified-hifi-control` base image.
