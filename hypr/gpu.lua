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
