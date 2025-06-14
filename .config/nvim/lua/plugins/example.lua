return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = { transparent_background = true },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  {
    "neovim/nvim-lspconfig",
    lazy = false,
    opts = function(_, opts)
      opts.inlay_hints = { enabled = false }

      opts.servers = opts.servers or {}
      opts.servers.vtsls = { enabled = false }

      opts.servers.gopls = opts.servers.gopls or {}
      opts.servers.gopls.settings = opts.servers.gopls.settings or {}
      opts.servers.gopls.settings.gopls = {
        semanticTokens = false,
      }

      opts.setup = opts.setup or {}
      opts.setup.gopls = function(_, _)
        LazyVim.lsp.on_attach(function(client, _) end, "gopls")
      end

      return opts
    end,
  },

  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {},
  },

  {
    "stevearc/conform.nvim",
    lazy = false,
    opts = {
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
    },
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        lua = { "selene", "luacheck" },
        markdown = { "markdownlint" },
      },
      linters = {
        selene = {
          condition = function(ctx)
            return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        luacheck = {
          condition = function(ctx)
            return vim.fs.find({ ".luacheckrc" }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_extend("force", opts.ensure_installed or {}, {
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
        "rust",
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
    opts = {
      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      scroll_buffer_space = true,
      legacy_computing_symbols_support = false,
      smear_insert_mode = true,
    },
  },

  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
      mappings = {}, -- disable all default scroll mappings
    },
  },

  {
    "blink.cmp",
    event = "InsertEnter",
    opts = function(_, opts)
      opts.mappings = vim.tbl_extend("force", opts.mappings or {}, {
        ["<C-n>"] = "next",
        ["<C-p>"] = "prev",
        ["<Tab>"] = "next",
        ["<S-Tab>"] = "prev",
        ["<CR>"] = "confirm",
        ["<C-e>"] = "abort",
      })
    end,
  },
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
  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      restriction_mode = "hint",
    },
  },
}
