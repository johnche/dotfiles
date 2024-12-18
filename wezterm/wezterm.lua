-- local wezterm = require "wezterm";
-- local act = wezterm.action;
-- local config = {};
-- 
-- function scheme_for_appearance(appearance)
--   return "Solarized Light (Gogh)"
--   -- if appearance:find "Dark" then
--   --   return "Catppuccin Mocha"
--   -- else
--   --   return "Catppuccin Latte"
--   -- end
-- end
-- 
-- config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
-- 
local config = require('modules'):init()
   :append(require('modules.general'))
   :append(require('modules.appearance'))
   :append(require('modules.keybindings'))
   :append(require('modules.plugins'))

return config.options
