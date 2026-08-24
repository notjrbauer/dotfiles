return {
  -- Key repeat: on macOS use_ime defaults to true, which routes every keystroke
  -- through the input-method framework and makes held keys repeat sluggishly --
  -- holding j to scroll a buffer crawls no matter what KeyRepeat is set to.
  -- Costs nothing here: the Japanese IME cask is installed but has zero input
  -- modes enabled in Input Sources. Flip this back to true if that changes,
  -- since dead keys and IME composition need it.
  use_ime = false,
  -- exit_behavior = 'CloseOnCleanExit', -- if the shell program exited with a successful status

  scrollback_lines = 20000,

  -- Nightly cask: brew is the upgrade path; the built-in check only knows
  -- about stable releases.
  check_for_updates = false,
  -- tmux (libutf8proc, Unicode 16) and Ghostty size VS16 emoji as wide;
  -- wezterm defaults to Unicode 9 rules. Agree with the multiplexer.
  unicode_version = 14,
  -- hyperlink_rules: the defaults (wezterm.default_hyperlink_rules()) already
  -- cover bracketed URLs, bare URLs and mailto — the copy that used to live
  -- here was identical to them.
}
