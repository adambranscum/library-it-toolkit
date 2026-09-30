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
| [voip-fax](voip-fax/) | FreePBX phones, fax server, voice VLAN, DHCP provisioning, holiday messages |
| [network](network/) | Collapsed core architecture and VLAN segmentation |

### Monitoring and Security

| Guide | What It Covers |
|---|---|
| [wazuh](wazuh/) | Device security monitoring (SIEM) and agent rollout |
| [security-onion](security-onion/) | Network security monitoring with a mirror port |
| [uptime-kuma](uptime-kuma/) | Uptime monitoring for vendors, servers, and your website |
| [docker-alt-stack](docker-alt-stack/) | Wazuh, Malcolm, and Uptime Kuma in Docker on one server |

### Endpoint Management

| Guide | What It Covers |
|---|---|
| [meshcentral-ansible](meshcentral-ansible/) | Remote management, automated updates, scheduling, and logging |
| [ansible-scripts](ansible-scripts/) | Example playbooks and scripts (placeholders only, no real hosts or secrets) |

### Coming Soon

| Guide | What It Covers |
|---|---|
| gitea | Self-hosted Git for configs and documentation |
| bitwarden | Self-hosted password management |
| gophish | Phishing awareness training |
| openvas | Vulnerability scanning |

## By Presentation

**Invisible Infrastructure, Visible Impact (session)**
voip-fax, meshcentral-ansible, wazuh, uptime-kuma, security-onion, network, docker-alt-stack

**Cybersecurity on a Library Budget (poster)**
security-onion, wazuh, gitea, bitwarden, gophish, openvas, ansible-scripts

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
