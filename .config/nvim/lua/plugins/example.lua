local utils = require("utils")

return {
{
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  lazy = false,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      transparent_background = true,
      term_colors = true,
      integrations = {
        blink_cmp = true,
        treesitter = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    })

    vim.cmd.colorscheme("catppuccin")
  end,
},

-- {
--   "neovim/nvim-lspconfig",
--   config = function()
--     local lspconfig = require("lspconfig")
--
--     lspconfig.gopls.setup({
--       settings = {
--         gopls = {
--           semanticTokens = false,
--         },
--       },
--       -- optional: custom `on_attach` logic
--       on_attach = function(client, bufnr)
--         -- You can set keymaps here if you want
--       end,
--     })
--
--       -- opts.inlay_hints = { enabled = false }
--       --
--       -- opts.servers = opts.servers or {}
--       -- opts.servers.vtsls = { enabled = false }
--       --
--       -- opts.servers.gopls = opts.servers.gopls or {}
--       -- opts.servers.gopls.settings = opts.servers.gopls.settings or {}
--       -- opts.servers.gopls.settings.gopls = {
--       --   semanticTokens = false,
--       -- }
--       --
--       -- opts.setup = opts.setup or {}
--       -- opts.setup.gopls = function(_, _)
--       --   LazyVim.lsp.on_attach(function(client, _) end, "gopls")
--       -- end
--       --
--       -- return opts
--     end,
--   },

  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {},
  },

  {
    "stevearc/conform.nvim",
    lazy = false,
    opts = function(_, opts)
      return utils.deep_merge_opts(opts, {
        formatters_by_ft = {
          sh = { "shfmt" },
          markdown = { "prettierd" },
          ["markdown.mdx"] = { "prettierd" },
          json = { "jq" },
          javascript = { "dprint" },
          javascriptreact = { "dprint" },
          typescript = { "dprint" },
          typescriptreact = { "dprint" },
          go = { "gofumpt", "goimports" },
          rust = { "rustfmt" },
        },
        default_format_opts = {
          timeout_ms = 2000,
          lsp_fallback = true,
          async = false,
          quiet = false,
        },
        formatters = {
          shfmt = {
            prepend_args = { "-i", "2", "-ci" },
          },
          dprint = {
            condition = function(_, ctx)
              return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
            end,
          },
        },
      })
    end,
  },

  -- {
  --   "mfussenegger/nvim-lint",
  --   opts = function(_, opts)
  --     return utils.deep_merge_opts(opts, {
  --       linters_by_ft = {
  --         lua = { "selene", "luacheck" },
  --         markdown = { "markdownlint" },
  --       },
  --       linters = {
  --         selene = {
  --           condition = function(ctx)
  --             return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
  --           end,
  --         },
  --         luacheck = {
  --           condition = function(ctx)
  --             return vim.fs.find({ ".luacheckrc" }, { path = ctx.filename, upward = true })[1]
  --           end,
  --         },
  --       },
  --     })
  --   end,
  -- },

  -- nvim-treesitter: Syntax Highlighting {{{2
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {},
    event = "BufReadPost",
    auto_install = false,
    cmd = {
      "TSInstall",
      "TSUpdate",
      "TSInstallInfo",
      "TSEnable",
      "TSDisable",
      "TSModuleInfo",
      "TSUninstall",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash",
          "html",
          "javascript",
          "json",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "regex",
          "tsx",
          "typescript",
          "vim",
          "yaml",
          "go",
          "css",
          "gitignore",
          "rust",
          "cpp",
          "c",
          "vim",
          "vimdoc",
        },

        sync_install = false,

        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },

  {
    "aznhe21/actions-preview.nvim",
    config = function()
      vim.keymap.set({ "v", "n" }, "<leader>ca", require("actions-preview").code_actions)
    end,
  },

  {
    "sphamba/smear-cursor.nvim",
    opts = function(_, opts)
      return utils.deep_merge_opts(opts, {
        time_interval = 10, -- milliseconds
        stiffness = 0.5,
        trailing_stiffness = 0.5,
        damping = 0.67,
        matrix_pixel_threshold = 0.5,
        legacy_computing_symbols_support = true,
      })
    end,
  },

  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
      mappings = {}, -- disable all default scroll mappings
    },
  },

  -- {
  --   "blink.cmp",
  --   event = "InsertEnter",
  --   opts = function(_, opts)
  --     return utils.deep_merge_opts(opts, {
  --       mappings = {
  --         ["<C-n>"] = "next",
  --         ["<C-p>"] = "prev",
  --         ["<Tab>"] = "next",
  --         ["<S-Tab>"] = "prev",
  --         ["<CR>"] = "confirm",
  --         ["<C-e>"] = "abort",
  --       },
  --     })
  --   end,
  -- },
  {
    "nvim-focus/focus.nvim",
    event = "VeryLazy",
    version = "*",
    config = function()
      require("focus").setup({
        -- optional: your config here
        enable = true,
      })
    end,
  },
  {
    "zeioth/garbage-day.nvim",
    dependencies = "neovim/nvim-lspconfig",
    event = "VeryLazy",
  },
  -- render-markdown: Markdown Previews {{{2
  -- {
  --   "MeanderingProgrammer/render-markdown.nvim",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   ---@module 'render-markdown'
  --   ---@type render.md.UserConfig
  --   opts = {
  --     enabled = true,
  --     completions = { lsp = { enabled = true } },
  --   },
  -- },
  -- fzf-lua: Previewing and Grepping {{{2
  {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = {
      "junegunn/fzf",
      "BurntSushi/ripgrep",
      "nvim-tree/nvim-web-devicons",
      -- "MeanderingProgrammer/render-markdown.nvim",
    },
    -- or if using mini.icons/mini.nvim
    -- dependencies = { "echasnovski/mini.icons" },
    opts = {
      winopts = {
        preview = {
          default = "bat",
        },
      },
      -- bat's themes are bad and never match nvim perfectly. Make plain text so
      -- that text is themed according to nvim theme. Keep highlighting, line
      -- numbers, and git diff marks and it looks nice and is not distracting.
      previewers = {
        bat = {
          cmd = "bat",
          args = "--color=always --style=numbers,changes --decorations=always",
        },
      },
    },
    keys = {
      -- Files
      {
        mode = "n",
        "<leader>?",
        function()
          require("fzf-lua").oldfiles()
        end,
        desc = "[?] Find recently opened files",
      },
      {
        mode = "n",
        "<leader><space>",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "[ ] Find existing buffers",
      },
      {
        mode = "n",
        "<leader>sf",
        function()
          require("fzf-lua").files()
        end,
        desc = "[S]earch [F]iles",
      },
      {
        mode = "n",
        "<leader>sm",
        function()
          require("fzf-lua").manpages()
        end,
        desc = "[S]earch [M]anpages",
      },
      -- Grepping
      {
        mode = "n",
        "<leader>/",
        function()
          require("fzf-lua").lgrep_curbuf()
        end,
        desc = "[/] Live grep current buffer",
      },
      {
        mode = "n",
        "<leader>l",
        function()
          require("fzf-lua").lines()
        end,
        desc = "[l] Grep open buffer [L]ines",
      },
      {
        mode = "n",
        "<leader>sw",
        function()
          require("fzf-lua").grep_cword()
        end,
        desc = "[S]earch [W]ord under cursor",
      },
      {
        mode = "n",
        "<leader>sg",
        function()
          require("fzf-lua").live_grep()
        end,
        desc = "[S]earch by [G]rep",
      },
      {
        mode = "n",
        "<leader>sl",
        function()
          require("fzf-lua").live_grep_glob()
        end,
        desc = "[S]earch by grep g[L]ob",
      },
      {
        mode = "n",
        "<leader>sp",
        function()
          require("fzf-lua").grep_project()
        end,
        desc = "[S]earch [P]roject",
      },
      {
        mode = "v",
        "<leader>s",
        function()
          require("fzf-lua").grep_visual()
        end,
        desc = "[S]earch [V]isual selection",
      },
      -- Git
      {
        mode = "n",
        "<leader>gf",
        function()
          require("fzf-lua").git_files()
        end,
        desc = "Search [G]it [F]iles",
      },
      {
        mode = "n",
        "<leader>gc",
        function()
          require("fzf-lua").git_commits()
        end,
        desc = "Search [G]it [C]ommits",
      },
      {
        mode = "n",
        "<leader>gb",
        function()
          require("fzf-lua").git_bcommits()
        end,
        desc = "Search [G]it [B]uffer commits",
      },
      -- LSP
      {
        mode = "n",
        "<leader>sd",
        function()
          require("fzf-lua").diagnostics_document()
        end,
        desc = "[S]earch [D]iagnostics",
      },
      {
        mode = "n",
        "<leader>so",
        function()
          require("fzf-lua").lsp_references()
        end,
        desc = "LSP: [S]earch [O]ccurences",
      },
      {
        mode = "n",
        "<leader>ds",
        function()
          require("fzf-lua").lsp_document_symbols()
        end,
        desc = "LSP: [d]ocument [s]ymbols",
      },
      {
        mode = "n",
        "<leader>ws",
        function()
          require("fzf-lua").lsp_workspace_symbols()
        end,
        desc = "LSP: [w]orkspace [s]ymbols",
      },
      {
        mode = "n",
        "gI",
        function()
          require("fzf-lua").lsp_implementations()
        end,
        desc = "LSP: [g]oto [I]mplementation",
      },
      -- Misc
      {
        mode = "n",
        "<leader>sb",
        function()
          require("fzf-lua").builtin()
        end,
        desc = "[S]earch fzf-lua [B]uiltins",
      },
      {
        mode = "n",
        "<leader>sh",
        function()
          require("fzf-lua").help_tags()
        end,
        desc = "[S]earch [H]elp",
      },
      {
        mode = "n",
        "<leader>sr",
        function()
          require("fzf-lua").resume()
        end,
        desc = "[S]earch [R]esume",
      },
    },
  },
  -- {
  --   "m4xshen/hardtime.nvim",
  --   lazy = false,
  --   dependencies = { "MunifTanjim/nui.nvim" },
  --   opts = {
  --     restriction_mode = "hint",
  --   },
  -- },
  {
  "saghen/blink.cmp",
  version = "v1.2.0",
  event = "InsertEnter",
  dependencies = {
    {
      "rafamadriz/friendly-snippets",
    }
  },
  opts = {
    keymap = {
      ["<CR>"] = { "accept", "fallback" },
    },
    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 250,
        treesitter_highlighting = true,
      },
      list = {
        selection = { preselect = false, auto_insert = true },
      },
    },
    signature = { enabled = true },
    sources = {
      default = { "lsp", "path", "buffer"},
    },
  },
  opts_extend = { "sources.default" },
}
}
