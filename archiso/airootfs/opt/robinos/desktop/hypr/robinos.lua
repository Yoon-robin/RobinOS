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

-- The display scale picked in quick settings ("화면 배율", ShellState.setScale),
-- one "output scale" line per screen
local state_dir = os.getenv("XDG_STATE_HOME") or ((os.getenv("HOME") or "") .. "/.local/state")
local scales = io.open(state_dir .. "/robinos/display-scale")
if scales then
    for line in scales:lines() do
        local output, scale = line:match("^([%w-]+)%s+([%d.]+)$")
        if output and tonumber(scale) then
            hl.monitor({
                output   = output,
                mode     = "preferred",
                position = "auto",
                scale    = tonumber(scale),
            })
        end
    end
    scales:close()
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
hl.bind(mainMod .. " + I",     hl.dsp.global("robinos:quicksettings"), { description = "빠른 설정 (윈도우의 설정 Win+I)" })
hl.bind(mainMod .. " + R",     hl.dsp.global("robinos:launcher"),      { description = "앱 런처 (윈도우의 실행 Win+R)" })
hl.bind(mainMod .. " + N",     hl.dsp.global("robinos:notifications"), { description = "알림 센터" })
hl.bind(mainMod .. " + D",     hl.dsp.global("robinos:desktop"),       { description = "바탕 화면 보기" })
hl.bind(mainMod .. " + Tab",   hl.dsp.global("robinos:taskview"),      { description = "작업 보기 (윈도우의 Win+Tab)" })
hl.bind(mainMod .. " + X",     hl.dsp.global("robinos:quicklinks"),    { description = "빠른 메뉴 (윈도우의 Win+X)" })
hl.bind(mainMod .. " + V",     hl.dsp.global("robinos:clipboard"),     { description = "클립보드 기록" })
hl.bind(mainMod .. " + period",    hl.dsp.global("robinos:emoji"),     { description = "이모지 (윈도우의 Win+.)" })
hl.bind(mainMod .. " + semicolon", hl.dsp.global("robinos:emoji"),     { description = "이모지 (윈도우의 Win+;)" })
hl.bind(mainMod .. " + ALT + D", hl.dsp.global("robinos:calendar"),   { description = "달력" })
hl.bind(mainMod .. " + F1",    hl.dsp.global("robinos:shortcuts"),     { description = "단축키 보기" })
-- Apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal),    { description = "터미널" })
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager), { description = "파일" })
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(browser),     { description = "브라우저" })
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("loginctl lock-session"), { description = "화면 잠금" })
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("missioncenter"), { description = "작업 관리자 (Mission Center)" })
hl.bind("Print",                hl.dsp.exec_cmd(bin_dir .. "/robinos-screenshot region"), { description = "영역 스크린샷" })
hl.bind("SHIFT + Print",        hl.dsp.exec_cmd(bin_dir .. "/robinos-screenshot screen"), { description = "전체 스크린샷" })
hl.bind(mainMod .. " + Print",  hl.dsp.exec_cmd(bin_dir .. "/robinos-screenshot screen"), { description = "전체 스크린샷 (윈도우의 Win+PrtSc)" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(bin_dir .. "/robinos-screenshot region"), { description = "영역 스크린샷 (윈도우의 캡처 도구)" })

-- Windows (Windows-style shortcuts work too)
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "창 닫기" })
hl.bind("ALT + F4", function()
    if hl.get_active_window() then
        hl.dispatch(hl.dsp.window.close())
    else
        -- Like Windows on the desktop: the shutdown choices (the quick settings' power menu)
        hl.dispatch(hl.dsp.global("robinos:power"))
    end
end, { description = "창 닫기 (창이 없으면 전원 메뉴)" })
-- Alt+Tab like Windows: the shell shows the windows while Alt is held (AltTab.qml)
-- and switches when Alt is let go. A release bind on Alt_L never fires once Alt+Tab
-- has taken the key (boot test, 2026-10-09), so a short timer watches Alt instead
-- and sends robinos:alttab-done when it comes up.
local alttab_watch = nil

local function alttab(signal)
    hl.dispatch(hl.dsp.global("robinos:" .. signal))
    if alttab_watch then
        return
    end
    alttab_watch = hl.timer(function()
        if hl.is_key_down("Alt_L") or hl.is_key_down("Alt_R") then
            return
        end
        alttab_watch:set_enabled(false)
        alttab_watch = nil
        hl.dispatch(hl.dsp.global("robinos:alttab-done"))
    end, { timeout = 50, type = "repeat" })
end

hl.bind("ALT + Tab",         function() alttab("alttab") end,      { description = "창 전환 (Alt를 누른 채 Tab으로 고르고, 놓으면 바뀌어요)" })
hl.bind("ALT + SHIFT + Tab", function() alttab("alttab-back") end, { description = "창 전환, 거꾸로" })
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "창 정렬/띄우기 전환" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "전체 화면" })
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }),  { description = "최대화" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exit(), { description = "로그아웃" })

