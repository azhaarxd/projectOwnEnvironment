-- Native springs; tune only after the first full hardware session test.
hl.config({
    animations = { enabled = true },
    decoration = {
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            noise = 0.0,
            contrast = 1.05,
            brightness = 1.0,
            vibrancy = 0.45,
        },
        -- Enabled at user request; visual/performance acceptance is still pending.
        motion_blur = { enabled = true, samples = 8 },
    },
})
hl.layer_rule({
    name = "ukishima-pill-blur",
    match = { namespace = "^ukishima$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.15,
})
hl.layer_rule({
    name = "ukishima-dock-blur",
    match = { namespace = "^ukishima-dock$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.15,
})
hl.curve("stage1Spring", { type = "spring", mass = 1, stiffness = 240, damping = 22 })
hl.curve("stage1Fade", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "stage1Fade" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "stage1Spring", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, spring = "stage1Spring", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "stage1Fade" })
