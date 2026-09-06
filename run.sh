#!/usr/bin/env bash
set -u

HOME_DIR="${BOT_HOME:-/opt/volunteer-bot}"
BIN="$HOME_DIR/volunteer-bot"
PREV="$HOME_DIR/volunteer-bot.prev"
FAILMARK="$HOME_DIR/.fastfail"

[ -x "$BIN" ] || { echo "missing binary $BIN"; exit 1; }

start=$(date +%s)
"$BIN"
code=$?
runtime=$(( $(date +%s) - start ))

if [ "$code" -eq 42 ]; then
    rm -f "$FAILMARK"
    exit 0
fi

if [ "$runtime" -ge 120 ]; then
    rm -f "$FAILMARK"
    exit "$code"
fi

fails=$(cat "$FAILMARK" 2>/dev/null || echo 0)
fails=$(( fails + 1 ))
echo "$fails" > "$FAILMARK"

if [ "$fails" -ge 3 ] && [ -f "$PREV" ]; then
    mv -f "$BIN" "$HOME_DIR/volunteer-bot.broken" 2>/dev/null || true
    mv -f "$PREV" "$BIN"
    rm -f "$FAILMARK"
fi

exit "$code"
