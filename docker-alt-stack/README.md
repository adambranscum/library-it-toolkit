# Docker Alternative Stack Guide

**Run device security, network monitoring, and uptime monitoring on one small server.**
Invisible Infrastructure, Visible Impact | freewareforlibraries.org
Questions? abranscum@nlrlibrary.org

---

## Who This Is For

This is the alternative for libraries with **one spare server** and no virtual machine host or dedicated hardware.

Our production setup is Wazuh on its own VM and Security Onion on dedicated hardware. This guide shows the Docker-based equivalent of each.

## The Stack

| Job | Our Production Tool | Docker Alternative |
|---|---|---|
| Device security | Wazuh (all-in-one install) | **Wazuh** (official Docker deployment) |
| Network monitoring | Security Onion | **Malcolm** (Zeek, Suricata, Arkime, OpenSearch) |
| Uptime monitoring | Uptime Kuma | **Uptime Kuma** (Docker) |

**Good to know:** Security Onion is a full operating system, so it does not run in Docker. Malcolm is a different product that covers similar ground: traffic metadata, intrusion alerts, and full packet search.

## System Requirements

These are starting points. Check each project's documentation before buying hardware.

| | Wazuh | Malcolm | Uptime Kuma |
|---|---|---|---|
| Memory | 8 GB (under 50 devices) | 16 GB minimum, **32 GB recommended** for live capture | 1-2 GB |
| CPU cores | 4 | 4-8 | 1 |
| Storage | 100 GB | 100 GB+ (more = longer packet history) | 10 GB |

### One Box or Separate Boxes?

| Option | Recommended Size |
|---|---|
| **All three on one server** | 8+ cores, 64 GB DDR4 RAM, 1 TB SSD, **2 network ports** |
| **Wazuh + Kuma on one, Malcolm on its own** | Wazuh box: 8 GB, 4 cores, 100 GB. Malcolm box: 32 GB, 4-8 cores, 500 GB SSD, 2 network ports |

Notes:
- Docker does not make these tools lighter. It changes how you install them.
- The server needs **two network ports**: one for management (web pages, agents, SSH) and one dedicated to Malcolm's mirror port traffic with no IP address.
- Docker containers share the management port. They do not each need their own port.
- Use SSD storage. Searches get slow on spinning disks.

## Step 1: Prepare the Server

1. Install **Ubuntu Server 24.04** (or another current Linux).
2. Give the management port a **static IP**.
3. Install Docker:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2 git
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

4. Log out and back in so the Docker group change applies.
5. Raise the memory map limit. Wazuh's indexer will not work without it:

```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

## Step 2: Install Wazuh

```bash
git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.7
cd wazuh-docker/single-node
docker compose -f generate-indexer-certs.yml run --rm generator
```

**Before starting it on a server that will also run Malcolm:** both use port 443 for their web pages by default. Open `docker-compose.yml` in this folder and change the Wazuh dashboard's published port from `443` to another number such as `8443`.

```bash
nano docker-compose.yml
docker compose up -d
```

Then open `https://SERVER-IP` (or `https://SERVER-IP:8443` if you changed it).

**Change the default login right away.** The default dashboard account is `admin` with the password `SecretPassword`. Follow Wazuh's documentation to change it.

### Connect Your Devices

Install the Wazuh agent on each computer and point it at your server's IP. The steps are the same as a normal Wazuh install.

| Port | Purpose |
|---|---|
| 1514 | Agent data |
| 1515 | Agent enrollment |
| 55000 | Wazuh API |

## Step 3: Install Malcolm

```bash
cd ~
git clone https://github.com/idaholab/Malcolm.git
cd Malcolm
sudo ./scripts/install.py
```

1. Follow the prompts. Say yes to installing missing Docker components if asked.
2. Answer yes when asked about **capturing live network traffic**, and choose your **capture network port** (the second one, not management).
3. Start Malcolm using the start script in the `scripts` folder:

```bash
./scripts/start
```

4. Open `https://SERVER-IP` and log in with the account you created during setup.

Malcolm's setup steps change between versions. If a prompt differs from this guide, follow the current quick start at **github.com/idaholab/Malcolm**.

## Step 4: Set Up the Mirror Port

Same as Security Onion. On your switch, create a port mirror (SPAN):

- **Source:** the port(s) you want to watch
- **Destination:** the port plugged into the server's **capture network port**

Start with the link between your firewall and core switch. Move to core capture once it is stable.

## Step 5: Install Uptime Kuma

Use the Uptime Kuma guide on freewareforlibraries.org. The short version:

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

Save it as `compose.yaml` in its own folder and run `docker compose up -d`. Open `http://SERVER-IP:3001`.

## Keep It Healthy

- **Back up** the Docker volumes and config folders before any update.
- **Update** one tool at a time, and test after each.
- **Watch disk space.** Malcolm and Wazuh both grow over time.
- **Check after reboots:** `docker ps` should list every container.

## What You Give Up

| Compared To Our Production Setup | Trade-Off |
|---|---|
| Security Onion has more built-in features and a polished alert console | Malcolm focuses on traffic analysis and search |
| One server runs everything | If it goes down, you lose monitoring on all three tools |
| Fewer machines to buy | You still need enough memory, storage, and a capture port |

## Start Small

Start with Wazuh and Uptime Kuma on one server. Add Malcolm when you have the memory and a mirror port ready.
