# Vaultwarden Setup Guide

A free, self-hosted password manager for your library staff.

*Cybersecurity on a Library Budget | github.com/adambranscum/library-it-toolkit*

*Questions? abranscum@nlrlibrary.org*

## What You Need

|  | Recommended |
| --- | --- |
| Memory | 512 MB-1 GB |
| CPU cores | 1 |
| Storage | 5 GB |
| Software | Docker and Docker Compose |
| **HTTPS** | **Required.** The web vault and apps will not work over plain HTTP |
| Name | A hostname such as `vault.yourlibrary.org` |

## Step 1: Install Docker

```
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
```

## Step 2: Create the Compose File

```
sudo mkdir -p /opt/vaultwarden && cd /opt/vaultwarden
sudo nano compose.yaml
```

Paste (change the domain):

```
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: "https://vault.yourlibrary.org"
      SIGNUPS_ALLOWED: "true"
    volumes:
      - ./vw-data:/data

  caddy:
    image: caddy:2
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./caddy-data:/data
    depends_on:
      - vaultwarden
```

Caddy is a small web server that handles HTTPS for you.

## Step 3: Set Up HTTPS

```
sudo nano Caddyfile
```

Paste (change the domain):

```
vault.yourlibrary.org {
    reverse_proxy vaultwarden:80
}
```

Point your DNS name at this server's address before you start it.

**Internal only?** If the vault should only work inside your network, add `tls internal` inside the braces. Caddy makes its own certificate, and you install Caddy's root certificate on staff devices so browsers trust it.

## Step 4: Start It

```
sudo docker compose up -d
```

## Step 5: Create Accounts

1. Open `https://vault.yourlibrary.org`.
2. Click **Create account** and make your own admin account.
3. Choose a long **master password**. It can't be recovered if forgotten.
4. Have each staff member create their own account the same way.

## Step 6: Turn Off Signups

Once everyone has an account, stop strangers from registering.

1. Change `SIGNUPS_ALLOWED` to `"false"` in `compose.yaml`.
2. Apply it:

```
sudo docker compose up -d
```

To add someone later, flip it back on briefly, or invite them from an organization.

## Step 7: Connect the Apps

Install the free Bitwarden browser extension or app. On the login screen, choose **self-hosted** and enter your server address, `https://vault.yourlibrary.org`.

## Shared Passwords

For passwords the whole team needs (vendor portals, shared accounts):

1. Create an **Organization** in the web vault.
2. Add staff to it.
3. Create a **Collection** for each group, such as IT or Circulation.
4. Save shared logins into the collection.

## Lock It Down

1. Turn on **two-step login** for every account.
2. Keep signups off.
3. Keep the admin page disabled unless you need it. It's off by default.
4. Keep the server updated.

## Back Up Vaultwarden

**Back up** the `vw-data` folder. It holds every vault, and without it the passwords are gone.

```
cd /opt/vaultwarden
sudo docker compose down
sudo tar czf ~/vaultwarden-backup-$(date +%F).tar.gz vw-data
sudo docker compose up -d
```

Copy the backup to another machine, and **test a backup** at least once.

**Update:**

```
cd /opt/vaultwarden
sudo docker compose pull
sudo docker compose up -d
```

Back up first.
