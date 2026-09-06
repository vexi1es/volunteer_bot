# Volunteer Bot

A Telegram bot, shipped as a single self-contained binary for **Ubuntu Linux**.
No Python or dependencies to install. It keeps itself running and updates itself.

## Install (once)

Requires Ubuntu 22.04+ and `sudo`.

```bash
git clone https://github.com/vexi1es/volunteer_bot.git
cd volunteer_bot
sudo bash install.sh
```

Then put the values you were given into the config file and start it:

```bash
sudo nano /opt/volunteer-bot/.env      # fill in BOT_TOKEN and ADMIN_LOG_CHAT_ID
sudo systemctl start volunteer-bot
```

Done. Nothing else to do — it runs on its own from here.

## After that — nothing

- Crash, error, or server reboot → it comes back up by itself.
- New version → it downloads and installs it by itself.
- A bad update → it rolls back to the previous working version by itself.

## Commands

```bash
systemctl status volunteer-bot        # is it running
journalctl -u volunteer-bot -f        # live logs
sudo systemctl restart volunteer-bot  # restart
sudo systemctl stop volunteer-bot     # stop
```

## Uninstall

```bash
sudo systemctl disable --now volunteer-bot
sudo rm -f /etc/systemd/system/volunteer-bot.service
sudo systemctl daemon-reload
sudo rm -rf /opt/volunteer-bot
sudo userdel volbot
```

## Server requirements

- Ubuntu 22.04 / 24.04 (64-bit)
- 1 CPU, 512 MB RAM, ~500 MB disk
- Outbound internet only (no open ports, no domain, no static IP needed)
