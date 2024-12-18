local wezterm = require('wezterm');
local act = wezterm.action;

local keys = {
   { key = "T", mods = "CMD", action = act.SpawnTab 'CurrentPaneDomain' },
   { key = "Enter", mods = "CTRL", action = act.SplitPane {
       direction = 'Right',
     },
   },
   { key = "Enter", mods = "CTRL|SHIFT", action = act.SplitPane {
       direction = 'Down',
     },
   },
   { key = "{", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection('Prev') },
   { key = "}", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection('Next') },
   { key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection('Left') },
   { key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection('Down') },
   { key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection('Up') },
   { key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection('Right') },
};

return {
  keys = keys,
  send_composed_key_when_left_alt_is_pressed = false,
  send_composed_key_when_right_alt_is_pressed = false,
};
