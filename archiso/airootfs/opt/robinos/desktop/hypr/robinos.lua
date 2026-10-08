-- RobinOS Hyprland defaults (Hyprland 0.56+ Lua config).
--
-- Installed to /usr/share/robinos/hypr/robinos.lua and loaded by
-- /etc/xdg/hypr/hyprland.lua. To customize, create ~/.config/hypr/hyprland.lua
-- that requires this file first and then overrides what you want:
--
--   require("/usr/share/robinos/hypr/robinos")
--   hl.config({ general = { gaps_out = 16 } })

local hypr_dir  = "/usr/share/robinos/hypr"
local bin_dir   = "/usr/share/robinos/bin"

local terminal    = "foot"
local fileManager = "nautilus"
local browser     = "firefox"

-- robinos-session sets ROBINOS_RENDER=software when there is no GPU acceleration
-- (most VMs). Blur and shadows are then turned off to keep the desktop responsive.
local software = os.getenv("ROBINOS_RENDER") == "software"

-- Handles the shell changes at runtime through `hyprctl eval`.
robinos = robinos or {}


------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Virtual machine screens (VMware, QEMU) report no physical size, so "auto"
-- guesses 2x and a 1280x800 VM window becomes a 640x400 desktop.
-- robinos-vm-display then keeps them the size of the VM window.
for i = 1, 8 do
    hl.monitor({
        output   = "Virtual-" .. i,
        mode     = "preferred",
        position = "auto",
        scale    = 1,
    })
end


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- Qt apps (Wireshark, qt6ct, the installer, ...) draw their own Adwaita-style
-- title bar, like GTK apps and Firefox already do. Hyprland answers every
-- xdg-decoration request with "server side" but draws no title bar, so Qt must
-- not see that protocol. The buttons follow button-layout in desktop/dconf.
hl.env("QT_WAYLAND_DECORATION", "adwaita")
hl.env("QT_WAYLAND_DISABLED_INTERFACES", "zxdg_decoration_manager_v1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Korean input: fcitx5 talks to Hyprland through input-method-v2 / text-input-v3.
-- GTK_IM_MODULE is intentionally left unset on Wayland.
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULES", "wayland;fcitx")


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Keeps the shell running and falls back to software drawing when Qt can't use the GPU
    hl.exec_cmd(bin_dir .. "/robinos-shell")
    hl.exec_cmd(bin_dir .. "/robinos-vm-display")
    hl.exec_cmd("fcitx5 -d --replace")
    hl.exec_cmd("hypridle -c " .. hypr_dir .. "/hypridle.conf")
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd("xdg-user-dirs-update")
    -- Clipboard history for Win+V (desktop/shell/Launcher.qml). It lives in
    -- $XDG_RUNTIME_DIR, so it is gone after logging out; cliphist skips copies that
    -- password managers mark sensitive (CLIPBOARD_STATE).
    for _, kind in ipairs({ "text", "image" }) do
        hl.exec_cmd("sh -c 'exec wl-paste --type " .. kind .. " --watch cliphist"
            .. " -db-path \"$XDG_RUNTIME_DIR/robinos-cliphist.db\" -max-items 50 store'")
    end
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Colors follow the RobinOS zinc tokens (desktop/shell/Theme.qml).
-- The shell rewrites the border colors at runtime when the light theme is picked.
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 10,

        border_size = 1,

        col = {
            active_border   = "rgba(ffffff38)",
            inactive_border = "rgba(ffffff14)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 28,
            render_power = 3,
            color        = 0x66000000,
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 3,
            vibrancy = 0.17,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = 0xff09090b,
        focus_on_activate        = true,
        -- robinos-session starts Hyprland directly so it can fall back to software rendering.
        disable_watchdog_warning = true,
    },

    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },

    cursor = {
        hide_on_key_press = true,
    },
})

-- Short, ease-out motion in the spirit of shadcn/ui: quick in, quicker out.
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},    {1, 1}    } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1}  } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 8,    bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 4,    bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.2,  spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 3.6,  spring = "easy",         style = "popin 92%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.4,  bezier = "linear",       style = "popin 92%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.7,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.4,  bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,    bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.8,  bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.4,  bezier = "easeOutQuint", style = "slidefade 12%" })

