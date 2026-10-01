# Semaphore Installation

Installing Semaphore and Connecting It to an Existing Ansible Control Node

*Cybersecurity on a Library Budget | github.com/adambranscum/library-it-toolkit*

*Questions? [abranscum@nlrlibrary.org](mailto:abranscum@nlrlibrary.org)*

## Part 1: Installing Semaphore

### 1.1  Download and install the package

Find the current release, download and install it:

```
curl -s https://api.github.com/repos/semaphoreui/semaphore/releases/latest | grep tag_name

cd /tmp
curl -LO https://github.com/semaphoreui/semaphore/releases/download/vX.X.X/semaphore_X.X.X_linux_amd64.deb
sudo dpkg -i semaphore_X.X.X_linux_amd64.deb
```

> **Note:**  Replace X.X.X with the version the first command actually returned.

### 1.2  Create the config directory before running setup

The setup wizard's SQLite option fails with "unable to open database file" if its target directory doesn't already exist. Create it first:

```
sudo mkdir -p /etc/semaphore
```

### 1.3  Run the setup wizard

```
sudo semaphore setup
```

Answer the prompts as follows:

- What database to use: 4 (SQLite)
- db Hostname (this is actually the SQLite file path): /etc/semaphore/database.sqlite
- Playbook path: the path to the existing Ansible repo, e.g. /root/ansible
- Public URL: leave blank for an internal-only server
- Enable email alerts: yes or no, depending on whether SMTP is available
- Telegram / Slack / Rocket.Chat / Microsoft Teams alerts: no
- Enable LDAP authentication: no
- Config output directory: /var/lib/semaphore/output

### 1.4  Create the systemd service

The .deb package does not ship a systemd unit It has to be created manually so Semaphore starts on boot and restarts if it crashes:

```
sudo tee /etc/systemd/system/semaphore.service > /dev/null <<'EOF'
[Unit]
Description=Semaphore Ansible UI
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/semaphore server --config /var/lib/semaphore/output/config.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

```
sudo systemctl daemon-reload
sudo systemctl enable --now semaphore
sudo systemctl status semaphore --no-pager
```

Log in at http://\<server-ip>:3000 with the admin account created during setup.

## Part 2: Connecting Semaphore to Ansible

Semaphore needs four things configured before it can run a playbook: a Project, a way to authenticate to the git repository, the Repository itself, and an Inventory.

### 2.1  Create a Project

In the web UI, create a new Project — this is just a container for everything else below.

### 2.2  Add the SSH key for the git repository

Semaphore pulls the playbook repo itself, so it needs a key authorized against it. If the server already has a working deploy key for the repo, reuse it rather than generating a new one:

```
cat ~/.ssh/id_ed25519
```

In Key Store -> Add Key, set Type to SSH Key and paste the full private key.

### 2.3  Add the Repository

Repositories -> Add Repository:

- URL: the repo's SSH remote, e.g. git@github.com:org/repo.git
- Branch: master (or the actual default branch)
- Access Key: the SSH key added in the previous step

### 2.4  Add the Inventory

Inventory -> Add Inventory:

- Type: File
- Path: the inventory file's path relative to the repo root, e.g. inventories/production/hosts.ini
- Repository: the repository added above

### 2.5  Create a Task Template

Task Templates -> Add Template:

- Repository: the repository added above
- Playbook: the path to the playbook file, e.g. playbooks/install-updates.yml
- Inventory: the inventory added above
- Ansible options -> Limit: an inventory group name, to scope this template to a specific set of hosts rather than everything

Save, then run it once manually to confirm it completes before attaching a schedule.

### 2.6  Set the correct timezone before scheduling

Semaphore's cron field defaults to UTC regardless of the server's own timezone. Set this once before creating any schedules, or every scheduled time will be off by several hours:

```
sudo nano /var/lib/semaphore/output/config.json
```

Add this key at the top level of the file, alongside the existing settings:

```
"schedule": {
    "timezone": "America/Chicago"
}
```

```
sudo systemctl restart semaphore
```

After the restart, the cron field in the Schedule editor is labeled with the configured timezone instead of UTC, and times can be entered directly in local time.

### 2.7  Add a Schedule

Open the Task Template -> Schedules -> add a cron expression and confirm the "Next run time" preview shows the intended local time before saving.
