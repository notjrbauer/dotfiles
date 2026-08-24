local wezterm = require('wezterm')
local colors = require('colors.custom')

-- Random backdrop from ./backdrops, washed with the theme background. Only the
-- startup path exists: wezterm.lua calls set_images():random() (glob must run
-- there — wezterm.glob spawns a child process and errors from a required
-- module during the initial load), and appearance.lua reads initial_options().
-- The cycle/focus/picker methods that used to live here had no caller.

local GLOB_PATTERN = '*.{jpg,jpeg,png,gif,bmp,ico,tiff,pnm,dds,tga}'

---@class BackDrops
---@field current_idx number index of current image
---@field images string[] background images
---@field images_dir string directory of background images
local BackDrops = {}
BackDrops.__index = BackDrops

function BackDrops:init()
  return setmetatable({
    current_idx = 1,
    images = {},
    images_dir = wezterm.config_dir .. '/backdrops/',
  }, self)
end

---MUST run in wezterm.lua during the initial load (see above).
function BackDrops:set_images()
  self.images = wezterm.glob(self.images_dir .. GLOB_PATTERN)
  return self
end

---Pick a random image. Lua 5.4's math.random(0) raises "interval is empty",
---which would take the whole config down and leave wezterm on its defaults —
---an empty backdrops dir just means no image.
function BackDrops:random()
  if #self.images > 0 then
    self.current_idx = math.random(#self.images)
  end
  return self
end

---The `background` option: the image, then a 90%-opaque wash of the theme
---background over it. With no image, the wash alone.
function BackDrops:initial_options()
  local layers = {
    {
      source = { Color = colors.background },
      height = '120%',
      width = '120%',
      vertical_offset = '-10%',
      horizontal_offset = '-10%',
      opacity = 0.90,
    },
  }
  if #self.images > 0 then
    table.insert(layers, 1, {
      source = { File = self.images[self.current_idx] },
      horizontal_align = 'Center',
    })
  end
  return layers
end

return BackDrops:init()
