local wezterm = require('wezterm')
local platform = require('utils.platform')()
local act = wezterm.action

local mod = {}

if platform.is_mac then
   mod.SUPER = 'SUPER'
   mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win then
   mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
   mod.SUPER_REV = 'ALT|CTRL'
end

local keys = {

   { key = 'a', mods = 'LEADER|CTRL', action = wezterm.action({ SendString = '\x01' }) },
   { key = 'z', mods = 'LEADER', action = 'TogglePaneZoomState' },
   { key = 'c', mods = 'LEADER', action = wezterm.action({ SpawnTab = 'CurrentPaneDomain' }) },
   { key = 'h', mods = 'CTRL', action = wezterm.action({ ActivatePaneDirection = 'Left' }) },
   { key = 'j', mods = 'CTRL', action = wezterm.action({ ActivatePaneDirection = 'Down' }) },
   { key = 'k', mods = 'CTRL', action = wezterm.action({ ActivatePaneDirection = 'Up' }) },
   { key = 'l', mods = 'CTRL', action = wezterm.action({ ActivatePaneDirection = 'Right' }) },

   {
      key = '"',
      mods = 'LEADER',
      action = wezterm.action({ SplitVertical = { domain = 'CurrentPaneDomain' } }),
   },
   {
      key = '%',
      mods = 'LEADER',
      action = wezterm.action({ SplitHorizontal = { domain = 'CurrentPaneDomain' } }),
   },
   {
      key = 's',
      mods = 'LEADER',
      action = wezterm.action({ SplitVertical = { domain = 'CurrentPaneDomain' } }),
   },
   {
      key = 'v',
      mods = 'LEADER',
      action = wezterm.action({ SplitHorizontal = { domain = 'CurrentPaneDomain' } }),
   },

   -- misc/useful --
   { key = '[', mods = 'LEADER', action = 'ActivateCopyMode' },
   { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
   { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
   { key = 'F4', mods = 'NONE', action = act.ShowTabNavigator },
   { key = 'F12', mods = 'NONE', action = act.ShowDebugOverlay },
   { key = 'f', mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },

   -- copy/paste --
   { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo('Clipboard') },
   { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom('Clipboard') },

   -- tabs --
   -- tabs: spawn+close
   { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },
   { key = 't', mods = mod.SUPER_REV, action = act.SpawnTab({ DomainName = 'WSL:Ubuntu' }) },
   { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },

   -- tabs: navigation
   { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
   { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
   { key = '[', mods = mod.SUPER_REV, action = act.ActivateLastTab },
   { key = ']', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

   -- window --
   -- spawn windows
   -- { key = 'n', mods = mod.SUPER, action = act.SpawnWindow },

   -- panes --
   -- panes: split panes
   {
      key = [[\]],
      mods = mod.SUPER,
      action = act.SplitVertical({ domain = 'CurrentPaneDomain' }),
   },
   {
      key = [[\]],
      mods = mod.SUPER_REV,
      action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
   },

   -- panes: zoom+close pane
   { key = 'z', mods = mod.SUPER_REV, action = act.TogglePaneZoomState },
   { key = 'w', mods = mod.SUPER, action = act.CloseCurrentPane({ confirm = false }) },

   { key = '-', mods = 'LEADER', action = act.AdjustPaneSize({ 'Up', 10 }) },
   { key = '=', mods = 'LEADER', action = act.AdjustPaneSize({ 'Down', 10 }) },

   -- panes: navigation
   -- { key = 'k', mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Up') },
   -- { key = 'j', mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Down') },
   -- { key = 'h', mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Left') },
   -- { key = 'l', mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Right') },

   -- key-tables --
   -- resizes fonts
   -- {
   --    key = 'f',
   --    mods = 'LEADER',
   --    action = act.ActivateKeyTable({
   --       name = 'resize_font',
   --       one_shot = false,
   --       timemout_miliseconds = 1000,
   --    }),
   -- },
   -- resize panes
   -- {
   --    key = 'p',
   --    mods = 'LEADER',
   --    action = act.ActivateKeyTable({
   --       name = 'resize_pane',
   --       one_shot = false,
   --       timemout_miliseconds = 1000,
   --    }),
   -- },
}

local key_tables = {
   -- resize_font = {
   --    { key = 'k', action = act.IncreaseFontSize },
   --    { key = 'j', action = act.DecreaseFontSize },
   --    { key = 'r', action = act.ResetFontSize },
   --    { key = 'Escape', action = 'PopKeyTable' },
   --    { key = 'q', action = 'PopKeyTable' },
   -- },
   search_mode = {
      { key = 'Enter', mods = 'NONE', action = act.CopyMode('PriorMatch') },
      { key = 'Escape', mods = 'NONE', action = act.CopyMode('Close') },
      { key = 'n', mods = 'CTRL', action = act.CopyMode('NextMatch') },
      { key = 'p', mods = 'CTRL', action = act.CopyMode('PriorMatch') },
      { key = 'r', mods = 'CTRL', action = act.CopyMode('CycleMatchType') },
      { key = 'u', mods = 'CTRL', action = act.CopyMode('ClearPattern') },
      {
         key = 'PageUp',
         mods = 'NONE',
         action = act.CopyMode('PriorMatchPage'),
      },
      {
         key = 'PageDown',
         mods = 'NONE',
         action = act.CopyMode('NextMatchPage'),
      },
      { key = 'UpArrow', mods = 'NONE', action = act.CopyMode('PriorMatch') },
      { key = 'DownArrow', mods = 'NONE', action = act.CopyMode('NextMatch') },
   },
   resize_pane = {
      -- { key = 'k', action = act.AdjustPaneSize({ 'Up', 1 }) },
      -- { key = 'j', action = act.AdjustPaneSize({ 'Down', 1 }) },
      -- { key = 'h', action = act.AdjustPaneSize({ 'Left', 1 }) },
      -- { key = 'l', action = act.AdjustPaneSize({ 'Right', 1 }) },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q', action = 'PopKeyTable' },
   },
}

local mouse_bindings = {
   -- Ctrl-click will open the link under the mouse cursor
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
   },
}

return {
   disable_default_key_bindings = false,
   leader = { key = 'a', mods = 'CTRL' },
   keys = keys,
   key_tables = key_tables,
   mouse_bindings = mouse_bindings,
}
