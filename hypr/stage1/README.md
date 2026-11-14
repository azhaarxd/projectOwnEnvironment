# Stage 1 handoff and recovery

The configuration is implemented for installed Hyprland 0.57.2. Hardware login
and live configuration checks passed. Visual effects and return-to-KDE acceptance
are **pending**. Do not describe
Stage 1 as passed until those tests are recorded below.

## Recovery point (completed)

Backup: `/home/azhaar/.local/state/hypr-stage1/20261115-015834/config.tar.gz` (includes `.git`).
All 792 entries were read successfully. Full packages and original display report
are beside the archive. Starting commit: `0d38940ab5996ef483ad1aa7857d8837a5c1a9e4`.

```bash
cd /home/azhaar/.local/state/hypr-stage1/20261115-015834
sha256sum -c config.tar.gz.sha256
```

Expected: `config.tar.gz: OK`. If it fails, stop before switching sessions.
Baseline commit: `e518fca chore: record Stage 1 recovery baseline`.
GPU commit: `3491afd feat: prepare Hyprland hybrid graphics session`.
The allowlist was extended only for the explicit Stage 1 paths; the pre-existing
quickshell allowlist was retained. No unrelated app settings were added.

## Install and validate (no logout)

```bash
sudo pacman -S --needed swaybg
bash ~/.config/hypr/stage1/check.sh
```

Expected: Hyprland `config ok`, Foot exit 0, swaybg path and package version.
The config-only Hyprland checker may print a socket-2 binding diagnostic: it
cannot provide live compositor IPC in this mode. `config ok` is the parser result.
If config errors appear, stay in KDE, correct the reported file, and rerun.
If installation fails, stay in KDE; inspect the pacman error before proceeding.
Do not perform a partial system upgrade or alter drivers to fix a missing package.

## First login (manual; interrupts desktop access)

**Save work before logging out.** Logging out closes applications and may end
this assistant connection. Use KDE's logout UI yourself, select the installed
**Hyprland** session once at the greeter, and log in. No greeter configuration or
default session was edited. If the greeter remembers your selection, select
Plasma (Wayland) on the recovery login to restore your usual choice.

Choose the normal **Hyprland** entry, which reads `hypr/hyprland.lua`.
The UWSM entry requires `uwsm`, which is not installed; do not select it.
GPU resolution happens with `hl.env` before backend startup; on this machine
it currently produces `/dev/dri/card1:/dev/dri/card0` (Intel then NVIDIA).
PCI identity is stable; card numbers are resolved each launch. `prime-run APP`
is available for applications that should render on NVIDIA. External NVIDIA
outputs are allowed by the second DRM device, but remain untested.

Expected: Sonoma wallpaper, no bar/dock/settings shell, no config error overlay.
Meta+T opens Foot; Meta+W opens Firefox; Meta+Q closes the active window;
Meta+E opens Dolphin; Meta+S toggles fullscreen; Meta+F toggles floating.
Ctrl+Meta+K/L/;' moves the active window left/up/down/right, respectively.
Super+1/2 switch workspaces; Super+Shift+1/2 move a window to the respective
workspace. Super+left/right/up/down focuses a neighbor; Super+left/right mouse
drag moves/resizes windows. US keyboard layout is preserved.
**Super+Shift+Escape logs out immediately: save work first.**

Inside Foot:

```bash
bash ~/.config/hypr/stage1/check.sh
```

Expected: empty `configerrors`, eDP-1 1920x1200 at about 144 Hz / scale 1,
Intel OpenGL renderer, live wallpaper and polkit agent, both portals active.
Check Firefox opens and a screen-share chooser uses the Hyprland portal.
Session-start failures are logged to `~/.local/state/hypr-stage1/session-start.log`.
No notification UI, bar, dock, or custom desktop shell is started.

If the wallpaper fails, inspect that log and confirm swaybg and the image exist.
If authentication or portals fail, inspect the same log and
`systemctl --user status xdg-desktop-portal{,-hyprland}.service`.
Do not accept the session until these failures are resolved.

After successful first login and the checks above, commit the base files:

```bash
cd ~/.config
git add hypr/hyprland.lua hypr/session-start.sh hypr/stage1 foot/foot.ini hypr/effects.lua
git commit -m 'feat: add minimal Hyprland desktop'
```

The prepared effects are loaded with the base files so every saved revision has
a complete configuration. Their visual acceptance is a separate gate below.

## Springs and frosted background (visual gate)

Open two Foot windows. Move one to workspace 2 using Super+Shift+2, then switch
with Super+1/2. Observe the sliding workspace bounce. Open/close a window and
move/resize a floating window (Super+F, then Super+mouse drag) to check window
spring motion. Parameters: mass 1, stiffness 240, damping 22.

