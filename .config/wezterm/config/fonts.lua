local wezterm = require('wezterm')
local platform = require('utils.platform')

-- local font = wezterm.font('Fira Code')
local font_style = wezterm.font('JetBrains Mono')
-- local font = 'Iosevka'
local font_size = platform().is_mac and 12 or 9

return {
   font = font_style,
   font_size = font_size,

   -- --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
   freetype_load_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
   freetype_render_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}
