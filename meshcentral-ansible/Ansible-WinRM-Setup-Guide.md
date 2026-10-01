# Ansible Control Node Setup

Installing Ansible, Configuring WinRM via Group Policy,

and Verifying Connectivity to Windows Hosts

*Cybersecurity on a Library Budget | github.com/adambranscum/library-it-toolkit*

*Questions? [abranscum@nlrlibrary.org](mailto:abranscum@nlrlibrary.org)*

## What This Guide Covers

This guide walks through the three pieces needed before Ansible can manage Windows machines from a Linux control node:

1. Installing Ansible on a Linux server (the control node)
2. Enabling and configuring WinRM on target Windows machines via Group Policy, so Ansible has something to connect to
3. Basic commands to test that a Windows host is actually reachable and responding

## Part 1: Installing Ansible on a Linux Server

Ansible only needs to be installed on the control node — the Linux machine you'll run commands from. It does not need to be installed on the Windows machines it manages; those just need WinRM enabled (covered in Part 2).

### 1.1  Update the system

Start with a clean, updated system before installing anything:

```
sudo apt update
sudo apt upgrade -y
```

### 1.2  Install Ansible

On Ubuntu/Debian, the simplest reliable method is the official PPA, which keeps Ansible itself up to date independently of the OS release:

```
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
```

Confirm the install and check the version:

```
ansible --version
```

### 1.3  Install the Windows connection dependencies

Ansible talks to Windows over WinRM using a Python library called pywinrm. This is not installed by default and must be added separately:

```
sudo apt install -y python3-pip
pip3 install pywinrm --break-system-packages
```

Install the official Windows collection, which provides the win_ping, win_updates, win_shell, and other Windows-specific modules used throughout this guide:

```
ansible-galaxy collection install ansible.windows
```

### 1.4  Create an inventory file

Ansible needs a list of hosts to manage. Create a dedicated inventory directory and a hosts file inside it:

```
sudo mkdir -p /etc/ansible
sudo nano /etc/ansible/hosts
```

Add a Windows group with at least one target machine's FQDN:

```
[windows]
testpc1.domain.local

[windows:vars]
ansible_connection=winrm
ansible_winrm_transport=ntlm
ansible_port=5985
ansible_winrm_scheme=http
```

## Part 2: Enabling WinRM via Group Policy

WinRM (Windows Remote Management) is what actually lets Ansible connect to a Windows machine. It's built into Windows but disabled by default. Rather than enabling it manually on every machine, a Group Policy Object (GPO) pushes the configuration to every computer in the target OU automatically.

### 2.1  Create the GPO

On a Domain Controller (or a machine with the Group Policy Management console installed):

1. Open Group Policy Management.
2. Right-click the Organizational Unit (OU) containing the target machines.
3. Select "Create a GPO in this domain, and Link it here..."
4. Name it something clear, e.g. Enable WinRM - Ansible.

### 2.2  Allow the WinRM service to run

Edit the new GPO and navigate to:

```
Computer Configuration
  -> Policies
    -> Administrative Templates
      -> Windows Components
        -> Windows Remote Management (WinRM)
          -> WinRM Service
```

Enable the following setting:

- **Allow remote server management through WinRM,** set to Enabled, with both IPv4 and IPv6 filters set to \* (asterisk), which allows connections from any address.

### 2.3  Set the WinRM service to start automatically

Still within the GPO, navigate to:

```
Computer Configuration
  -> Preferences
    -> Control Panel Settings
      -> Services
```

1. Right-click -> New -> Service.
2. Service name: WinRM
3. Startup: Automatic
4. Service action: Start service

### 2.4  Open the firewall for WinRM

Navigate to:

```
Computer Configuration
  -> Policies
    -> Windows Settings
      -> Security Settings
        -> Windows Defender Firewall with Advanced Security
          -> Inbound Rules
```

Create a New Rule:

1. Rule type: Port
2. Protocol: TCP, specific local port: 5985 (HTTP). Use port 5986 instead if using HTTPS/encrypted WinRM
3. Action: Allow the connection
4. Scope it to the control node's IP address only, rather than leaving it open to all sources

### 2.5  Add the Ansible service account to local Administrators

Ansible's connecting account needs local admin rights on each target machine to run most modules. Under:

```
Computer Configuration
  -> Preferences
    -> Control Panel Settings
      -> Local Users and Groups
```

1. Right-click -> New -> Local Group.
2. Group name: Administrators (built-in)
3. Action: Update
4. Add the Ansible service account as a member

### 2.6  Apply and verify

Force a policy refresh on a test machine rather than waiting for the normal refresh cycle:

```
gpupdate /force
```

Confirm the WinRM listener is active on that machine:

```
winrm enumerate winrm/config/listener
```

A working listener shows output similar to:

```
Listener
    Address = *
    Transport = HTTP
    Port = 5985
    Enabled = true
```

## Part 3: Basic Testing Command

Once Ansible is installed and WinRM is enabled on the target, these commands confirm the connection actually works before running anything real.

### 3.1  Ping a single host

Ansible's win_ping module is the standard first test. It confirms authentication and module execution both work, not just network reachability:

```
ansible testpc1.domain.local -m ansible.windows.win_ping
```

A successful response looks like:

```
testpc1.domain.local | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```
