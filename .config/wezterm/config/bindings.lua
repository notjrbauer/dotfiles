local wezterm = require('wezterm')
local platform = require('utils.platform')
local act = wezterm.action

local mod = {}
if platform.is_mac then
  mod.SUPER = 'SUPER'
  mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
  mod.SUPER = 'ALT' -- avoid clashing with the Windows key
  mod.SUPER_REV = 'ALT|CTRL'
end

local keys = {
  -- send a literal C-a to the terminal (tmux/readline) with C-a C-a
  { key = 'a', mods = 'LEADER|CTRL', action = act.SendString('\x01') },

  -- panes: navigation on the LEADER (C-a) so bare C-h/j/k/l stays free for
  -- Neovim's window navigation.
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection('Left') },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection('Down') },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection('Up') },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection('Right') },

  -- panes: split
  { key = '"', mods = 'LEADER', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = '%', mods = 'LEADER', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = 's', mods = 'LEADER', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = 'v', mods = 'LEADER', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = [[\]], mods = mod.SUPER, action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = [[\]], mods = mod.SUPER_REV, action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },

  -- panes: zoom / resize / close
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
  { key = 'z', mods = mod.SUPER_REV, action = act.TogglePaneZoomState },
  { key = '-', mods = 'LEADER', action = act.AdjustPaneSize({ 'Down', 10 }) },
  { key = '=', mods = 'LEADER', action = act.AdjustPaneSize({ 'Up', 10 }) },
  -- LEADER r enters a sticky resize mode (h/j/k/l to resize in any direction)
  { key = 'r', mods = 'LEADER', action = act.ActivateKeyTable({ name = 'resize_pane', one_shot = false, timeout_milliseconds = 1000 }) },
  { key = 'w', mods = mod.SUPER, action = act.CloseCurrentPane({ confirm = false }) },

  -- tabs
  { key = 'c', mods = 'LEADER', action = act.SpawnTab('CurrentPaneDomain') },
  { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },
  { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = '[', mods = mod.SUPER_REV, action = act.ActivateLastTab },
  { key = ']', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

  -- misc
  { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },
  { key = 'f', mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
  { key = 'F12', mods = 'NONE', action = act.ShowDebugOverlay },

  -- copy / paste
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo('Clipboard') },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom('Clipboard') },
}

local key_tables = {
  search_mode = {
    { key = 'Enter', mods = 'NONE', action = act.CopyMode('PriorMatch') },
    { key = 'Escape', mods = 'NONE', action = act.CopyMode('Close') },
    { key = 'n', mods = 'CTRL', action = act.CopyMode('NextMatch') },
    { key = 'p', mods = 'CTRL', action = act.CopyMode('PriorMatch') },
    { key = 'r', mods = 'CTRL', action = act.CopyMode('CycleMatchType') },
    { key = 'u', mods = 'CTRL', action = act.CopyMode('ClearPattern') },
    { key = 'PageUp', mods = 'NONE', action = act.CopyMode('PriorMatchPage') },
    { key = 'PageDown', mods = 'NONE', action = act.CopyMode('NextMatchPage') },
    { key = 'UpArrow', mods = 'NONE', action = act.CopyMode('PriorMatch') },
    { key = 'DownArrow', mods = 'NONE', action = act.CopyMode('NextMatch') },
  },

  -- Enter via LEADER r. Resize in any direction with h/j/k/l; Escape/q or 1s
  -- of inactivity exits back to normal.
  resize_pane = {
    { key = 'h', action = act.AdjustPaneSize({ 'Left', 3 }) },
    { key = 'j', action = act.AdjustPaneSize({ 'Down', 3 }) },
    { key = 'k', action = act.AdjustPaneSize({ 'Up', 3 }) },
    { key = 'l', action = act.AdjustPaneSize({ 'Right', 3 }) },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'q', action = 'PopKeyTable' },
  },
}

local mouse_bindings = {
  -- Ctrl-click opens the link under the cursor
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = act.OpenLinkAtMouseCursor },
}

return {
  disable_default_key_bindings = false,
  leader = { key = 'a', mods = 'CTRL' },
  keys = keys,
  key_tables = key_tables,
  mouse_bindings = mouse_bindings,
}
