-- RobinOS system-wide Hyprland entry point (/etc/xdg/hypr/hyprland.lua).
--
-- Hyprland reads ~/.config/hypr/hyprland.lua first and only falls back to this
-- file when the user has no Lua config of their own. A ~/.config/hypr/hyprland.conf
-- is ignored while this file exists, so customize with hyprland.lua: create
-- ~/.config/hypr/hyprland.lua with the require line below and add overrides after it.

require("/usr/share/robinos/hypr/robinos")
