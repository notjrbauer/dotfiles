return {
  -- Login zsh via the stable Homebrew symlink (not the version-pinned
  -- /usr/local/opt/zsh/bin/zsh-5.9, which breaks on every zsh upgrade).
  default_prog = { '/usr/local/bin/zsh', '-l' },
  launch_menu = {},
}
