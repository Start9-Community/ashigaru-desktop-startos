#!/usr/bin/env bash

set -eu

# Selkies only copies /defaults/autostart when the user file is absent.
# Replace this package-owned hook on every launch so existing volumes receive
# startup fixes without disturbing the rest of /config.
autostart=/config/.config/openbox/autostart
mkdir -p "$(dirname "$autostart")"
cp /defaults/autostart "$autostart"
chmod 755 "$autostart"

exec dbus-launch --exit-with-session /usr/bin/openbox-session