if software then
    hl.config({
        decoration = {
            blur   = { enabled = false },
            shadow = { enabled = false },
        },
        cursor = {
            no_hardware_cursors = true,
        },
    })
end


---------------
---- INPUT ----
---------------

-- Right Alt toggles 한/영 and Right Ctrl is 한자, like a Korean keyboard.
hl.config({
    input = {
        kb_layout  = "us",
        kb_options = "korean:ralt_hangul,korean:rctrl_hanja",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Shell (Quickshell global shortcuts registered by desktop/shell)
hl.bind(mainMod .. " + space", hl.dsp.global("robinos:launcher"),      { description = "앱 런처" })
hl.bind(mainMod .. " + A",     hl.dsp.global("robinos:launcher"),      { description = "앱 런처" })
hl.bind(mainMod .. " + S",     hl.dsp.global("robinos:quicksettings"), { description = "빠른 설정" })
hl.bind(mainMod .. " + N",     hl.dsp.global("robinos:notifications"), { description = "알림 모두 지우기" })
hl.bind(mainMod .. " + D",     hl.dsp.global("robinos:desktop"),       { description = "바탕 화면 보기" })
hl.bind(mainMod .. " + V",     hl.dsp.global("robinos:clipboard"),     { description = "클립보드 기록" })
-- Apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal),    { description = "터미널" })
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager), { description = "파일" })
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(browser),     { description = "브라우저" })
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("loginctl lock-session"), { description = "화면 잠금" })
hl.bind("Print",                hl.dsp.exec_cmd(bin_dir .. "/robinos-screenshot region"), { description = "영역 스크린샷" })
hl.bind("SHIFT + Print",        hl.dsp.exec_cmd(bin_dir .. "/robinos-screenshot screen"), { description = "전체 스크린샷" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(bin_dir .. "/robinos-screenshot region"), { description = "영역 스크린샷 (윈도우의 캡처 도구)" })

-- Windows (Windows-style shortcuts work too)
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "창 닫기" })
hl.bind("ALT + F4",        hl.dsp.window.close(), { description = "창 닫기" })
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "다음 창" })
hl.bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "이전 창" })
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "창 정렬/띄우기 전환" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "전체 화면" })
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }),  { description = "최대화" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exit(), { description = "로그아웃" })

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. dir,             hl.dsp.focus({ direction = dir }))
    hl.bind(mainMod .. " + SHIFT + " .. dir,     hl.dsp.window.move({ direction = dir }))
end

-- Workspaces 1-9
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,               hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,       hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Hardware keys. The shell shows its own volume indicator.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })


--------------------------------
---- WINDOWS AND LAYERS     ----
--------------------------------

-- New windows float like on Windows. The shell's "창 자동 정렬" switch disables this
-- rule (robinos.floatByDefault:set_enabled(false)) so new windows tile instead.
robinos.floatByDefault = hl.window_rule({
    name  = "robinos-float-by-default",
    match = { class = ".*" },
    float = true,
})

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Small utility windows open centered instead of tiling.
hl.window_rule({
    name  = "robinos-floating-utilities",
    match = { class = "^(org\\.pulseaudio\\.pavucontrol|nm-connection-editor|robinos-float)$" },
    float  = true,
    size   = "900 600",
    center = true,
})

-- Shell surfaces from desktop/shell. Their own QML handles enter/exit motion.
hl.layer_rule({
    name         = "robinos-shell-blur",
    match        = { namespace = "^robinos-(bar|dock)$" },
    blur         = true,
    ignore_alpha = 0.2,
})

hl.layer_rule({
    name  = "robinos-launcher-blur",
    match = { namespace = "^robinos-launcher$" },
    blur  = true,
})

hl.layer_rule({
    name    = "robinos-shell-no-anim",
    match   = { namespace = "^robinos-.*$" },
    no_anim = true,
})
