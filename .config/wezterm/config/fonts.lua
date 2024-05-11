local wezterm = require('wezterm')
local platform = require('utils.platform')

-- local font = wezterm.font('Fira Code')
-- local font_style = wezterm.font('JetBrains Mono')
local font_style = wezterm.font_with_fallback({
   {
      family = 'JetBrainsMono Nerd Font Mono',
      weight = 'Medium',
      style = 'Normal',
      scale = 0.9,
   },
   { family = 'JetBrainsMono NFM' }, -- v3.1.0 only
})

local font_rules = {
   {
      intensity = 'Bold',
      italic = false,
      font = wezterm.font_with_fallback({
         { family = 'JetBrainsMono NFM', weight = 'Bold' },
      }),
   },
}
-- local font = 'Iosevka'
local font_size = platform().is_mac and 11 or 9
-- print(wezterm.gui.screens())

-- This doesn't work well on a dual screen setup, and is hopefully a temporary solution to the font rendering oddities
-- shown in https://github.com/wez/wezterm/issues/4096. Ideally I'll switch to using `dpi_by_screen` at some point,
-- but for now 11pt @ 109dpi seems to be the most stable for font rendering on my 38" ultrawide LG monitor here.
wezterm.on('window-config-reloaded', function(window)
   if wezterm.gui.screens().active.name == 'LG ULTRAGEAR+' then
      window:set_config_overrides({
         max_fps = 200,
         effective_dpi = 100,
         dpi = 100,
         font_size = font_size,
      })
   end
end)

-- font_style = fonts.font_style,
-- max_fps = 200,
-- animation_fps = 1,
return {

   font = font_style,
   font_size = font_size,
   font_rules = font_rules,
   max_fps = 200,
   dpi_by_screen = {
      ['Built-in Retina Display'] = 144, -- You can omit this if you don't need to change it
      ['LG ULTRAGEAR+'] = 100,
   },

   -- --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
   freetype_load_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
   freetype_render_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}
