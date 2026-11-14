#!/usr/bin/env bash
# Invoked only by the real Hyprland session, never by config verification.
set -euo pipefail
[[ ${XDG_CURRENT_DESKTOP:-} == *Hyprland* ]] || exit 0
: "${XDG_RUNTIME_DIR:?Missing session runtime directory}"
: "${WAYLAND_DISPLAY:?Missing Wayland display}"
state="${XDG_STATE_HOME:-$HOME/.local/state}/hypr-stage1"
mkdir -p "$state"
exec >>"$state/session-start.log" 2>&1
exec 9>"$XDG_RUNTIME_DIR/hypr-stage1-${WAYLAND_DISPLAY}.lock"
flock -n 9 || exit 0
printf '\nStage 1 startup: %s\n' "$(date --iso-8601=seconds)"
# Portals activated through D-Bus/systemd must see this compositor's session.
dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE
if ! systemctl --user restart xdg-desktop-portal-hyprland.service xdg-desktop-portal.service; then
    echo "Portal restart failed; inspect systemctl --user status xdg-desktop-portal.service"
fi
# Reuse KDE's installed agent, without starting Plasma's shell.
agent=/usr/lib/polkit-kde-authentication-agent-1
if ! pgrep -u "$UID" -f "^$agent( |$)" >/dev/null; then
    "$agent" &
fi
wallpaper="$HOME/Pictures/Wallpaper/macos-sonoma-6016x6016-11577.jpeg"
if ! command -v swaybg >/dev/null; then
    echo 'Missing swaybg: install with sudo pacman -S --needed swaybg'
    exit 1
fi
[[ -r "$wallpaper" ]] || { echo "Wallpaper not readable: $wallpaper"; exit 1; }
# Keep the lock while swaybg runs, so config reloads cannot duplicate it.
exec swaybg -i "$wallpaper" -m fill
