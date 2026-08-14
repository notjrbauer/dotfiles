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

-- SUPER-side chords only — tmux owns the C-a layer (.tmux.conf: prefix C-a,
-- prefix h/j/k/l, sticky resize table, copy mode) plus bare C-h/j/k/l pane
-- navigation. No LEADER here: a wezterm leader on C-a would swallow the tmux
-- prefix and force the old C-a C-a double-tap. Same layering as ghostty
-- (.config/ghostty/config), so both terminals feel identical over tmux.
local keys = {
  -- panes: split / zoom / close (native wezterm panes, for use outside tmux)
  { key = [[\]], mods = mod.SUPER, action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  {
    key = [[\]],
    mods = mod.SUPER_REV,
    action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
  },
  { key = 'z', mods = mod.SUPER_REV, action = act.TogglePaneZoomState },
  { key = 'w', mods = mod.SUPER, action = act.CloseCurrentPane({ confirm = false }) },

  -- tabs
  { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },
  { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },
  { key = '[', mods = mod.SUPER_REV, action = act.ActivateLastTab },
  { key = ']', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

  -- misc
  { key = 'f', mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
  { key = 'F12', mods = 'NONE', action = act.ShowDebugOverlay },

  -- copy / paste (macOS Cmd+C / Cmd+V). Bound explicitly so they never depend
  -- on wezterm's default key set.
  { key = 'c', mods = 'SUPER', action = act.CopyTo('Clipboard') },
  { key = 'v', mods = 'SUPER', action = act.PasteFrom('Clipboard') },
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
}

local mouse_bindings = {
  -- Ctrl-click opens the link under the cursor
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
  -- Selecting is inert here too — the same rule as .tmux.conf (Copy-mode).
  -- Every wezterm default ends a left-button release in
  -- CompleteSelection('ClipboardAndPrimarySelection'), including streaks 2 and 3
  -- and including the SHIFT variants. SHIFT is the mouse-reporting bypass, so
  -- inside tmux (mouse on) a Shift-drag is handled HERE rather than by tmux, and
  -- it would overwrite the clipboard the tmux copy-mode bindings are careful not
  -- to touch. 'PrimarySelection' is a no-op writer on macOS: the highlight stays,
  -- the clipboard does not move, and SUPER-c still copies deliberately.
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'PrimarySelection',
  },
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'SHIFT',
    action = act.CompleteSelection 'PrimarySelection',
  },
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'PrimarySelection',
  },
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'PrimarySelection',
  },
}

return {
  disable_default_key_bindings = false,
  keys = keys,
  key_tables = key_tables,
  mouse_bindings = mouse_bindings,
}