Compare the same terminal over a detailed part of the wallpaper:

```bash
hyprctl eval 'hl.config({decoration={blur={enabled=false}}})'
```

Expected: wallpaper detail stays sharp through the translucent white terminal.
Restore:

```bash
hyprctl eval 'hl.config({decoration={blur={enabled=true}}})'
```

Expected: wallpaper detail softens; stationary text stays opaque and sharp.
Compositor window opacity remains 1; Foot alone supplies background alpha 0.72.
If the effect is ineffective or unreadable, leave acceptance pending and tune
`hypr/effects.lua` or `foot/foot.ini`; reload Hyprland / reopen Foot respectively.

## Motion blur (separate, temporary A/B test)

Motion blur is enabled at user request; its visual effect and performance
have not been verified. With a floating terminal, ensure it is enabled for comparison:

```bash
hyprctl eval 'hl.config({decoration={motion_blur={enabled=true,samples=8}}})'
```

Drag and resize at different speeds. Compare with:

```bash
hyprctl eval 'hl.config({decoration={motion_blur={enabled=false}}})'
```

Motion blur is currently enabled. If it causes disruptive stutter or is ineffective,
set `enabled = false` in the `motion_blur` table in `hypr/effects.lua`, then run:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
hyprctl reload
```

Record whether motion blur is retained or disabled. `hyprctl reload` restores all
saved settings after temporary A/B changes. For discomfort or stutter, disable
motion blur immediately using the command above.

## Return to KDE and final commit (manual; interrupts access)

**Save work first**, then Super+Shift+Escape logs out of Hyprland. Select
**Plasma (Wayland)** at the greeter and log in. Confirm KDE opens normally.
Record the actual observed results in `hypr/stage1/acceptance.md` (including
motion blur retained/rejected), and only after the tests have passed:

```bash
cd ~/.config
git add hypr/effects.lua foot/foot.ini hypr/stage1/acceptance.md
git commit -m 'feat: add spring animations and verified blur effects'
```

## Undo / failure recovery

If Hyprland does not open, return to the greeter and select Plasma (Wayland).
If necessary switch to a TTY with Ctrl+Alt+F3 and log in. Disable this new config
without deleting it, then log back into KDE:

```bash
mv ~/.config/hypr ~/.config/hypr.stage1-disabled-$(date +%Y%m%d-%H%M%S)
```

This does not stop a running compositor. Do not run it during a working Hyprland
session. With the config absent a future Hyprland login may generate defaults;
choose KDE for recovery.

To restore only the changed paths from the verified original snapshot, from KDE
or a TTY (this moves the Stage 1 files aside and retains unrelated app settings):

```bash
stamp=$(date +%Y%m%d-%H%M%S)
mkdir -p "$HOME/.local/state/hypr-stage1/undo-$stamp"
for name in hypr foot; do
  if [ -e "$HOME/.config/$name" ]; then
    mv "$HOME/.config/$name" "$HOME/.local/state/hypr-stage1/undo-$stamp/$name"
  fi
done
python - <<'RESTORE'
import tarfile
from pathlib import Path
archive = Path('/home/azhaar/.local/state/hypr-stage1/20261115-015834/config.tar.gz')
with tarfile.open(archive) as t:
    members = [m for m in t.getmembers() if m.name in ('.config/hypr', '.config/foot', '.config/.gitignore') or m.name.startswith(('.config/hypr/', '.config/foot/'))]
    t.extractall(Path.home(), members=members, filter='data')
RESTORE
```

Expected: original Foot/Hyprland paths (if any existed) and `.gitignore` restored;
new files preserved outside the repository. Leave swaybg installed or optionally
remove just it with `sudo pacman -R swaybg`. For Git-only rollback of the first
two commits after setting aside new files, use `git revert 3491afd e518fca` from
`~/.config`. Do not reset or overwrite the whole `.config` tree to undo Stage 1.

## Sources and attribution

This is an original, minimal configuration using the installed example and Lua
API stubs as syntax references. No third-party dotfiles or scripts were copied.
Wallpaper ownership/licensing is unchanged; the existing local asset is used.

- Installed syntax reference: `/usr/share/hypr/hyprland.lua`, `/usr/share/hypr/stubs/hl.meta.lua`.
- https://wiki.hypr.land/configuring/core/environment-variables/ (`hl.env` precedes server initialization).
- https://wiki.hypr.land/configuring/core/animations/ (native springs).
- https://wiki.hypr.land/configuring/core/config-options/#motion-blur (moving/resizing windows).
- https://wiki.hypr.land/nvidia/ (official drivers with open kernel modules).
- https://wiki.archlinux.org/title/NVIDIA could not be fetched by automated access;
  distribution instructions could not be independently checked. Installed drivers
  and kernel flags were inspected locally; no driver or bootloader changes made.
- Foot 1.28.0 local `foot.ini(5)` manual (colors-dark and background alpha).

## Complete installed file contents

The following snapshot makes the change reviewable and recoverable. Apply edits
to the actual files above; this section records their initial prepared contents.

### `hypr/gpu.lua`

```lua
-- Resolve the stable PCI identities before Aquamarine initializes.
-- hl.env runs before display-server startup (Hyprland 0.57.2).
-- Never put PCI symlink paths directly in AQ_DRM_DEVICES: ':' is its separator.
local function drm_card(pci)
    local pipe = assert(io.popen("readlink -e /dev/dri/by-path/pci-" .. pci .. "-card", "r"))
    local path = pipe:read("*l")
    pipe:close()
    assert(path and path:match("^/dev/dri/card%d+$"), "Missing DRM GPU: " .. pci)
    return path
