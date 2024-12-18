-- local wezterm = require('wezterm');
-- scheme_for_appearance(wezterm.gui.get_appearance())
function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Catppuccin Mocha"
  else
    return "Catppuccin Latte"
  end
end

return {
   color_scheme = "Solarized Light (Gogh)",

   -- cursor style
   default_cursor_style = "BlinkingBlock",
   cursor_blink_ease_in = 'Constant',
   cursor_blink_ease_out = 'Constant',
};