-- Windows' snap: Win+Left/Right put the window on half of the screen, Win+Up
-- maximizes, Win+Down restores and then minimizes. Tiled windows (창 자동 정렬)
-- swap places instead. snapped keeps where a window was, for Win+Down.
local snapped = {}
local snap_gap = 10  -- general.gaps_out

-- The free part of a monitor (without the bar and the dock), in layout coordinates
local function work_area(m)
    local w, h = m.width / m.scale, m.height / m.scale
    if m.transform % 2 == 1 then
        w, h = h, w
    end
    local r = m.reserved
    return m.x + r.left + snap_gap, m.y + r.top + snap_gap,
        w - r.left - r.right - 2 * snap_gap, h - r.top - r.bottom - 2 * snap_gap
end

local function snap(side)
    local w = hl.get_active_window()
    if not w or not w.monitor then
        return
    end
    if not w.floating then
        hl.dispatch(hl.dsp.window.move({ direction = side }))
        return
    end
    -- A maximized window can't move; it comes back to its own size first
    if w.fullscreen ~= 0 then
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
    end
    if not snapped[w.address] then
        snapped[w.address] = { x = w.at.x, y = w.at.y, w = w.size.x, h = w.size.y }
    end
    local x, y, aw, ah = work_area(w.monitor)
    local half = math.floor((aw - snap_gap) / 2)
    hl.dispatch(hl.dsp.window.resize({ x = half, y = math.floor(ah) }))
    hl.dispatch(hl.dsp.window.move({ x = math.floor(side == "left" and x or x + aw - half), y = math.floor(y) }))
end

local function snap_down()
    local w = hl.get_active_window()
    if not w then
        return
    end
    if w.fullscreen ~= 0 then
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
        return
    end
    local old = snapped[w.address]
    if old and w.floating then
        snapped[w.address] = nil
        hl.dispatch(hl.dsp.window.resize({ x = old.w, y = old.h }))
        hl.dispatch(hl.dsp.window.move({ x = old.x, y = old.y }))
        return
    end
    -- Minimized by the shell, so the dock can bring it back
    hl.dispatch(hl.dsp.global("robinos:minimize"))
end

hl.bind(mainMod .. " + left",  function() snap("left") end,  { description = "창을 화면 왼쪽 절반에" })
hl.bind(mainMod .. " + right", function() snap("right") end, { description = "창을 화면 오른쪽 절반에" })
hl.bind(mainMod .. " + up",    hl.dsp.window.fullscreen({ mode = "maximized", action = "set" }), { description = "최대화" })
hl.bind(mainMod .. " + down",  snap_down, { description = "원래 크기로, 다시 누르면 최소화" })
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + SHIFT + " .. dir,     hl.dsp.window.move({ direction = dir }))
end
-- Win+Ctrl+Left/Right like Windows' virtual desktops
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ workspace = "r-1" }), { description = "이전 작업 공간" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }), { description = "다음 작업 공간" })
-- Windows' Win+Ctrl+D and Win+Ctrl+F4 for virtual desktops (ShellState.newWorkspace)
hl.bind(mainMod .. " + CTRL + D",  hl.dsp.global("robinos:newworkspace"),   { description = "새 작업 공간 (윈도우의 Win+Ctrl+D)" })
hl.bind(mainMod .. " + CTRL + F4", hl.dsp.global("robinos:closeworkspace"), { description = "작업 공간 닫기, 창은 왼쪽 작업 공간으로 (윈도우의 Win+Ctrl+F4)" })

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
