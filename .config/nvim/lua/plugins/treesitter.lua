return {
  { 'nvim-treesitter/playground', cmd = 'TSPlaygroundToggle' },

  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'BufReadPre',
    enabled = true,
    opts = { mode = 'cursor' },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = {
      ensure_installed = {
        'astro',
        'bash',
        'c',
        'cmake',
        -- "comment", -- comments are slowing down TS bigtime, so disable for now
        'cpp',
        'css',
        'diff',
        'fish',
        'gitignore',
        'go',
        'graphql',
        'html',
        'http',
        'java',
        'javascript',
        'jsdoc',
        'jsonc',
        'lua',
        'luap',
        'markdown',
        'markdown_inline',
        'meson',
        'ninja',
        'nix',
        'norg',
        'org',
        'php',
        'python',
        'query',
        'regex',
        'rust',
        'scss',
        'sql',
        'svelte',
        'teal',
        'toml',
        'tsx',
        'typescript',
        'vhs',
        'vim',
        'vimdoc',
        'vue',
        'wgsl',
        'yaml',
        -- "wgsl",
        'json',
        -- "markdown",
      },
      matchup = {
        enable = true,
      },
      -- highlight = { enable = true },
      query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { 'BufWrite', 'CursorHold' },
      },
      playground = {
        enable = true,
        disable = {},
        updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
        persist_queries = true, -- Whether the query persists across vim sessions
        keybindings = {
          toggle_query_editor = 'o',
          toggle_hl_groups = 'i',
          toggle_injected_languages = 't',
          toggle_anonymous_nodes = 'a',
          toggle_language_display = 'I',
          focus_language = 'f',
          unfocus_language = 'F',
          update = 'R',
          goto_node = '<cr>',
          show_help = '?',
        },
      },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      { 'windwp/nvim-ts-autotag', opts = {} },
    },
  },
}