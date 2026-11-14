#!/usr/bin/env bash
# Run static checks from any session, live checks only from a Hyprland terminal.
set -euo pipefail
config="${XDG_CONFIG_HOME:-$HOME/.config}"
Hyprland --verify-config -c "$config/hypr/hyprland.lua"
foot --check-config -c "$config/foot/foot.ini"
bash -n "$config/hypr/session-start.sh"
command -v swaybg
pacman -Q swaybg
[[ -r "$HOME/Pictures/Wallpaper/macos-sonoma-6016x6016-11577.jpeg" ]]
if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    echo 'Static checks passed. Live checks pending: run this again inside Hyprland.'
    exit 0
fi
printf '\nConfig errors (expected empty):\n'
hyprctl configerrors
printf '\nMonitor (expected eDP-1 1920x1200 ~144 Hz, scale 1):\n'
hyprctl monitors
printf '\nRenderer (expected Intel/Mesa, inspect the OpenGL renderer):\n'
hyprctl systeminfo
log="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log"
if [[ -r "$log" ]]; then
    printf '\nRenderer evidence from compositor startup:\n'
    rg 'Renderer:|becomes primary drm' "$log" || true
fi
printf '\nBackground and motion blur values:\n'
hyprctl getoption decoration:blur:enabled
hyprctl getoption decoration:motion_blur:enabled
printf '\nAuthentication agent and wallpaper:\n'
pgrep -a -u "$UID" -f '^(/usr/lib/polkit-kde-authentication-agent-1|swaybg)( |$)'
printf '\nPortals (expected active):\n'
systemctl --user is-active xdg-desktop-portal.service xdg-desktop-portal-hyprland.service
printf '\nFinish the visual tests in hypr/stage1/README.md; these cannot be inferred from config checks.\n'
