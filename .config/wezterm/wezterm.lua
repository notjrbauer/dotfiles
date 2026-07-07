local Config = require('config')

-- Load background images and pick a random one. Must run in wezterm.lua on the
-- initial load: wezterm.glob() spawns a child process and errors if invoked
-- from a required module during startup.
require('utils.backdrops')
  -- :set_focus('#000000')
  -- :set_images_dir(require('wezterm').home_dir .. '/Pictures/Wallpapers/')
  :set_images()
  :random()

return Config:init()
  :append(require('config.appearance'))
  :append(require('config.bindings'))
  :append(require('config.general'))
  :append(require('config.launch')).options
