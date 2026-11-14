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

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

hl.bind("SUPER + T", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("qs -p ~/.local/share/quickshell/ukishima ipc call ukishima agents \"\""))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("qs -p ~/.local/share/quickshell/ukishima ipc call ukishima launcher \"\""))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))
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
local tiling_templates = { "dwindle", "master" }
local tiling_template_index = 1
hl.bind("CTRL + SUPER + RETURN", function()
    tiling_template_index = tiling_template_index % #tiling_templates + 1
    hl.config({ general = { layout = tiling_templates[tiling_template_index] } })
end)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.on("hyprland.start", function()
    -- Quote the path for the shell; nothing launches during --verify-config.
    local script = dir .. "session-start.sh"
    hl.exec_cmd("bash '" .. script:gsub("'", "'\\''") .. "'")
end)
