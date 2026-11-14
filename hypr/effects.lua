-- Native springs; tune only after the first full hardware session test.
hl.config({
    animations = { enabled = true },
    decoration = {
        shadow = { enabled = false },
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            noise = 0.0,
            contrast = 1.05,
            brightness = 1.0,
            vibrancy = 0.45,
            ignore_opacity = true,
            new_optimizations = true,
            xray = true,
            special = false,
            popups = false,
        },
        -- Disabled to eliminate 8-sample per-pixel shader overhead at 144Hz on iGPU.
        motion_blur = { enabled = false, samples = 8 },
    },
})
hl.layer_rule({
    name = "ukishima-pill-blur",
    match = { namespace = "^ukishima$" },
    blur = true,
    blur_popups = false,
    xray = true,
    ignore_alpha = 0.15,
})
hl.layer_rule({
    name = "ukishima-dock-blur",
    match = { namespace = "^ukishima-dock$" },
    blur = true,
    blur_popups = false,
    xray = true,
    ignore_alpha = 0.15,
})
hl.window_rule({
    name = "konsole-blur-opacity",
    match = { class = "^(org\\.kde\\.konsole|konsole)$" },
    opacity = "0.82 0.78",
})
hl.window_rule({
    name = "thunar-blur-opacity",
    match = { class = "^([Tt]hunar|[Oo]rg\\.xfce\\.Thunar)$" },
    opacity = "0.88 0.84",
})
hl.curve("stage1Spring", { type = "spring", mass = 1, stiffness = 240, damping = 22 })
hl.curve("stage1Fade", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "stage1Fade" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "stage1Spring", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, spring = "stage1Spring", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "stage1Fade" })
