# MeshCentral Server Setup

Installing the Server, Deploying Agents via Group Policy,

and Verifying Device Connectivity

*Cybersecurity on a Library Budget | github.com/adambranscum/library-it-toolkit*

*Questions? [abranscum@nlrlibrary.org](mailto:abranscum@nlrlibrary.org)*

## What This Guide Covers

This guide walks through the three pieces needed for a working MeshCentral remote-management setup:

1. Installing MeshCentral on a Linux server and putting it behind a reverse proxy
2. Deploying the MeshCentral agent to Windows machines via Group Policy, so devices actually appear in the console

## Part 1: Installing MeshCentral

MeshCentral runs as a Node.js application. It's installed once, on a single Linux server that all agents will connect back to.

### 1.1  Install Node.js

MeshCentral needs a current Node.js LTS release. Add the NodeSource repository and install it:

```
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v
```

### 1.2  Create the install directory and install MeshCentral

MeshCentral installs into its own folder rather than system-wide. Create the folder and run the install from inside it. Do not use sudo for the npm install itself:

```
sudo mkdir -p /opt/meshcentral
sudo chown $USER /opt/meshcentral
cd /opt/meshcentral
npm install meshcentral
```

### 1.3  First run: generate the default config

Starting MeshCentral once creates its default configuration and database, then stop it to edit the config:

```
node node_modules/meshcentral
```

Press Ctrl+C once it finishes starting up. A config.json file now exists in the meshcentral-data folder.

### 1.4  Configure for a reverse proxy

If MeshCentral will sit behind an existing web server (Nginx or Apache, already serving other sites on the same box), it shouldn't bind directly to port 443. Edit meshcentral-data/config.json and set:

```
"settings": {
    "cert": "mesh.yourdomain.org",
    "port": 4430,
    "aliasPort": 443,
    "redirPort": 8080,
    "TLSOffload": "127.0.0.1"
}
```

port is what MeshCentral actually listens on locally. aliasPort tells agents that the real public-facing port is 443, since the reverse proxy is what actually terminates that connection. TLSOffload tells MeshCentral to trust the proxy's forwarded headers instead of expecting to handle TLS itself.

### 1.5  Run MeshCentral as a service

Create a systemd unit so the server starts on boot and restarts if it crashes:

```
sudo tee /etc/systemd/system/meshcentral.service > /dev/null <<'EOF'
[Unit]
Description=MeshCentral Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/meshcentral
ExecStart=/usr/bin/node node_modules/meshcentral
Restart=always

[Install]
WantedBy=multi-user.target
EOF
```

```
sudo systemctl daemon-reload
sudo systemctl enable --now meshcentral
sudo systemctl status meshcentral --no-pager
```

### 1.6  Create the admin account and lock down signups

The first account created through the web login page automatically becomes the site administrator. After that account exists, disable further open signups in config.json:

```
"newAccounts": false
```

Restart the service after any config.json change:

```
sudo systemctl restart meshcentral
```

## Part 2: Deploying Agents via Group Policy

Devices don't appear in MeshCentral until they have the agent installed and running. Rather than installing it by hand on every machine, a GPO pushes it automatically to every computer in the target OU.

### 2.1  Create a Device Group and get its install command

In the MeshCentral web console:

1. My Devices -> Add Device Group.
2. Name it clearly, e.g. Domain Workstations.
3. Open the new group -> Add Agent.
4. Select Windows, and copy the provided background/silent install command. It includes a unique mesh ID tying any device installed with it to that specific group.

### 2.2  Host the installer on a share the GPO can reach

Download the .exe from the Add Agent page and place it somewhere every target machine can read, such as SYSVOL or a dedicated read-only share:

```
\\yourdomain.local\NETLOGON\MeshAgent.exe
```

### 2.3  Create the GPO

On a Domain Controller, in Group Policy Management:

1. Right-click the target OU -> Create a GPO in this domain, and Link it here...
2. Name it something clear, e.g. Deploy MeshCentral Agent.

### 2.4  Push the install with a startup script

Under:

```
Computer Configuration
  -> Policies
    -> Windows Settings
      -> Scripts (Startup/Shutdown)
        -> Startup -> PowerShell Scripts
```

Add a script that runs the installer silently and checks first so it doesn't reinstall on every boot:

```
if (-not (Get-Service -Name "Mesh Agent" -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath "\\yourdomain.local\NETLOGON\MeshAgent.exe" -ArgumentList "-fullinstall" -Wait
}
```

### 2.5  Apply and verify

Force a policy refresh on a test machine and confirm the service exists and is running:

```
gpupdate /force
Get-Service -Name "Mesh Agent"
```

The machine should appear online in its assigned Device Group in the MeshCentral console within a minute or two.

## Part 3: Basic Verification Command

Once the agent is installed, a few checks confirm the device is actually connected and reachable, both from the server side and the client side.

### 3.1  Check the agent service is running (on the client)

```
Get-Service -Name "Mesh Agent"
```
