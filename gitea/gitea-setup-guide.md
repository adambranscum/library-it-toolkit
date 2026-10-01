# Gitea Setup Guide

Your own free Git server for configs, scripts, and documentation.

*Cybersecurity on a Library Budget | github.com/adambranscum/library-it-toolkit*

*Questions? abranscum@nlrlibrary.org*

## What You Need

|  | Recommended |
| --- | --- |
| Memory | 1-2 GB |
| CPU cores | 1-2 |
| Storage | 20 GB (grows with your repos) |
| Software | Docker and Docker Compose |
| OS | Ubuntu 24.04 (or any Linux with Docker) |

It can share a server with other light Docker tools.

## Step 1: Install Docker

```
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
```

## Step 2: Create the Compose File

```
sudo mkdir -p /opt/gitea && cd /opt/gitea
sudo nano compose.yaml
```

Paste:

```
services:
  gitea:
    image: docker.gitea.com/gitea:latest
    container_name: gitea
    restart: unless-stopped
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__service__DISABLE_REGISTRATION=true
    volumes:
      - ./data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "2222:22"
```

Port 3000 is the web page. Port 2222 is for Git over SSH, which keeps it from clashing with the server's own SSH.

## Step 3: Start It

```
sudo docker compose up -d
```

## Step 4: Finish Setup in the Browser

1. Open `http://SERVER-IP:3000`.
2. **Database type:** choose **SQLite3**. It's simple and plenty for a library.
3. **Server Domain:** your server's name or IP.
4. **Gitea Base URL:** `http://SERVER-IP:3000` (use your real address).
5. Expand **Administrator Account Settings** and create your admin account now.
6. Click **Install Gitea**.

## Step 5: Create Your First Repository

1. Click the **+** at the top right and choose **New Repository**.
2. Name it, and keep it **Private**.
3. Copy the repo's address from the page.

## Step 6: Push Your First Files

From your computer:

```
cd your-project-folder
git init
git add .
git commit -m "First commit"
git remote add origin http://SERVER-IP:3000/YOUR-USER/YOUR-REPO.git
git push -u origin main
```

## Lock It Down

1. Turn on **two-factor authentication** for admin accounts (Settings > Security).
2. Registration is already off in the compose file. Create staff accounts yourself as admin.
3. Keep it **inside your network**. Don't publish port 3000 to the internet.
4. Never commit passwords, keys, or `.env` files. Add them to `.gitignore`.

## Keep It Updated

**Back up** the `data` folder. It holds every repo and the database.

```
cd /opt/gitea
sudo docker compose down
sudo tar czf ~/gitea-backup-$(date +%F).tar.gz data
sudo docker compose up -d
```

Copy the backup to another machine.

**Update** every few months:

```
cd /opt/gitea
sudo docker compose pull
sudo docker compose up -d
```

Back up first.
