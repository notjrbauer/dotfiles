local wezterm = require('wezterm')
local colors = require('colors.custom')
local fonts = require('config.fonts')

return {
   force_reverse_video_cursor = true,
   animation_fps = 200,
   max_fps = 200,
   front_end = 'WebGpu',
   webgpu_power_preference = 'HighPerformance',
   freetype_load_target = fonts.freetype_load_target,
   freetype_render_target = fonts.freetype_render_target,

   -- window_decorations = 'NONE',

   -- color scheme
   -- colors = colors,
   color_scheme = 'Catppuccin Mocha',

   -- background
   background = {
      {
         source = { File = wezterm.config_dir .. '/backdrops/space.jpg' },
      },
      {
         source = { Color = colors.background },
         height = '100%',
         width = '100%',
         opacity = 0.90,
      },
   },

   default_cursor_style = 'BlinkingBlock',
   cursor_blink_rate = 600,
   -- scrollbar
   enable_scroll_bar = false,

   -- tab bar
   enable_tab_bar = true,
   hide_tab_bar_if_only_one_tab = false,
   use_fancy_tab_bar = false,
   tab_max_width = 25,
   show_tab_index_in_tab_bar = false,
   switch_to_last_active_tab_when_closing_tab = true,

   -- window
   window_padding = {
      left = 5,
      right = 10,
      top = 12,
      bottom = 7,
   },
   window_close_confirmation = 'NeverPrompt',
   window_frame = {
      active_titlebar_bg = '#090909',
      font = fonts.font,
      font_size = fonts.font_size,
   },
   inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 },
}
