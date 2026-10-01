# Library IT Toolkit

Free, open-source setup guides and scripts for small and midsize library IT departments.

Everything here is built on free tools and written for a small team, often a team of one. Each guide is step by step, with system requirements up front, so you can decide if it fits before you start.

Created for the **"Invisible Infrastructure, Visible Impact"** session and the **"Cybersecurity on a Library Budget"** poster at the 2026 KLA/SELA Conference.

---

## How to Use This Repo

1. Find the guide you need in the tables below.
2. Open its folder and read the `README.md` first, which starts with system requirements.
3. Follow the steps in order.
4. Start small. Every guide ends with a "Start Small" section for your first step.

## Guides

### Phones and Network

| Guide | What It Covers |
|---|---|
| [VoIP and Fax](voip-fax/voip-fax-setup-guide.md) | FreePBX phones, fax server, voice VLAN, DHCP provisioning, holiday messages |
| [Collapsed Core](network/Collapsed-Core-Architecture.md) | Collapsed core architecture: how it works, benefits, trade-offs |

### Monitoring and Security

| Guide | What It Covers |
|---|---|
| [Wazuh](wazuh/Wazuh-Setup-Guide.md) | Device security monitoring (SIEM) and agent rollout |
| [Security Onion](security-onion/Security-Onion-Setup-Guide.md) | Network security monitoring with a mirror port |
| [Uptime Kuma](uptime-kuma/Uptime-Kuma-Setup-Guide.md) | Uptime monitoring for vendors, servers, and your website |
| [OpenVAS](openvas/openvas-setup-guide.md) | Vulnerability scanning with Greenbone Community Edition |
| [Gophish](gophish/gophish-setup-guide.md) | Phishing awareness training for staff |
| [Docker Alternative Stack](docker-alt-stack/docker-alt-stack-guide.md) | Wazuh, Malcolm, and Uptime Kuma in Docker on one server |

### Tools and Management

| Guide | What It Covers |
|---|---|
| [MeshCentral, Ansible, and Semaphore](meshcentral-ansible/) | Remote management, automated updates, scheduling, and logging |
| [Ansible Scripts](ansible-scripts/) | Example playbooks and scripts (placeholders only, no real hosts or secrets) |
| [Gitea](gitea/gitea-setup-guide.md) | Self-hosted Git for configs, scripts, and documentation |
| [Vaultwarden](bitwarden/vaultwarden-setup-guide.md) | Self-hosted password manager that works with Bitwarden apps |

## By Presentation

**Invisible Infrastructure, Visible Impact (session)**
VoIP and Fax, MeshCentral/Ansible, Wazuh, Uptime Kuma, Security Onion, Collapsed Core, Docker Alternative Stack

**Cybersecurity on a Library Budget (poster)**
Security Onion, Wazuh, OpenVAS, Gophish, Gitea, Vaultwarden, Ansible Scripts

## Before You Start

- **Test first.** Try each guide on a test machine or virtual machine before production.
- **Back up** anything you're about to change.
- **Check versions.** Free tools update often. If a menu or command differs from a guide, follow the tool's current official documentation.
- **Your environment is different.** Guides show one working approach, not the only one.

## Security Note

Example files in this repo use placeholder names, addresses, and passwords. Replace them with your own, and never commit real credentials. If you fork this repo, keep files like `.env` and vault files in your `.gitignore`.

## Get Help

Questions, corrections, or want to share how it went at your library?

- Open an **Issue** in this repo
- Email **abranscum@nlrlibrary.org**

## About

Maintained by Adam Branscum, IT Manager, North Little Rock Public Library System.

## License

Add a license before publishing. **MIT** is a common choice for this kind of repo and lets other libraries use and adapt it freely.
