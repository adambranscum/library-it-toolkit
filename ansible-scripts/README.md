# Ansible Scripts

Example Ansible playbooks for managing a small fleet of Windows PCs (and a few Linux servers) from one control node.

Everything here uses **placeholder names, addresses, and passwords**. Replace them with your own. Never commit real credentials.

Built to go with the **Ansible + WinRM Setup Guide**: finish that first so `win_ping` works.

## What's Inside

| Path | Purpose |
|---|---|
| `ansible.cfg` | Defaults: inventory path, forks, timeouts |
| `requirements.yml` | Collections to install (`ansible.windows`, `community.windows`) |
| `inventories/production/hosts.ini` | Example inventory with placeholder hosts |
| `group_vars/all/vars.yml` | Log folder and heartbeat thresholds |
| `group_vars/windows/vars.yml` | WinRM settings, update and onboarding variables |
| `group_vars/windows/vault.yml.example` | Template for the encrypted password file |
| `group_vars/linux/vars.yml` | SSH settings for Linux hosts |
| `playbooks/` | The playbooks (below) |
| `scripts/onboard-machine.sh` | Interactive helper for adding a new machine |
| `logs/` | Output on the control node (not committed) |

## Playbooks

| Playbook | What It Does | Changes Anything? |
|---|---|---|
| `win-ping.yml` | Tests WinRM auth and module execution | No |
| `scan-updates.yml` | Counts pending Windows updates | No |
| `install-updates.yml` | Installs updates, reboots if needed, logs result | Yes |
| `update-software.yml` | Runs `winget upgrade --all` | Yes |
| `heartbeat.yml` | CPU, RAM, disk per host. Logs threshold breaches | No |
| `inventory-check.yml` | Pending updates and outdated app counts | No |
| `onboard-new-machine.yml` | Time zone, apps, local groups, shortcuts, optional auto-login | Yes |
| `update-linux.yml` | `apt` upgrade and reboot if needed (Linux servers) | Yes |

## Setup

Run from the folder that holds `ansible.cfg`. Relative paths break from anywhere else.

```bash
cd ~/ansible-scripts
ansible-galaxy collection install -r requirements.yml
cp group_vars/windows/vault.yml.example group_vars/windows/vault.yml
nano group_vars/windows/vault.yml          # set the service account password
ansible-vault encrypt group_vars/windows/vault.yml
```

Then edit:

1. `inventories/production/hosts.ini`: your hosts and groups.
2. `group_vars/windows/vars.yml`: your service account (`ansible_user`) and domain.

## Run Something

Start read-only, on one group:

```bash
ansible-playbook playbooks/win-ping.yml --ask-vault-pass -e target=branch_a_staff
ansible-playbook playbooks/scan-updates.yml --ask-vault-pass -e target=branch_a_staff
```

Use `-e target=` to pick a group or a single host. Leave it off to run on every Windows machine.

To skip the vault prompt, put the vault password in `.vault_pass` (it's in `.gitignore`), `chmod 600` it, and add `--vault-password-file .vault_pass`.

## Kerberos Instead of NTLM

NTLM works out of the box and matches the setup guide. For a domain, Kerberos is better because no password sits in Ansible. See the comments in `group_vars/windows/vars.yml`.

## Scheduling

Use cron or [Semaphore](https://semaphoreui.com) (free web UI for Ansible).

- **Heartbeat:** every 15-30 minutes.
- **Updates:** weekly, after hours, one group at a time (staggered).
- **Inventory check:** every 12 hours.

If you use Semaphore, its cron field expects UTC unless you set a timezone in its config.

## Safety

- **Test on one machine first.** Then one group. Then the fleet.
- **Updates reboot machines.** Schedule after hours and stagger groups so a whole branch is never down together.
- **Auto-login stores a password in the registry.** It's off by default. Only use it on locked-down public PCs.
- **winget over WinRM can behave differently than at the console.** Test `update-software.yml` before scheduling it.
- **Keep secrets out of git.** `.gitignore` already covers `vault.yml`, `.vault_pass`, keytabs, and `.env`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `UNREACHABLE` or "No route to host" | Check DNS first: `getent hosts HOSTNAME` |
| "Server not found in Kerberos database" | The hostname in the inventory has no matching AD computer record |
| Auth failure | Confirm the service account is in local Administrators on the target (GPO) |
| Module errors on one machine only | That machine's local PowerShell may be broken. Not an Ansible problem |
| Playbook can't find files | Run from the repo root |
