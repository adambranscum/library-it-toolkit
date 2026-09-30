# Security Onion Setup Guide

**Free network security monitoring. See what's crossing your network.**
Invisible Infrastructure, Visible Impact | freewareforlibraries.org
Questions? abranscum@nlrlibrary.org

---

## What It Does

Security Onion watches a copy of your network traffic and alerts on suspicious activity: malware calling home, scans, strange connections.

**Wazuh watches devices. Security Onion watches the wire.** Together you see both sides.

## What You Need

| | Bare Minimum (Standalone) |
|---|---|
| CPU cores | 4 |
| Memory | 24 GB |
| Storage | 200 GB |
| Network cards | **2** (one for management, one for capture) |

These are the bare minimum. More storage means longer retention. Use **dedicated hardware**, since it competes badly with other workloads. Wired network only.

Also needed: a **managed switch with a mirror (SPAN) port.**

## Step 1: Download and Verify

1. Get the ISO from **docs.securityonion.net** (Download page).
2. Verify the checksum and signature using the steps on that page.
3. Write it to a USB drive with Rufus or balenaEtcher.

## Step 2: Install

1. Boot the server from USB.
2. Follow the installer. It formats the disk. **Back up anything on it first.**
3. Create the admin user and reboot.

## Step 3: Run Setup

Log in and run the setup wizard.

1. Choose **Install**, then **STANDALONE**.
2. Give the server a hostname.
3. **Management NIC:** the one on your normal network.
4. Set a **static IP** for the management NIC.
5. **Monitor NIC:** the second card. This is the one that receives mirrored traffic. Do **not** give it an IP.
6. Set your NTP/time source.
7. Choose which networks may reach the web interface (your IT VLAN only).
8. Create the web admin account (email + password).
9. Confirm and let it finish. This takes a while.

## Step 4: Check It's Healthy

```bash
sudo so-status
```

Everything should show **OK**.

## Step 5: Allow Yourself In

```bash
sudo so-allow
```

Choose the **analyst** role and enter your workstation's IP. Then browse to `https://SERVER-IP`.

## Step 6: Set Up the Mirror Port

On your switch, create a **port mirror (SPAN)**:

- **Source:** the port(s) you want to watch
- **Destination:** the port plugged into Security Onion's **monitor NIC**

The menu name varies by brand (SPAN, port mirroring, monitor session). Mirror both directions (transmit and receive).

### Which Port to Mirror?

| Option | What You See | Trade-Off |
|---|---|---|
| **Uplink only** (link between firewall and core) | Everything entering and leaving your building | Easy, low load. Misses traffic between internal VLANs. |
| **Full core capture** (core switch ports) | Internal traffic too | Sees more, needs more capacity. |

**Start with uplink only.** Move to core capture once it's stable.

## Step 7: Confirm Traffic Is Arriving

Replace `ETH1` with your monitor NIC name.

```bash
sudo tcpdump -nn -i ETH1 -c 20
```

If packets scroll by, the mirror works. If nothing appears, recheck the switch config and cable.

## Step 8: Learn the Console

Log in and open these first:

| Area | What It Shows |
|---|---|
| **Alerts** | Suspicious activity, ranked |
| **Dashboards** | Overall traffic summary |
| **Hunt** | Search all network data |
| **Cases** | Track an investigation |

## Step 9: Tune It

Expect noise the first week.

1. Review the alerts you see most often.
2. Decide if each one is real or normal for your network.
3. Suppress the normal ones.
4. Leave the rest.

Your goal is a short list of alerts worth reading, not zero alerts.

## Troubleshooting

| Problem | Fix |
|---|---|
| Web page won't load | Run `sudo so-allow` and add your IP |
| No traffic in dashboards | Test with `tcpdump`, check the switch mirror |
| Disk filling up | Reduce retention or add storage |
| Services not OK | `sudo so-status`, wait 10 minutes after boot, then reboot |

## Start Small

Get one mirror port, one server, and one week of alert tuning. That alone shows you more about your network than you have today.
