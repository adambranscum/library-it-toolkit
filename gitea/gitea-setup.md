# Gitea Setup (Docker)

## 1. Port Mapping

Host SSH (port 22) is already in use, so map Gitea's container SSH to 2222.

```yaml
ports:
  - "3000:3000"
  - "2222:22"
```

## 2. Open the Install Page

```
http://192.168.13.18:3000/
```

## 3. Database Settings

| Field | Value |
|---|---|
| Database Type | SQLite3 |
| Path | `/data/gitea/gitea.db` |

## 4. General Settings

| Field | Value |
|---|---|
| Site Title | (your choice) |
| Data Path | `/data/gitea` |
| Run As Username | `git` (auto-detected, not editable) |
| SSH Server Port | `2222` |
| HTTP Server Port | `3000` |
| Gitea Website URL | `http://192.168.13.18:3000/` |

## 5. Checkboxes

- [x] Only administrators can create user accounts (no self-registration)
- [x] Require sign-in to view pages
- [ ] Enable registration CAPTCHA
- [x] Enable update checker

## 6. Administrator Account

Expand **Administrator Account Settings** and create the admin user before installing.

## 7. Install

Click **Install Gitea**. If the page hangs or redirects incorrectly, browse manually to:

```
http://192.168.13.18:3000/
```
