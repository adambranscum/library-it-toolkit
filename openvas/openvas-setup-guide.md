# OpenVAS Setup Guide

Free vulnerability scanning: find weak spots before someone else does.

*Cybersecurity on a Library Budget | github.com/adambranscum/library-it-toolkit*

*Questions? abranscum@nlrlibrary.org*

## What You Need

|  | Recommended |
| --- | --- |
| Memory | 8 GB minimum, 16 GB more comfortable |
| CPU cores | 4 |
| Storage | 60 GB SSD |
| Software | Docker and Docker Compose |
| Network | The server can reach the networks you want to scan |

These are starting points, not official numbers.

## Step 1: Install Docker

```
sudo apt update
sudo apt install -y docker.io docker-compose-v2 curl
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

Log out and back in.

## Step 2: Download the Compose File

```
mkdir -p ~/greenbone && cd ~/greenbone
```

Get the **current** compose file from the Greenbone Community Containers documentation (greenbone.github.io/docs) and save it here as `compose.yaml`. Greenbone updates this file, so always use the latest copy.

## Step 3: Download and Start

```
docker compose -f compose.yaml -p greenbone-community-edition pull
docker compose -f compose.yaml -p greenbone-community-edition up -d
```

The first download is large. Give it time.

## Step 4: Set the Admin Password

The default login is `admin` / `admin`. Change it right away:

```
docker compose -f compose.yaml -p greenbone-community-edition \
  exec -u gvmd gvmd gvmd --user=admin --new-password='YOUR-PASSWORD'
```

Keep the single quotes if your password has special characters.

## Step 5: Open the Web Page

By default the web interface only answers on the server itself: `http://127.0.0.1:9392`.

To reach it from your own computer, either:

- **Use an SSH tunnel** (safest): `ssh -L 9392:127.0.0.1:9392 user@SERVER-IP`, then browse to `http://127.0.0.1:9392`.
- **Or change the port setting** in `compose.yaml` from `127.0.0.1:9392:80` to `9392:80`, then firewall it to IT only.

## Step 6: Wait for the Feeds

OpenVAS downloads its vulnerability database on first start. **Scans won't work until it finishes**, which can take a while. Check **Administration > Feed Status** and wait until every feed shows current.

## Step 7: Run Your First Scan

1. **Configuration > Targets > New Target.** Enter one or two test hosts, not your whole network.
2. **Scans > Tasks > New Task.** Pick the target and the **Full and fast** scan configuration.
3. Start the task.
4. When it's done, open **Scans > Reports**.

## Read the Report

Results are ranked by severity.

1. Start with **High** findings.
2. Look for patterns: one missing patch on 40 machines is one fix, not 40.
3. Mark false positives so they don't clutter the next report.
4. Fix, then scan again to confirm.

## Keep It Updated

**Update** the containers every month or two:

```
cd ~/greenbone
docker compose -f compose.yaml -p greenbone-community-edition pull
docker compose -f compose.yaml -p greenbone-community-edition up -d
```

The feeds update in the background.
