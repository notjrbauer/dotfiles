-- Login zsh via the stable Homebrew symlink (not the version-pinned
-- /usr/local/opt/zsh/bin/zsh-5.9, which breaks on every zsh upgrade).
-- The prefix differs by arch: /opt/homebrew (Apple Silicon) vs /usr/local
-- (Intel); fall back to the system zsh so panes always spawn.
local zsh = '/bin/zsh'
for _, candidate in ipairs({ '/opt/homebrew/bin/zsh', '/usr/local/bin/zsh' }) do
  local f = io.open(candidate, 'r')
  if f then
    f:close()
    zsh = candidate
    break
  end
end

-- Start every window inside tmux. `new-session -A -s main` attaches to "main"
-- if it exists and creates it otherwise, so closing the last WezTerm window
-- never loses the session -- reopening reattaches to the same one.
--
-- tmux is deliberately not exec'd: exec would replace the shell, so `tmux
-- detach` would leave nothing running and take the window down with it.
-- Falling through to an exec'd login shell means detach lands at a prompt.
--
-- Resolved the same defensive way as zsh above: if tmux isn't installed yet
-- (first boot, before brew bundle), fall back to a plain login shell instead
-- of spawning windows that die immediately.
local tmux
for _, candidate in ipairs({ '/opt/homebrew/bin/tmux', '/usr/local/bin/tmux' }) do
  local f = io.open(candidate, 'r')
  if f then
    f:close()
    tmux = candidate
    break
  end
end

local prog = { zsh, '-l' }
if tmux then
  prog = { zsh, '-l', '-c', string.format('%q new-session -A -s main; exec %q -l', tmux, zsh) }
end

return {
  default_prog = prog,
}
