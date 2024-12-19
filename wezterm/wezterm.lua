local config = require('modules'):init()
   :append('modules.general')
   :append('modules.appearance')
   :append('modules.keybindings')
   :append('modules.plugins')

return config.options
