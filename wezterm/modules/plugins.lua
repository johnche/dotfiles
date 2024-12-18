local wezterm = require('wezterm');

local plugins = {};
table.insert(plugins, "https://github.com/adriankarlen/bar.wezterm");

local config = {};
for _, url in ipairs(plugins) do
  local plug = wezterm.plugin.require(url);
  plug.apply_to_config(config);
end

-- --local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm");
-- local bar = wezterm.plugin.require("ssh://git@github.com:adriankarlen/bar.wezterm");
-- bar.apply_to_config(plugins);

wezterm.log_warn(plugins)

return config;
