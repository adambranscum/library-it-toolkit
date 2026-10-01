# Gophish Setup Guide

Free phishing awareness training for your library staff.

*Cybersecurity on a Library Budget | github.com/adambranscum/library-it-toolkit*

*Questions? abranscum@nlrlibrary.org*

## What You Need

|  | Recommended |
| --- | --- |
| Memory | 1 GB |
| CPU cores | 1 |
| Storage | 5 GB |
| OS | Ubuntu 24.04 (or any Linux) |
| Mail | An account or server that can send email (SMTP) |
| Network | Staff computers can reach the server on port 80 |

It can share a small server with other light tools.

## Step 1: Download Gophish

Get the current Linux release from the project's GitHub releases page (github.com/gophish/gophish/releases).

```
sudo mkdir -p /opt/gophish && cd /opt/gophish
sudo apt install -y unzip wget
sudo wget https://github.com/gophish/gophish/releases/download/vVERSION/gophish-vVERSION-linux-64bit.zip
sudo unzip gophish-vVERSION-linux-64bit.zip
sudo chmod +x gophish
```

Replace `VERSION` with the release number you downloaded.

## Step 2: Edit the Settings

```
sudo nano config.json
```

Two settings matter:

| Setting | Default | What It Does |
| --- | --- | --- |
| `admin_server` `listen_url` | `127.0.0.1:3333` | The admin page. Keep it local, or use `0.0.0.0:3333` and firewall it to IT only |
| `phish_server` `listen_url` | `0.0.0.0:80` | The page staff see when they click. Must be reachable from staff computers |

Protect the file, since it can hold database settings:

```
sudo chmod 640 config.json
```

## Step 3: Start It

```
sudo ./gophish
```

Watch the output. On first start it prints a **temporary admin password**. Copy it right away, since it isn't saved anywhere.

## Step 4: Log In

1. Open `https://SERVER-IP:3333`. Your browser will warn about the certificate. That's expected with the built-in one.
2. Username: `admin`, password: the one from the output.
3. You'll be asked to set a new password. Use a long one and store it in your password manager.

## Step 5: Build a Campaign

Use the left menu, in this order.

### Sending Profile

Tells Gophish how to send mail.

1. **Sending Profiles > New Profile.**
2. Enter your SMTP server, port, and sending account.
3. Use **Send Test Email** to confirm it works.

### Landing Page

What staff see after clicking.

1. **Landing Pages > New Page.**
2. Write a short, friendly training page, such as "This was a test. Here's what to look for."
3. **Leave "Capture Submitted Data" and "Capture Passwords" off.**

### Email Template

The fake phishing email.

1. **Email Templates > New Template.**
2. Write a believable but generic message (a package notice, a shared document, a password expiry).
3. Include the link placeholder so clicks are tracked.
4. Don't imitate a real company's branding.

### Users & Groups

Who gets it.

1. **Users & Groups > New Group.**
2. Add staff names and email addresses, or import a CSV.

### Campaign

1. **Campaigns > New Campaign.**
2. Pick your template, landing page, sending profile, and group.
3. **URL:** the address staff can reach this server on, such as `http://SERVER-IP`.
4. Set a launch time during working hours.
5. Launch.

## Make Sure the Email Arrives

Mail filters often block or quarantine simulation emails. Before your first campaign:

1. Send a test to yourself and check it lands in the inbox.
2. If it doesn't, **allow-list** your sending server in your mail filter. Microsoft 365 has a dedicated setting for phishing simulations.
3. Test again.

## Read the Results

The dashboard shows who received, opened, and clicked. Use it to see trends over time, not to single out people. Follow up with a short all-staff tip sheet.

## Run It as a Service

So it starts on its own after a reboot:

```
sudo nano /etc/systemd/system/gophish.service
```

```
[Unit]
Description=Gophish
After=network.target

[Service]
WorkingDirectory=/opt/gophish
ExecStart=/opt/gophish/gophish
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```
sudo systemctl daemon-reload
sudo systemctl enable --now gophish
```

Since it's no longer printing to your screen, set your admin password before you switch to the service.

## Lock It Down

- Keep the admin page (port 3333) reachable from **IT only**.
- Use a long, unique admin password.
- Delete the campaign data when you no longer need it.
- Back up `gophish.db` in the Gophish folder if you want to keep your history.
