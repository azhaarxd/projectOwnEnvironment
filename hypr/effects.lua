-- Native springs; tune only after the first full hardware session test.
hl.config({
    animations = { enabled = true },
    decoration = {
        blur = {
            enabled = true,
            size = 10,
            passes = 3,
            noise = 0.012,
            contrast = 1.06,
            brightness = 1.04,
            vibrancy = 0.18,
        },
        -- Enabled at user request; visual/performance acceptance is still pending.
        motion_blur = { enabled = true, samples = 8 },
    },
})
hl.layer_rule({
    name = "ukishima-dock-blur",
    match = { namespace = "^ukishima-dock$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.22,
})
hl.curve("stage1Spring", { type = "spring", mass = 1, stiffness = 240, damping = 22 })
hl.curve("stage1Fade", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "stage1Fade" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "stage1Spring", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, spring = "stage1Spring", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "stage1Fade" })
