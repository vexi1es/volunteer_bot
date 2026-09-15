#!/usr/bin/env bash
# School 21 Volunteer Bot — installer (run once, as root).
#
#   sudo bash install.sh              # default instance  -> /opt/volunteer-bot,        service volunteer-bot
#   sudo bash install.sh osnova       # named instance    -> /opt/volunteer-bot-osnova, service volunteer-bot-osnova
#
# A named instance is a fully separate bot (own token, own database, own
# volunteer group) running the same binary. Use it for a second program,
# e.g. the main course "Osnova" next to the intensive. Both instances update
# themselves from the same GitHub releases.
set -euo pipefail

REPO="vexi1es/volunteer_bot"
INSTANCE="${1:-}"
USER="volbot"
if [ -n "$INSTANCE" ]; then
    case "$INSTANCE" in *[!a-z0-9-]*) echo "Instance name: lowercase letters, digits, dashes"; exit 1;; esac
    HOME_DIR="/opt/volunteer-bot-$INSTANCE"
    SERVICE="volunteer-bot-$INSTANCE"
    DESC="School 21 Volunteer Bot ($INSTANCE)"
else
    HOME_DIR="/opt/volunteer-bot"
    SERVICE="volunteer-bot"
    DESC="School 21 Volunteer Bot"
fi
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ "$(id -u)" -eq 0 ] || { echo "Run as root:  sudo bash install.sh${INSTANCE:+ $INSTANCE}"; exit 1; }

command -v curl >/dev/null || { apt-get update && apt-get install -y curl; }

id "$USER" >/dev/null 2>&1 || useradd --system --home "$HOME_DIR" --shell /usr/sbin/nologin "$USER"
mkdir -p "$HOME_DIR/data"

curl -fL "https://github.com/$REPO/releases/latest/download/volunteer-bot" \
     -o "$HOME_DIR/volunteer-bot"
chmod +x "$HOME_DIR/volunteer-bot"

install -m 0755 "$SCRIPT_DIR/run.sh" "$HOME_DIR/run.sh"
# unit file is a template for the default paths — rewrite them for this instance
sed -e "s#/opt/volunteer-bot#$HOME_DIR#g" \
    -e "s#^Description=.*#Description=$DESC#" \
    "$SCRIPT_DIR/volunteer-bot.service" > "/etc/systemd/system/$SERVICE.service"
chmod 0644 "/etc/systemd/system/$SERVICE.service"

if [ ! -f "$HOME_DIR/.env" ]; then
    if [ -n "$INSTANCE" ]; then
        CONT="1"
        LIMIT="6"
    else
        CONT="0"
        LIMIT="5"
    fi
    cat > "$HOME_DIR/.env" <<ENV
BOT_TOKEN=
ADMIN_LOG_CHAT_ID=
TOPIC_LOGS=5
TOPIC_PENALTIES=7
TOPIC_MESSAGES=9
TOPIC_FLOOD=
TOPIC_SYSTEM=
DB_PATH=$HOME_DIR/data/volunteer_bot.db
# 1 = continuous program ("Osnova"): open-ended period, no 2-week auto-finish,
#     "Osnova" wording instead of "intensive". 0 = intensive bot.
CONTINUOUS=$CONT
GEO_CHECKIN=1
GEO_RADIUS_M=400
CAMPUS_LAT=
CAMPUS_LON=
# daily hour limit per volunteer; 0 = no limit
MAX_DAILY_HOURS=$LIMIT
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
systemctl enable "$SERVICE" >/dev/null 2>&1 || true

echo
if [ "$NEEDS_ENV" -eq 1 ]; then
    echo "Almost done. Fill in the config, then start:"
    echo "   sudo nano $HOME_DIR/.env"
    echo "   sudo systemctl start $SERVICE"
else
    systemctl restart "$SERVICE"
    echo "Done. The bot is running and enabled on boot."
fi
echo
echo "Logs:    journalctl -u $SERVICE -f"
echo "Status:  systemctl status $SERVICE"
