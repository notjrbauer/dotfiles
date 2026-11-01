local wezterm = require('wezterm')
local act = wezterm.action

-- macOS only (the Brewfile and launch.lua are), so SUPER is Cmd.
local mod = { SUPER = 'SUPER', SUPER_REV = 'SUPER|CTRL' }

-- SUPER-side chords only — tmux owns the C-a layer (.tmux.conf: prefix C-a,
-- prefix h/j/k/l, sticky resize table, copy mode) plus bare C-h/j/k/l pane
-- navigation. No LEADER here: a wezterm leader on C-a would swallow the tmux
-- prefix and force the old C-a C-a double-tap. Same layering as ghostty
-- (.config/ghostty/config), so both terminals feel identical over tmux.
--
-- The default key table is off: it binds CTRL-Tab, CTRL -/=/0 and the whole
-- CTRL|SHIFT letter set, which tmux (extended-keys csi-u) would otherwise
-- hand to nvim as distinct keys. Ghostty binds no CTRL chords on macOS. The
-- SUPER defaults worth keeping are listed below, explicitly.
local keys = {
  -- app / window (wezterm defaults, kept)
  { key = 'q', mods = 'SUPER', action = act.QuitApplication },
  { key = 'h', mods = 'SUPER', action = act.HideApplication },
  { key = 'm', mods = 'SUPER', action = act.Hide },
  { key = 'n', mods = 'SUPER', action = act.SpawnWindow },
  { key = 'r', mods = 'SUPER', action = act.ReloadConfiguration },
  { key = 'k', mods = 'SUPER', action = act.ClearScrollback('ScrollbackOnly') },
  { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
  { key = '=', mods = 'SUPER', action = act.IncreaseFontSize },
  { key = '0', mods = 'SUPER', action = act.ResetFontSize },

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

  -- copy / paste (macOS Cmd+C / Cmd+V)
  { key = 'c', mods = 'SUPER', action = act.CopyTo('Clipboard') },
  { key = 'v', mods = 'SUPER', action = act.PasteFrom('Clipboard') },
}
for i = 1, 8 do
  table.insert(keys, { key = tostring(i), mods = 'SUPER', action = act.ActivateTab(i - 1) })
end
table.insert(keys, { key = '9', mods = 'SUPER', action = act.ActivateTab(-1) })

local mouse_bindings = {
  -- Ctrl-click opens the link under the cursor
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
  -- Selecting is inert here too — the same rule as .tmux.conf (Copy-mode).
  -- Every wezterm default ends a left-button release in a CompleteSelection,
  -- including streaks 2 and 3 and the SHIFT/ALT variants. SHIFT is the
  -- mouse-reporting bypass, so inside tmux (mouse on) a Shift-drag is handled
  -- HERE rather than by tmux, and it would overwrite the clipboard the tmux
  -- copy-mode bindings are careful not to touch.
  --
  -- Not CompleteSelection('PrimarySelection'): on macOS the window backend
  -- ignores the destination and writes the general pasteboard either way
  -- (window/src/os/macos/window.rs set_clipboard, nightly of 2025-07-13), so that
  -- "no-op writer" copied on every drag. Nop ends the gesture without copying;
  -- the highlight made on Down/Drag stays, and SUPER-c copies it deliberately.
  -- Check: `printf sentinel | pbcopy`, drag-select, `pbpaste` → sentinel.
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'NONE', action = act.Nop },
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'SHIFT', action = act.Nop },
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'ALT', action = act.Nop },
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'SHIFT|ALT', action = act.Nop },
  { event = { Up = { streak = 2, button = 'Left' } }, mods = 'NONE', action = act.Nop },
  { event = { Up = { streak = 3, button = 'Left' } }, mods = 'NONE', action = act.Nop },
}

return {
  disable_default_key_bindings = true,
  keys = keys,
  mouse_bindings = mouse_bindings,
}
