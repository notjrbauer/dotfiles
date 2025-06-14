local wezterm = require('wezterm')
local platform = require('utils.platform')

-- Toggle between PragmataPro and JetBrainsMono
local use_pragmata = false

-- Base config
local config = {
  font_size = platform.is_mac and 12 or 9,
  -- freetype_load_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
  -- freetype_render_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
  -- harfbuzz_features = { 'liga=1', 'clig=1', 'calt=1' },
}

-- Font-specific settings
if use_pragmata then
  config.font = wezterm.font({ family = 'PragmataPro Mono Liga', weight = 'Regular' })
  config.line_height = 1.17
else
  config.font = wezterm.font('JetBrains Mono Semibold')
  -- config.font = wezterm.font({
  --   family = 'JetBrains Mono',
  --   weight = 'DemiBold',
  -- })
  -- config.font = wezterm.font({
  --   family = 'JetBrains Mono',
  --   -- family = 'JetBrainsMono Nerd Font Mono',
  --   -- weight = 'Bold',
  -- })
end

return config
