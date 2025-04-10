local wezterm = require('wezterm')
local platform = require('utils.platform')

-- Toggle between PragmataPro and JetBrainsMono
local use_pragmata = true

-- Base config
local config = {
  font_size = platform.is_mac and 16 or 14,
  freetype_load_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
  freetype_render_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
  harfbuzz_features = { 'liga=1', 'clig=1', 'calt=1' },
}

-- Font-specific settings
if use_pragmata then
  config.font = wezterm.font({ family = 'PragmataPro Mono Liga', weight = 'Regular' })
  config.line_height = 1.17
else
  config.font = wezterm.font({
    family = 'JetBrainsMono Nerd Font Mono',
    weight = 'Regular',
  })
end

return config
