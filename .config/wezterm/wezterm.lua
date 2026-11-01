local wezterm = require('wezterm')

-- Load background images and pick a random one. Must run in wezterm.lua on the
-- initial load: wezterm.glob() spawns a child process and errors if invoked
-- from a required module during startup.
require('utils.backdrops'):set_images():random()

-- config_builder in strict mode: a misspelled option is an error in the debug
-- overlay (F12) instead of a silently ignored key.
local config = wezterm.config_builder()
config:set_strict_mode(true)

for _, name in ipairs({ 'appearance', 'bindings', 'general', 'launch' }) do
  for k, v in pairs(require('config.' .. name)) do
    if config[k] ~= nil then
      wezterm.log_warn(string.format("config.%s sets '%s' twice", name, k))
    end
    config[k] = v
  end
end

return config
