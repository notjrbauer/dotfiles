local gpu_adapters = require('utils.gpu')
local backdrops = require('utils.backdrops')
local colors = require('colors.custom')
local fonts = require('config.fonts')

return {
  -- Performance
  max_fps = 120,
  animation_fps = 120,
  front_end = 'WebGpu',
  webgpu_power_preference = 'HighPerformance',
  webgpu_preferred_adapter = gpu_adapters:pick_best(),
  -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Dx12', 'IntegratedGpu'),
  -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Gl', 'Other'),

  -- Cursor
  default_cursor_style = 'BlinkingBlock',
  cursor_blink_rate = 650,
  cursor_blink_ease_in = 'EaseOut',
  cursor_blink_ease_out = 'EaseOut',
  force_reverse_video_cursor = true,

  -- Styling
  bold_brightens_ansi_colors = true,
  underline_thickness = '1.5pt',
  colors = colors,
  font = fonts.font,
  font_size = fonts.font_size,

  -- Background
  background = backdrops:initial_options(false), -- set to true for focus mode

  -- Window
  window_padding = {
    left = 0,
    right = 0,
    top = 10,
    bottom = 7.5,
  },
  initial_rows = 35,
  initial_cols = 100,
  -- window_decorations = 'MACOS_FORCE_SQUARE_CORNERS|RESIZE',
  window_decorations = 'RESIZE',
  window_close_confirmation = 'NeverPrompt',
  adjust_window_size_when_changing_font_size = false,
  window_frame = {
    -- active_titlebar_bg = '#090909',
    -- font = fonts.font,
    -- font_size = fonts.font_size,
  },

  -- Tabs
  enable_tab_bar = false,
  hide_tab_bar_if_only_one_tab = false,
  use_fancy_tab_bar = false,
  tab_max_width = 25,
  show_tab_index_in_tab_bar = false,
  switch_to_last_active_tab_when_closing_tab = true,

  -- Scrollbar
  enable_scroll_bar = false,

  -- Inactive pane styling
  inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.65,
  },

  -- Visual bell
  visual_bell = {
    fade_in_function = 'EaseIn',
    fade_in_duration_ms = 250,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 250,
    target = 'CursorColor',
  },
}
