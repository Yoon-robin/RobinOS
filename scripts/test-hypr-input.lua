-- Loads desktop/hypr/robinos.lua with a stand-in for Hyprland's `hl` and checks the pointer
-- and keyboard settings it takes from ~/.local/state/robinos/input (Settings.qml writes it).
--
--   XDG_STATE_HOME=<empty dir> lua scripts/test-hypr-input.lua desktop/hypr/robinos.lua
--
-- scripts/check-desktop.sh runs it with a fresh directory.

local config_path = arg[1]
local state_dir = os.getenv("XDG_STATE_HOME")
assert(config_path and state_dir, "usage: XDG_STATE_HOME=<dir> lua test-hypr-input.lua robinos.lua")

local failed = false

local function check(name, ok)
    print((ok and "  ok      " or "  FAILED  ") .. name)
    if not ok then
        failed = true
    end
end

-- Any hl.something(...) does nothing and returns the same stand-in, except hl.config
local function stub()
    local s
    s = setmetatable({}, { __index = function() return s end, __call = function() return s end })
    return s
end

local function load_config(file_text)
    os.execute("mkdir -p '" .. state_dir .. "/robinos' && rm -f '" .. state_dir .. "/robinos/input'")
    if file_text then
        local f = assert(io.open(state_dir .. "/robinos/input", "w"))
        f:write(file_text)
        f:close()
    end
    local input
    hl = stub()
    hl.config = function(t)
        if t.input and t.input.touchpad then
            input = t.input
        end
    end
    robinos = nil
    dofile(config_path)
    return input
end

local function same(input, want)
    return input ~= nil
        and input.sensitivity == want.speed
        and input.natural_scroll == want.wheel_flip
        and input.repeat_rate == want.repeat_rate
        and input.repeat_delay == want.repeat_delay
        and input.touchpad.natural_scroll == want.natural
        and input.touchpad.tap_to_click == want.tap
        and input.touchpad.disable_while_typing == want.typing_off
end

local defaults = { tap = true, natural = true, typing_off = true, wheel_flip = false, speed = 0, repeat_rate = 25, repeat_delay = 600 }

check("no file: the defaults", same(load_config(nil), defaults))

check("a saved file is used (and false stays false)", same(load_config(
    "tap false\nnatural false\ntyping_off false\nwheel_flip true\nspeed 0.4\nrepeat_rate 40\nrepeat_delay 300\n"),
    { tap = false, natural = false, typing_off = false, wheel_flip = true, speed = 0.4, repeat_rate = 40, repeat_delay = 300 }))

check("values out of range or odd keep the defaults", same(load_config(
    "speed 7\ntap maybe\nrepeat_rate 5\nrepeat_delay abc\nbogus 1\nnatural\n"), defaults))

check("a negative speed", same(load_config("speed -0.35\n"),
    { tap = true, natural = true, typing_off = true, wheel_flip = false, speed = -0.35, repeat_rate = 25, repeat_delay = 600 }))

-- What the shell sends at runtime
load_config(nil)
local at_runtime
hl.config = function(t)
    at_runtime = t.input
end
robinos.applyInput({ tap = false, speed = 0.5 })
check("a change at runtime: the rest stays default", same(at_runtime,
    { tap = false, natural = true, typing_off = true, wheel_flip = false, speed = 0.5, repeat_rate = 25, repeat_delay = 600 }))
robinos.applyInput({ tap = "no", speed = 2, repeat_rate = 61 })
check("a runtime value of the wrong kind or range is ignored", same(at_runtime, defaults))

os.exit(failed and 1 or 0)
