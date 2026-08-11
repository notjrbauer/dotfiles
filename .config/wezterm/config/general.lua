return {
  -- behaviours
  automatically_reload_config = true,

  -- Key repeat: on macOS use_ime defaults to true, which routes every keystroke
  -- through the input-method framework and makes held keys repeat sluggishly --
  -- holding j to scroll a buffer crawls no matter what KeyRepeat is set to.
  -- Costs nothing here: the Japanese IME cask is installed but has zero input
  -- modes enabled in Input Sources. Flip this back to true if that changes,
  -- since dead keys and IME composition need it.
  use_ime = false,
  -- exit_behavior = 'CloseOnCleanExit', -- if the shell program exited with a successful status

  scrollback_lines = 20000,

  hyperlink_rules = {
    -- Matches: a URL in parens: (URL)
    {
      regex = '\\((\\w+://\\S+)\\)',
      format = '$1',
      highlight = 1,
    },
    -- Matches: a URL in brackets: [URL]
    {
      regex = '\\[(\\w+://\\S+)\\]',
      format = '$1',
      highlight = 1,
    },
    -- Matches: a URL in curly braces: {URL}
    {
      regex = '\\{(\\w+://\\S+)\\}',
      format = '$1',
      highlight = 1,
    },
    -- Matches: a URL in angle brackets: <URL>
    {
      regex = '<(\\w+://\\S+)>',
      format = '$1',
      highlight = 1,
    },
    -- Then handle URLs not wrapped in brackets
    {
      regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
      format = '$0',
    },
    -- implicit mailto link
    {
      regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',
      format = 'mailto:$0',
    },
  },
}
