# Unified Hi-Fi Control — Home Assistant Add-on

Runs the [Unified Hi-Fi Control](https://github.com/open-horizon-labs/unified-hifi-control)
bridge (Roon, LMS, UPnP/OpenHome, HQPlayer) as a Supervisor-managed
container on your Home Assistant box, with its own web UI. This is the
Tier 1 ("no ingress") add-on: the UI opens in its own browser tab at
`http://<your-ha-host>:8088`, not embedded inside the Home Assistant
dashboard. If you also want the media-player / sensor entities inside HA,
install the [UHC HACS integration](https://github.com/open-horizon-labs/unified-hifi-control)
separately — this add-on and the integration are complementary.

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

## Why "no ingress"?

This add-on runs with `host_network: true` — the container shares your HA
host's network stack directly instead of Docker's isolated bridge network.
That's required because:

- **Roon** discovery (SOOD) and **LMS/UPnP/OpenHome/Chromecast** discovery
  (mDNS/SSDP) rely on broadcast and multicast packets that don't cross
  Docker's NAT boundary.
- Without host networking, the add-on would start but never see any zones
  or devices on your LAN.

Home Assistant's **Ingress** feature (embedding the UI inside the HA
dashboard, single sign-on) is not available for host-network add-ons in
this release. You reach the UI directly, at your HA host's IP or hostname
on port 8088. (Tier 2 — ingress support — is tracked separately in the
main repo and depends on this add-on shipping first.)

## First-time setup: finding the bootstrap token

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
- **Lost the bootstrap token**: restart the add-on from the Info tab; a
  fresh token is written to the log on the next start.
- **Add-on won't build/install**: check the Supervisor's own log
  (Settings → System → Logs → Supervisor) for image pull failures — the
  add-on build depends on being able to reach Docker Hub to pull the
  `muness/unified-hifi-control` base image.