end
local intel = drm_card("0000:00:02.0")
local nvidia = drm_card("0000:01:00.0")
hl.env("AQ_DRM_DEVICES", intel .. ":" .. nvidia)
-- No global NVIDIA offload variables: desktop applications use Intel.
-- For an individual application, use prime-run if installed.
```

### `hypr/hyprland.lua`

```lua
-- Stage 1, Hyprland 0.57.2. See stage1/README.md for tests and recovery.
local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local dir = config .. "/hypr/"
dofile(dir .. "gpu.lua")

hl.monitor({ output = "eDP-1", mode = "1920x1200@144", position = "0x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.config({
    input = { kb_layout = "us", follow_mouse = 1 },
    general = {
        layout = "dwindle", gaps_in = 6, gaps_out = 12, border_size = 2,
        col = { active_border = "rgba(ffffffff)", inactive_border = "rgba(b0b0b080)" },
    },
    dwindle = { preserve_split = true },
    decoration = {
        rounding = 12, active_opacity = 1.0, inactive_opacity = 1.0,
    },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true,
             force_default_wallpaper = 0 },
})
dofile(dir .. "effects.lua")

hl.bind("SUPER + T", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + E", hl.dsp.exec_cmd("dolphin"))
hl.bind("SUPER + S", hl.dsp.window.fullscreen())
hl.bind("SUPER + F", hl.dsp.window.float({ action = "toggle" }))
-- Logs out immediately; save your work before pressing this shortcut.
hl.bind("SUPER + SHIFT + Escape", hl.dsp.exit())
for i = 1, 2 do
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))
hl.bind("CTRL + SUPER + K", hl.dsp.window.move({ direction = "left" }))
hl.bind("CTRL + SUPER + L", hl.dsp.window.move({ direction = "up" }))
hl.bind("CTRL + SUPER + SEMICOLON", hl.dsp.window.move({ direction = "down" }))
hl.bind("CTRL + SUPER + APOSTROPHE", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.on("hyprland.start", function()
    -- Quote the path for the shell; nothing launches during --verify-config.
    local script = dir .. "session-start.sh"
    hl.exec_cmd("bash '" .. script:gsub("'", "'\\''") .. "'")
end)
```

### `hypr/effects.lua`

```lua
-- Native springs; tune only after the first full hardware session test.
hl.config({
    animations = { enabled = true },
    decoration = {
        blur = { enabled = true, size = 8, passes = 3, vibrancy = 0.0 },
        -- Enabled at user request; visual/performance acceptance is still pending.
        motion_blur = { enabled = true, samples = 8 },
    },
})
hl.curve("stage1Spring", { type = "spring", mass = 1, stiffness = 240, damping = 22 })
hl.curve("stage1Fade", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "stage1Fade" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "stage1Spring", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, spring = "stage1Spring", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "stage1Fade" })
```

### `hypr/session-start.sh`

```bash
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
```

### `foot/foot.ini`

```ini
[main]
font=monospace:size=11
pad=14x14
initial-window-size-chars=100x30

[colors-dark]
# Background alpha affects the background only; text stays fully opaque.
background=ffffff
foreground=202124
alpha=0.72
alpha-mode=default
regular0=202124
regular1=a21c25
regular2=256b31
regular3=795700
regular4=2459a6
regular5=853a96
regular6=006b73
regular7=d6d6d6
bright0=606368
bright1=c12832
bright2=287b39
bright3=8a6500
bright4=2c6ac3
bright5=9d45ae
bright6=007e87
bright7=ffffff
selection-foreground=202124
selection-background=c8dcff
```

### `hypr/stage1/check.sh`

```bash
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
```
