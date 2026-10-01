# Wazuh Server Setup

Installation, Agent Groups, and Event Archives

*Cybersecurity on a Library Budget | github.com/adambranscum/library-it-toolkit*

*Questions? [abranscum@nlrlibrary.org](mailto:abranscum@nlrlibrary.org)*

## Part 1: Installing Wazuh

Wazuh's all-in-one installer sets up the manager, the indexer (OpenSearch), and the dashboard together on a single node.

```
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
sudo bash wazuh-install.sh -a
```

The install prints the admin username and a randomly generated password at the end. Save it immediately, it is not shown again without a separate reset step.

Confirm all three components are running:

```
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard --no-pager
```

## Part 2: Checking Disk Sizing (LVM)

On a VM provisioned with a specific disk size, the installer's default partitioning can leave most of that space unused if the logical volume was never extended to the full disk. This causes the indexer to eventually fail with "No space left on device" even though the underlying virtual disk has plenty of room.

Compare the filesystem's reported size against the actual disk:

```
df -h /
lsblk
```

If lsblk shows the physical disk at its full intended size but the logical volume mounted at / is significantly smaller, extend it to use the rest of the available space:

```
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
df -h /
```

## Part 3: Organizing Agents into Groups

Every agent group has its own configuration file (agent.conf) that is pushed down to every member automatically. Configuration is not inherited between groups. Each group's file is independent and must be set individually.

### 3.1  Create groups by OS and role

Rather than one blanket configuration, create a separate group for each meaningfully different type of machine, for example:

- Windows workstations (by branch/department as needed)
- Windows servers
- Domain controllers (kept separate from general servers — see below)
- Linux servers
- macOS

In the dashboard: Agents management -> Groups -> Add new group.

### 3.2  Edit a group's configuration

Open the group -> Files tab -> edit agent.conf. A Windows workstation baseline covering file integrity monitoring, vulnerability/software-configuration scanning, and core Windows event log collection looks like this:

```
<agent_config>
  <sca>
    <enabled>yes</enabled>
    <scan_on_start>yes</scan_on_start>
    <interval>12h</interval>
  </sca>
  <syscheck>
    <disabled>no</disabled>
    <frequency>43200</frequency>
    <directories check_all="yes" realtime="yes">C:\Windows\System32\drivers\etc</directories>
    <directories check_all="yes">C:\Windows\System32</directories>
    <directories check_all="yes">C:\Program Files</directories>
    <directories check_all="yes">C:\Program Files (x86)</directories>
  </syscheck>
  <localfile>
    <location>Security</location>
    <log_format>eventchannel</log_format>
  </localfile>
  <localfile>
    <location>System</location>
    <log_format>eventchannel</log_format>
  </localfile>
  <localfile>
    <location>Application</location>
    <log_format>eventchannel</log_format>
  </localfile>
</agent_config>
```

Servers add realtime monitoring on the registry hives and scheduled tasks folder, plus PowerShell logging. Domain controllers add the same server baseline plus realtime monitoring on the NTDS database and SYSVOL, and Directory Service / DNS Server event channels. Linux uses Unix-style paths and syslog files (/etc, /etc/passwd, /var/log/auth.log) instead of eventchannel. macOS uses /var/log/system.log and /var/log/auth.log, plus FIM on the LaunchAgents/LaunchDaemons persistence locations.

### 3.3  Install and enroll an agent into a specific group

The Windows install command includes the manager address and the target group directly, so the agent lands in the correct group at install time rather than needing to be moved afterward:

```
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.7-1.msi -OutFile $env:tmp\wazuh-agent.msi
msiexec.exe /i $env:tmp\wazuh-agent.msi /q WAZUH_MANAGER='<manager-ip>' WAZUH_AGENT_GROUP='<group-name>'
NET START WazuhSvc
```

## Part 4: Enabling Full Event Archives

By default Wazuh only stores events that trigger a rule ("alerts"). Archives capture every collected event, including ones that never matched a rule.

### 4.1  Turn on archive logging

```
sudo grep -E 'logall|logall_json' /var/ossec/etc/ossec.conf
```

If both show no, back up the config and enable them:

```
sudo cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak
sudo sed -i 's/<logall>no<\/logall>/<logall>yes<\/logall>/' /var/ossec/etc/ossec.conf
sudo sed -i 's/<logall_json>no<\/logall_json>/<logall_json>yes<\/logall_json>/' /var/ossec/etc/ossec.conf
sudo systemctl restart wazuh-manager
```

Confirm the archive files start populating:

```
ls -lh /var/ossec/logs/archives/
```

### 4.2  Set a retention window on the archive files

Wazuh rotates archive files by date internally but never deletes old ones on its own. A daily cron job handles cleanup based on file age:

```
sudo tee /etc/cron.daily/wazuh-archive-cleanup > /dev/null <<'EOF'
#!/bin/bash
find /var/ossec/logs/archives -type f \( -name "*.log" -o -name "*.json" \) -mtime +14 -delete
find /var/ossec/logs/archives -type d -empty -delete
EOF
sudo chmod +x /etc/cron.daily/wazuh-archive-cleanup
```

The currently active archives.log and archives.json files are separately rotated with logrotate, using copytruncate rather than the default rename-based rotation. Wazuh keeps internal hard links to these files that a normal rotation would break:

```
sudo tee /etc/logrotate.d/wazuh-archives > /dev/null <<'EOF'
/var/ossec/logs/archives/archives.log
/var/ossec/logs/archives/archives.json
{
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF
```

## Part 5: Fixing Dashboard Login for a Manually Created User

An internal user created through the dashboard's Security panel can sometimes display correctly in the Users list and still fail to log in with "Invalid username or password," even with the exact password that was set. This happens when the account was never fully written to OpenSearch's security backend, despite appearing in the UI.

### 5.1  Generate a password hash directly

The hashing tool needs the indexer's bundled Java runtime, which is not on the system PATH by default:

```
sudo OPENSEARCH_JAVA_HOME=/usr/share/wazuh-indexer/jdk /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh -p '<password>'
```

### 5.2  Add the user directly to the internal users file

```
sudo nano /etc/wazuh-indexer/opensearch-security/internal_users.yml
```

```
<username>:
  hash: "<hash from previous step>"
  reserved: false
  backend_roles:
  - "admin"
  description: "<description>"
```

### 5.3  Force OpenSearch to reload the security configuration

This is the step the dashboard UI does not reliably perform on its own. Confirm the certificate filenames first, they can vary by install:

```
sudo find /etc/wazuh-indexer -iname "*admin*.pem"
sudo find /etc/wazuh-indexer -iname "*root-ca*"
```

```
sudo OPENSEARCH_JAVA_HOME=/usr/share/wazuh-indexer/jdk /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /etc/wazuh-indexer/opensearch-security/ \
  -icl \
  -key /etc/wazuh-indexer/certs/admin-key.pem \
  -cert /etc/wazuh-indexer/certs/admin.pem \
  -cacert /etc/wazuh-indexer/certs/root-ca.pem \
  -nhnv
```

A successful run ends with "Done with success" and confirms internal users was included in the updated configuration types. The account can then log in normally with the password that was hashed in step 5.1.
