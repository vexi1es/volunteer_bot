#!/usr/bin/env bash
set -euo pipefail

REPO="vexi1es/volunteer_bot"
HOME_DIR="/opt/volunteer-bot"
USER="volbot"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ "$(id -u)" -eq 0 ] || { echo "Run as root:  sudo bash install.sh"; exit 1; }

command -v curl >/dev/null || { apt-get update && apt-get install -y curl; }

id "$USER" >/dev/null 2>&1 || useradd --system --home "$HOME_DIR" --shell /usr/sbin/nologin "$USER"
mkdir -p "$HOME_DIR/data"

curl -fL "https://github.com/$REPO/releases/latest/download/volunteer-bot" \
     -o "$HOME_DIR/volunteer-bot"
chmod +x "$HOME_DIR/volunteer-bot"

install -m 0755 "$SCRIPT_DIR/run.sh" "$HOME_DIR/run.sh"
install -m 0644 "$SCRIPT_DIR/volunteer-bot.service" /etc/systemd/system/volunteer-bot.service

if [ ! -f "$HOME_DIR/.env" ]; then
    cat > "$HOME_DIR/.env" <<'ENV'
BOT_TOKEN=
ADMIN_LOG_CHAT_ID=
TOPIC_LOGS=5
TOPIC_PENALTIES=7
TOPIC_MESSAGES=9
DB_PATH=/opt/volunteer-bot/data/volunteer_bot.db
GEO_CHECKIN=1
GEO_RADIUS_M=400
CAMPUS_LAT=
CAMPUS_LON=
MAX_DAILY_HOURS=5
S21_LOGIN=
S21_PASSWORD=
AI_API_KEY=
ENV
    NEEDS_ENV=1
else
    NEEDS_ENV=0
fi

chown -R "$USER:$USER" "$HOME_DIR"
chmod 600 "$HOME_DIR/.env"

systemctl daemon-reload
systemctl enable volunteer-bot >/dev/null 2>&1 || true

echo
if [ "$NEEDS_ENV" -eq 1 ]; then
    echo "Almost done. Fill in the config, then start:"
    echo "   sudo nano $HOME_DIR/.env"
    echo "   sudo systemctl start volunteer-bot"
else
    systemctl restart volunteer-bot
    echo "Done. The bot is running and enabled on boot."
fi
echo
echo "Logs:    journalctl -u volunteer-bot -f"
echo "Status:  systemctl status volunteer-bot"
