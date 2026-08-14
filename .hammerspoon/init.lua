-- Hammerspoon — window management and a terminal toggle.
--
-- Replaces BetterSnapTool, which is a Mac App Store app and so needs an Apple
-- ID; everything here installs via Homebrew. Requires Accessibility permission
-- (System Settings > Privacy & Security > Accessibility > Hammerspoon).

-- Move windows instantly. The default 0.2s tween is visible enough to feel
-- like lag when you're chaining placements.
hs.window.animationDuration = 0

-- Hyper: all four modifiers. Nothing in macOS or any app claims this
-- combination, so the layout keys below can't collide with an app shortcut.
local mash = { "cmd", "alt", "ctrl", "shift" }

-- Place the focused window on a fraction of the screen. Coordinates are
-- fractions of the *usable* frame: screen:frame() excludes the menu bar and
-- Dock, where fullFrame() would slide windows underneath them.
local function place(x, y, w, h)
  return function()
    local win = hs.window.focusedWindow()
    if not win then
      return
    end
    local f = win:screen():frame()
    win:setFrame({
      x = f.x + (f.w * x),
      y = f.y + (f.h * y),
      w = f.w * w,
      h = f.h * h,
    })
  end
end

-- stylua: ignore start
local layouts = {
  -- halves
  left  = place(0,   0,   0.5, 1  ),
  right = place(0.5, 0,   0.5, 1  ),
  up    = place(0,   0,   1,   0.5),
  down  = place(0,   0.5, 1,   0.5),
  -- full screen (not macOS fullscreen: no Space switch, no menu-bar hiding)
  f     = place(0,   0,   1,   1  ),
  -- quadrants, numbered left-to-right then top-to-bottom
  ["1"] = place(0,   0,   0.5, 0.5),
  ["2"] = place(0.5, 0,   0.5, 0.5),
  ["3"] = place(0,   0.5, 0.5, 0.5),
  ["4"] = place(0.5, 0.5, 0.5, 0.5),
}
-- stylua: ignore end

for key, fn in pairs(layouts) do
  hs.hotkey.bind(mash, key, fn)
end

-- cmd+` toggles WezTerm: focus it, or hide it if it's already frontmost.
-- macOS assigns cmd+` to "cycle windows in the active app"; binding it here
-- takes precedence globally, and WezTerm's own tabs/panes cover that need.
local TERMINAL = "WezTerm"

-- isVisible() is false for a window that is minimized or whose app is hidden,
-- which is exactly the "menu bar says WezTerm, nothing on screen" state.
local function hasVisibleWindow(app)
  for _, win in ipairs(app:allWindows()) do
    if win:isVisible() then
      return true
    end
  end
  return false
end

hs.hotkey.bind({ "cmd" }, "`", function()
  local app = hs.application.get(TERMINAL)
  if not app then
    hs.application.launchOrFocus(TERMINAL)
    return
  end
  -- Only toggle off when there's something to toggle off. Minimizing the last
  -- window leaves the app frontmost, and there the hotkey should restore it.
  if app:isFrontmost() and hasVisibleWindow(app) then
    app:hide()
    return
  end
  local wins = app:allWindows()
  if #wins == 0 then
    -- Running but windowless (last window closed). activate() would focus a
    -- menu bar with no window, so ask the app to open one.
    hs.application.launchOrFocus(TERMINAL)
    return
  end
  -- activate() only moves focus: it leaves a hidden app hidden and a minimized
  -- window in the Dock, so the menu bar switches with no window on screen.
  -- Undo both first, then activate(true) to raise every window above the
  -- others rather than just the key one.
  app:unhide()
  for _, win in ipairs(wins) do
    if win:isMinimized() then
      win:unminimize()
    end
  end
  app:activate(true)
end)

-- Command-line control (`hs -c '...'`), used to verify bindings without
-- clicking. Guarded: it writes into the Homebrew prefix and is not essential.
pcall(function()
  hs.ipc.cliInstall("/opt/homebrew")
end)

hs.notify.new({ title = "Hammerspoon", informativeText = "config loaded" }):send()
