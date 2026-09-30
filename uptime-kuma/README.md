# Uptime Kuma Setup Guide

**Free monitoring for vendor systems, servers, and your website.**
Invisible Infrastructure, Visible Impact | freewareforlibraries.org
Questions? abranscum@nlrlibrary.org

---

## What It Does

Uptime Kuma checks your systems every minute and alerts you when something goes down, before a patron or staff member has to tell you.

Pairs with Wazuh: **Wazuh watches devices. Uptime Kuma watches everything else.**

## What You Need

| | Minimum |
|---|---|
| Memory | 1-2 GB |
| Processors | 1 |
| Storage | 10 GB |
| OS | Ubuntu 24.04 (or any Linux with Docker) |

It can share a server with Wazuh or any other light service.

## Step 1: Install Docker

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
```

## Step 2: Create the Compose File

```bash
sudo mkdir -p /opt/uptime-kuma && cd /opt/uptime-kuma
sudo nano compose.yaml
```

Paste:

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - ./data:/app/data
```

## Step 3: Start It

```bash
sudo docker compose up -d
```

## Step 4: First Login

1. Open `http://SERVER-IP:3001` in a browser.
2. Create the admin username and password.
3. Save the password in your password manager.

## Step 5: Add Your First Monitors

Click **Add New Monitor**.

| Monitor Type | Use It For | Example |
|---|---|---|
| HTTP(s) | Websites, catalog, vendor web portals | Library website |
| Ping | Servers, switches, firewall, printers | Core switch |
| TCP Port | A service that has no web page | Phone server, vendor server port |
| HTTP(s) - Keyword | Vendor status pages | Look for "All Systems Operational" |
| DNS | Confirm your domain resolves | Library domain |
| Push | Scripts and custom checks report in to Kuma | Nightly backup job |

Set **Heartbeat Interval** to 60 seconds and **Retries** to 2-3 so one blip doesn't page you.

## Step 6: Monitor Vendor Systems

Most library vendors publish a public status page. Use it.

1. Add New Monitor > **HTTP(s) - Keyword**.
2. URL: the vendor's status page.
3. Keyword: the text the page shows when things are healthy.

**No API needed.** Vendors with an API can give you deeper data, but most library vendors don't offer one for customers. You can still cover them:

- **Cloud-hosted vendor** (EnvisionWare CloudNine, Libby/OverDrive, TLC, Freegal): monitor the status page or login page.
- **Server you host** (EnvisionWare server, Deep Freeze console): use **Ping** for the server and **TCP Port** on the service port so you know the service itself is answering, not just the machine.

Check the vendor's documentation for the port number to use.

## Step 7: Set Up Alerts

1. **Settings > Notifications > Setup Notification**.
2. Pick a type:
   - **Email (SMTP)**: works with any mail server.
   - **Slack** or **Microsoft Teams**: paste the webhook URL.
3. Check **Default enabled** so new monitors use it automatically.
4. Click **Test**, then **Save**.

## Step 8 (Optional): Status Page

Show staff a live wallboard or share it on a lobby TV.

1. **Status Pages > New Status Page**.
2. Add your monitors in groups (Servers, Websites, Vendors, Network).
3. Save and open the page on a TV or staff browser.

## Step 9: Keep It Healthy

Update every few months:

```bash
cd /opt/uptime-kuma
sudo docker compose pull
sudo docker compose up -d
```

Back up the `data` folder before updating.

## Troubleshooting

| Problem | Fix |
|---|---|
| Can't open the page | Check `sudo docker ps`, then check the server firewall allows port 3001 |
| Too many false alerts | Raise Retries to 3, raise interval to 120 seconds |
| Vendor monitor always red | Open the URL in a browser; confirm the keyword text matches exactly |
| Alerts not arriving | Use the Test button in Notification settings |

## Start Small

Monitor these five things first: your website, your firewall, your core switch, your catalog, and your phone server. Add more over time.
