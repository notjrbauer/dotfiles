local platform = require('utils.platform')

local options = {
  default_prog = {},
  launch_menu = {},
}

-- if platform.is_mac then
options.default_prog = { '/usr/local/opt/zsh/bin/zsh-5.9', '-l' }
-- options.launch_menu = {
--   { label = 'Zsh', args = { '/usr/local/opt/zsh/bin/zsh-5.9', '-l' } },
-- }
-- end

return options
