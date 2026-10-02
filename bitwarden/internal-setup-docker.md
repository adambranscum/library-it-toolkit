# Internal Setup - Docker

Vaultwarden break-glass password manager. IP-only, no domain, no DNS dependency. Web vault only (no browser extension).

Replace `<SERVER_IP>` with the Docker host's IP address. Use a static IP or DHCP reservation.

## Requirements

- Docker and Docker Compose on the host
- Two containers: `caddy` (image `caddy:2`) and `vaultwarden` (image `vaultwarden/server:latest`)
- Both containers on the same Docker network
- Only Caddy publishes ports 80 and 443. Vaultwarden only exposes 80 internally (do not publish it)
- Project folder: `/opt/vaultwarden`

## 1. Caddyfile

Put this at the very top of the Caddyfile:

```
{
    default_sni <SERVER_IP>
}

https://<SERVER_IP> {
    tls internal
    reverse_proxy vaultwarden:80
}
```

Why `default_sni`: browsers send no SNI when connecting by IP, and Docker NAT hides the real destination IP from Caddy. Without this, the TLS handshake fails with an internal error.

## 2. Vaultwarden environment

In the `vaultwarden` service in the compose file:

```yaml
environment:
  - DOMAIN=https://<SERVER_IP>
```

Match your existing format (list with dashes, or `KEY: value`).

## 3. Start

```
cd /opt/vaultwarden
sudo docker compose up -d --force-recreate
```

## 4. Reload Caddy after any Caddyfile change

```
sudo docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## 5. Test

```
curl -vk https://<SERVER_IP> 2>&1 | grep -E "HTTP/|subject|issuer"
```

Expected: `HTTP/2 200` and issuer `Caddy Local Authority`.

## 6. Create accounts

1. Browse to `https://<SERVER_IP>`
2. Accept the certificate warning (Firefox: Advanced, then Accept the Risk and Continue)
3. Click **Create account**
4. Use a long master password. It cannot be reset. Store it offline.
5. Create each admin account needed

## 7. Disable signups

After all accounts exist, add to the `vaultwarden` environment:

```yaml
  - SIGNUPS_ALLOWED=false
```

If env vars are in a `.env` file, put `SIGNUPS_ALLOWED=false` there instead.

Apply:

```
sudo docker compose up -d --force-recreate
```

Confirm you can still log in.

## 8. Keep it break-glass

- Back up `/opt/vaultwarden/data` to a location that does not depend on Active Directory
- Firewall port 443 to admin hosts only
- Keep the host independent of AD and DNS

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `SSL_ERROR_INTERNAL_ERROR_ALERT` on the IP | Missing `default_sni` | Add the global block from step 1, reload Caddy |
| "SSL received a record that exceeded the maximum permissible length" | HTTPS sent to port 80 | Use `https://<SERVER_IP>` with no `:80` |
| Certificate warning | `tls internal` cert is not trusted by the browser | Accept the exception, or import Caddy's root CA |
| Changes to Caddyfile not applied | Caddy not reloaded | Run the reload command in step 4 |
