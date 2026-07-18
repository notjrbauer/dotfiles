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

-- AdjustPaneSize is directional and *boundary-relative*: e.g. 'Down' moves the
-- active pane's shared split boundary downward, so the very same key grows the
-- pane when it sits above the boundary but shrinks it when it sits below (and
-- does nothing coherent with a single pane). That is why LEADER `-`/`=` felt
-- "inverted" depending on focus / pane count.
--
-- `resize` restores a tmux-style, position-independent grow/shrink: it inspects
-- the tab layout, finds the neighbour to push against, and always makes the
-- active pane bigger or smaller. With a single pane it is a harmless no-op.
---@param axis 'v'|'h'  vertical (height) or horizontal (width)
---@param grow boolean  true = enlarge the active pane, false = shrink it
---@param amount integer cells to adjust by
---@return table  an action_callback key assignment
local function resize(axis, grow, amount)
  return wezterm.action_callback(function(window, pane)
    local tab = pane:tab()
    if tab == nil then
      return
    end

    local panes = tab:panes_with_info()
    local me
    for _, p in ipairs(panes) do
      if p.is_active then
        me = p
        break
      end
    end
    if me == nil then
      return
    end

    -- Is there a neighbouring pane below (vertical) / to the right (horizontal)?
    local neighbour_after = false
    for _, p in ipairs(panes) do
      if axis == 'v' then
        if p.top >= me.top + me.height and p.left < me.left + me.width and p.left + p.width > me.left then
          neighbour_after = true
          break
        end
      else
        if p.left >= me.left + me.width and p.top < me.top + me.height and p.top + p.height > me.top then
          neighbour_after = true
          break
        end
      end
    end

    -- Push against whichever boundary actually grows/shrinks the active pane.
    local towards
    if axis == 'v' then
      towards = (grow == neighbour_after) and 'Down' or 'Up'
    else
      towards = (grow == neighbour_after) and 'Right' or 'Left'
    end

    window:perform_action(act.AdjustPaneSize({ towards, amount }), pane)
  end)
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
  -- vertical divider grow/shrink: `-`/`=` = shorter/taller (tmux-style, size-based).
  { key = '-', mods = 'LEADER', action = resize('v', false, 10) },
  { key = '=', mods = 'LEADER', action = resize('v', true, 10) },
  -- horizontal divider: `(`/`)` move the shared vertical divider left/right on
  -- screen, independent of which side the active pane is on. AdjustPaneSize's
  -- named direction *is* the direction the divider moves (see AdjustPaneSize.md),
  -- so plain directional actions are correct here — no neighbour detection needed.
  { key = '(', mods = 'LEADER', action = act.AdjustPaneSize({ 'Left', 10 }) },
  { key = ')', mods = 'LEADER', action = act.AdjustPaneSize({ 'Right', 10 }) },
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
