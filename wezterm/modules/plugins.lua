local Plugins = {};
function Plugins:init()
  self.__index = self;
  self.wezterm = require('wezterm');
  local table = setmetatable({ urls = {}, config = {} }, self);
  return table
end

function Plugins:add(url)
  table.insert(self.urls, url)
  return self
end

function Plugins:get_config()
  for _, url in ipairs(self.urls) do
    local plug = self.wezterm.plugin.require(url);
    self.wezterm.log_warn(plug)
    plug.apply_to_config(self.config);
  end

  return self.config;
end

return Plugins:init()
  --:add("https://github.com/adriankarlen/bar.wezterm")
  --:add("/Users/johnche/.local/share/wezterm/git/bar.wezterm")
  :get_config()
