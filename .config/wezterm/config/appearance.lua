local backdrops = require('utils.backdrops')
local colors = require('colors.custom')
local fonts = require('config.fonts')

return {
  -- Rendering. WebGpu is a real choice (the default reverted to OpenGL in
  -- 20240128). No adapter pinning: the old pick_best() forced the discrete
  -- Radeon on for a terminal, and webgpu_preferred_adapter overrides
  -- webgpu_power_preference anyway, so one of the two was always dead.
  -- LowPower is the default and what a laptop wants. The panel is 60 Hz;
  -- animation_fps only drives cursor-blink and bell easing.
  front_end = 'WebGpu',
  max_fps = 60,
  animation_fps = 60,

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
  background = backdrops:initial_options(),

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

  -- Tabs: tmux owns tabs and windows; the bar is off, so no bar styling.
  enable_tab_bar = false,
  switch_to_last_active_tab_when_closing_tab = true,

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
