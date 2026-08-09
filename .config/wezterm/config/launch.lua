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

return {
  default_prog = { zsh, '-l' },
  launch_menu = {},
}
