# VoIP and Fax Setup Guide

**Run your library phones and fax on free software.**
Invisible Infrastructure, Visible Impact | freewareforlibraries.org
Questions? abranscum@nlrlibrary.org

---

## Our Example (NLRPLS)

- We run **FreePBX** on Debian 12 with **Voxtelesys** as the SIP trunk provider.
- Cost is about **$153 a month**, down from roughly $1,800 to $1,900 with our old provider.
- One virtual machine runs the phone system. Fax runs on its own server.
- We now control every setting. No more being locked out of our own phones.

## What You Need

| Item | Size |
|---|---|
| Phone server (VM) | 4 GB RAM, 4 virtual CPUs, 256 GB storage |
| Fax server (VM) | Small. Separate from the phone server |
| SIP trunk provider | Any provider that supports PJSIP and T.38 fax |
| Desk phones | Standard SIP phones |
| Firewall | Can do 1:1 NAT and turn off SIP ALG |
| DHCP server | Can set custom options on a scope (option 66) |
| Network | A dedicated voice VLAN |

## Part 1: The Voice VLAN

Do this first. Most VoIP problems are network problems.

### Why a Separate VLAN

- Phone traffic stays away from public and staff traffic.
- Patron devices can never reach the phone server.
- Firewall rules are simple, because all voice devices live in one place.
- Voice traffic can be prioritized so calls stay clear.

Our phone system sits on its own dedicated voice VLAN, apart from staff and public.

### Set It Up

1. Create a **voice VLAN** on the firewall and switches (pick an unused VLAN ID and subnet).
2. Give the phone server a **static IP** in that VLAN.
3. Create a **DHCP scope** for the phones in that VLAN.
4. Add **DHCP option 66** so phones find their settings automatically (see Part 3).
5. Set switch ports for phones to the voice VLAN. If a computer plugs into the phone, leave the computer on its normal VLAN.
6. Turn on **QoS** so voice traffic gets priority.

### Firewall Rules

1. Allow the voice VLAN to reach your SIP provider only.
2. Allow IT to reach the FreePBX admin page.
3. Allow the phones to reach the provisioning server (see Part 3).
4. Block the public VLAN from reaching the voice VLAN.
5. Block everything else by default.

### NAT

1. Set up a **1:1 NAT** from one public IP to the phone server.
2. **Turn off SIP ALG** on the firewall.

## Part 2: Phones

### Step 1: Install FreePBX

1. Install Debian 12 on the VM.
2. Install FreePBX using the official install instructions at freepbx.org.
3. Log in to the web interface and finish the setup wizard.

### Step 2: Tell FreePBX Its Public Address

1. Go to **Settings > Asterisk SIP Settings > chan_pjsip**.
2. Set the **External Address** to your public IP.
3. Add your internal network under **Local Networks**.
4. Save and apply.

### Step 3: Add the SIP Trunk

1. Go to **Connectivity > Trunks > Add Trunk**, choose **PJSIP**.
2. Enter the details your provider gives you (server, username, password).
3. Add an **Inbound Route** for your phone number.
4. Add an **Outbound Route** so staff can dial out.
5. Place a test call both directions.

### Step 4: Add Extensions and Phones

1. Create extensions under **Applications > Extensions**.
2. Set up ring groups for shared lines (circulation, reference).
3. Plug in a desk phone, point it at the server, and test.

## Part 3: DHCP and Phone Provisioning

Provisioning means a new phone sets itself up. Plug it in, and it gets an address, finds its settings, and registers. No one touches the phone.

### How It Works

1. The phone boots and asks DHCP for an IP address.
2. DHCP answers with an address **and option 66**, which tells the phone where its settings live.
3. The phone contacts that server and downloads the config file that matches its MAC address.
4. The phone applies the settings and registers to FreePBX.

### Set Up DHCP

1. Create a **DHCP scope** in the voice VLAN (address range, gateway, DNS).
2. **Exclude** the phone server's static IP from the range.
3. Add **option 66** to the scope.
   - Value: the address of your provisioning server, as a URL (for example `http://SERVER-IP/...`) or an IP, depending on your phones.
   - Type: string.
4. Optional: add **option 42** so phones get the right time from your NTP server.
5. Activate the scope.

Check your phone brand's documentation for the exact format it expects in option 66.

### Set Up the Provisioning Server

1. Choose where phone config files will live. This can be FreePBX (using its Endpoint Manager module) or any web or TFTP server you control.
2. Create a config file for each phone, named for its MAC address, with its extension and password.
3. Allow the voice VLAN to reach that server on the right port (HTTP, HTTPS, or TFTP).

### Test It

1. Plug a phone into a voice VLAN port.
2. Confirm it gets a voice VLAN address.
3. Watch it download its config and reboot.
4. Confirm the extension shows **registered** in FreePBX.
5. Place a test call.

## Part 4: Holiday and After-Hours Messages

- Record a greeting for each closure.
- Use FreePBX time conditions and announcements to play the right message on the right days.
- Give **each branch its own voicemail box and announcement.**
- Test every branch before the holiday, not after.

Our scheduler is a custom per-branch config. Time conditions are the simpler starting point.

## Part 5: Fax

We run fax on a **separate server** using Asterisk's built-in fax support.

1. Build a second small VM with Asterisk.
2. Connect it to your SIP trunk over PJSIP with **T.38** enabled.
3. Set incoming faxes to save as a **PDF** and **email** to a staff mailbox.
4. Send a test fax in and out.

## Before You Go Live

1. Confirm phones land in the voice VLAN and provision on their own.
2. Test calls in, out, and between extensions.
3. Test voicemail at every branch.
4. Test fax in and out.
5. Back up the FreePBX config.
6. Keep your old phone line active until everything passes.

## Start Small

Set up the VM and trunk, then move **one** phone line and test for a week before moving the rest.
