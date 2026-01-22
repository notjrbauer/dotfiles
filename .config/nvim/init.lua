-- Modern Neovim 0.11+ Configuration
-- ~/.config/nvim/init.lua

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PERFORMANCE: Enable loader cache for faster startup (50% improvement)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.loader.enable()

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- BOOTSTRAP & SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Disable builtin plugins for performance
local disabled_built_ins = {
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin",
  "getscript", "getscriptPlugin", "vimball", "vimballPlugin",
  "2html_plugin", "logiPat", "rrhelper",
  "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers",
}

for _, plugin in ipairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    lazyrepo, lazypath
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CORE SETTINGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local opt = vim.opt

-- UI Settings
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes:1"
opt.cursorline = true
opt.laststatus = 3
opt.showmode = false
opt.cmdheight = 0
opt.pumheight = 15
opt.termguicolors = true

-- Editor Behavior
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.completeopt = "menu,menuone,noinsert,noselect"
opt.conceallevel = 2
opt.confirm = true
opt.formatoptions = "jcroqlnt"
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.inccommand = "split"
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.smoothscroll = true
opt.virtualedit = "block"
opt.winminwidth = 5
opt.wrap = false
opt.linebreak = true

-- Files and Backups
opt.autowrite = true
opt.backup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000
opt.writebackup = false

-- Ensure undo directory exists
local undodir = vim.fn.stdpath("data") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
opt.undodir = undodir

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Indentation
opt.autoindent = true
opt.smartindent = true
opt.expandtab = true
opt.shiftround = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2

-- Splits
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

-- Timeouts
opt.timeout = true
opt.timeoutlen = 300
opt.updatetime = 200

-- Scrolling
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Wildmenu
opt.wildmode = "longest:full,full"
opt.wildignore:append({
  "*.o", "*.obj", "*.dylib", "*.bin", "*.dll", "*.exe",
  "*/.git/*", "*/.svn/*", "*/.DS_Store",
  "*/node_modules/*", "*/target/*", "*/.cargo/*"
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UTILITY FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function augroup(name)
  return vim.api.nvim_create_augroup("config_" .. name, { clear = true })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LSP CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Default LSP attach function
local function on_attach(client, bufnr)
  -- Disable semantic tokens globally (can be enabled per-server if needed)
  if client.server_capabilities.semanticTokensProvider then
    client.server_capabilities.semanticTokensProvider = nil
  end

  -- Format on save if supported
  if client.server_capabilities.documentFormattingProvider then
    local format_group = augroup("lsp_format_" .. bufnr)
    vim.api.nvim_create_autocmd({ "BufWritePre" }, {
      group = format_group,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({
          bufnr = bufnr,
          timeout_ms = 3000,
          async = false,
        })
      end,
    })
  end
end

-- Go-specific LSP attach with organize imports
local function gopls_on_attach(client, bufnr)
  -- Call default on_attach first
  on_attach(client, bufnr)

  -- Override BufWritePre to organize imports before formatting
  local format_group = augroup("gopls_format_" .. bufnr)
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = format_group,
    buffer = bufnr,
    callback = function()
      -- Organize imports using code action
      local params = {
        context = {
          only = { "source.organizeImports" },
          diagnostics = {},
        },
      }

      -- Request organize imports code action
      local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)

      if result then
        for _, res in pairs(result) do
          if res.result then
            for _, action in pairs(res.result) do
              -- Apply the edit if it's an organize imports action
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
              end
            end
          end
        end
      end

      -- Then format
      vim.lsp.buf.format({
        bufnr = bufnr,
        timeout_ms = 3000,
        async = false,
      })
    end,
  })
end

-- Server configurations
local servers = {
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME },
        },
        telemetry = { enable = false },
        hint = {
          enable = true,
          setType = false,
          paramType = true,
          paramName = "Disable",
          semicolon = "Disable",
          arrayIndex = "Disable",
        },
      },
    },
  },
  gopls = {
    on_attach = gopls_on_attach,
    settings = {
      gopls = {
        gofumpt = true,
        codelenses = {
          gc_details = false,
          generate = true,
          regenerate_cgo = true,
          run_govulncheck = true,
          test = true,
          tidy = true,
          upgrade_dependency = true,
          vendor = true,
        },
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        analyses = {
          nilness = true,
          unusedparams = true,
          unusedwrite = true,
          useany = true,
          shadow = true,
        },
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
        directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
        semanticTokens = true,
      },
    },
  },
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        checkOnSave = { command = "clippy" },
        procMacro = { enable = true },
      },
    },
  },
  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
    },
  },
  zls = {},
  marksman = {},
}

-- Diagnostic configuration with ORIGINAL signs
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
  float = {
    border = "rounded",
    source = true,
  },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PLUGIN SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

require("lazy").setup({
  -- ══════════════════════════════════════════════════════════════════════════
  -- UI & Appearance
  -- ══════════════════════════════════════════════════════════════════════════

  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      show_end_of_buffer = true,
      term_colors = true,
      integrations = {
        blink_cmp = true,
        fzf = true,
        mason = true,
        native_lsp = { enabled = true },
        treesitter = true,
        which_key = true,
        gitsigns = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  {
    "echasnovski/mini.icons",
    lazy = true,
    opts = {
      style = "glyph",
    },
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  -- Navigation & UI
  -- ══════════════════════════════════════════════════════════════════════════

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = function(ctx)
        return ctx.plugin and 0 or 200
      end,
      spec = {
        { "<leader>c", group = "code" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hunks" },
        { "<leader>q", group = "quit/session" },
        { "<leader>s", group = "search" },
        { "<leader>u", group = "ui" },
        { "<leader>w", group = "windows" },
        { "<leader>x", group = "diagnostics" },
        { "[",         group = "prev" },
        { "]",         group = "next" },
        { "g",         group = "goto" },
        { "z",         group = "fold" },
      },
    },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer Keymaps",
      },
    },
  },

  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    dependencies = { "echasnovski/mini.icons" },
    keys = {
      { "-",          "<cmd>Oil<cr>", desc = "Open parent directory" },
      { "<leader>e",  "<cmd>Oil<cr>", desc = "File Explorer" },
      { "<leader>fe", "<cmd>Oil<cr>", desc = "File Explorer" },
    },
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = true,
        natural_order = true,
        is_always_hidden = function(name)
          return name == ".." or name == ".git"
        end,
      },
      win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-s>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-r>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
      },
    },
  },

  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "echasnovski/mini.icons" },
    keys = {
      -- LSP
      { "grr",              function() require("fzf-lua").lsp_references() end,                          desc = "LSP References" },
      { "gd",               function() require("fzf-lua").lsp_definitions() end,                         desc = "Goto Definition" },
      { "gI",               function() require("fzf-lua").lsp_implementations() end,                     desc = "Goto Implementation" },
      { "gy",               function() require("fzf-lua").lsp_typedefs() end,                            desc = "Goto Type Definition" },
      { "<leader>ds",       function() require("fzf-lua").lsp_document_symbols() end,                    desc = "Document Symbols" },
      { "<leader>ws",       function() require("fzf-lua").lsp_live_workspace_symbols() end,              desc = "Workspace Symbols" },

      -- Actions
      { "<leader>cr",       vim.lsp.buf.rename,                                                          desc = "Rename" },
      { "<leader>ca",       vim.lsp.buf.code_action,                                                     mode = { "n", "v" },           desc = "Code Action" },
      { "gD",               vim.lsp.buf.declaration,                                                     desc = "Goto Declaration" },

      -- Files
      { "<leader><leader>", function() require("fzf-lua").files() end,                                   desc = "Find Files" },
      { "<leader>ff",       function() require("fzf-lua").files() end,                                   desc = "Find Files" },
      { "<leader>fc",       function() require("fzf-lua").files({ cwd = vim.fn.stdpath("config") }) end, desc = "Config Files" },
      { "<leader>fr",       function() require("fzf-lua").oldfiles() end,                                desc = "Recent Files" },

      -- Search
      { "<leader>sg",       function() require("fzf-lua").live_grep() end,                               desc = "Live Grep" },
      { "<leader>sw",       function() require("fzf-lua").grep_cword() end,                              desc = "Grep Word" },
      { "<leader>sW",       function() require("fzf-lua").grep_cWORD() end,                              desc = "Grep WORD" },
      { "<leader>sb",       function() require("fzf-lua").lgrep_curbuf() end,                            desc = "Grep Buffer" },
      { "<leader>ss",       function() require("fzf-lua").builtin() end,                                 desc = "Search Select" },

      -- Other
      { "<leader>,",        function() require("fzf-lua").buffers() end,                                 desc = "Buffers" },
      { "<leader>/",        function() require("fzf-lua").lgrep_curbuf() end,                            desc = "Grep Buffer" },
      { "<leader>fh",       function() require("fzf-lua").helptags() end,                                desc = "Help Tags" },
      { "<leader>fk",       function() require("fzf-lua").keymaps() end,                                 desc = "Keymaps" },
      { "<leader>fd",       function() require("fzf-lua").diagnostics_document() end,                    desc = "Document Diagnostics" },
      { "<leader>fD",       function() require("fzf-lua").diagnostics_workspace() end,                   desc = "Workspace Diagnostics" },
    },
    opts = function()
      local actions = require("fzf-lua.actions")
      return {
        fzf_colors = true,
        fzf_opts = {
          ["--no-scrollbar"] = true,
          ["--info"] = "inline-right",
        },
        defaults = {
          formatter = "path.filename_first",
        },
        previewers = {
          builtin = {
            syntax_limit_b = 1024 * 100, -- 100KB
          },
        },
        winopts = {
          height = 0.85,
          width = 0.80,
          row = 0.35,
          col = 0.50,
          border = "rounded",
          preview = {
            border = "border",
            wrap = "nowrap",
            hidden = "nohidden",
            vertical = "down:45%",
            horizontal = "right:50%",
            layout = "flex",
            flip_columns = 120,
          },
        },
        keymap = {
          builtin = {
            ["<C-/>"] = "toggle-help",
            ["<C-a>"] = "toggle-fullscreen",
            ["<C-i>"] = "toggle-preview",
            ["<C-f>"] = "preview-page-down",
            ["<C-b>"] = "preview-page-up",
          },
          fzf = {
            ["ctrl-q"] = "select-all+accept",
            ["ctrl-u"] = "half-page-up",
            ["ctrl-d"] = "half-page-down",
            ["ctrl-f"] = "preview-page-down",
            ["ctrl-b"] = "preview-page-up",
          },
        },
        files = {
          prompt = "Files❯ ",
          cwd_prompt = false,
          actions = {
            ["ctrl-g"] = actions.toggle_ignore,
          },
        },
        grep = {
          prompt = "Grep❯ ",
          rg_glob = true,
          actions = {
            ["ctrl-g"] = actions.toggle_ignore,
          },
        },
        lsp = {
          symbols = {
            symbol_style = 1,
          },
        },
        oldfiles = {
          include_current_session = true,
        },
      }
    end,
    config = function(_, opts)
      require("fzf-lua").setup(opts)
      require("fzf-lua").register_ui_select()
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  -- Completion
  -- ══════════════════════════════════════════════════════════════════════════

  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    dependencies = "rafamadriz/friendly-snippets",
    version = "*",
    opts = {
      keymap = {
        preset = "default",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          buffer = {
            max_items = 4,
            min_keyword_length = 4,
          },
        },
      },
      completion = {
        accept = {
          auto_brackets = { enabled = true },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          treesitter_highlighting = true,
          window = { border = "rounded" },
        },
        ghost_text = { enabled = true },
        menu = {
          border = "rounded",
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "kind_icon" },
              { "label",    "label_description", gap = 1 },
              { "kind" },
            },
          },
        },
      },
      signature = {
        enabled = true,
        window = { border = "rounded" },
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  -- LSP
  -- ══════════════════════════════════════════════════════════════════════════

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "saghen/blink.cmp",
      {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        opts = {
          ui = {
            border = "rounded",
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗",
            },
          },
        },
      },
      {
        "williamboman/mason-lspconfig.nvim",
        opts = {
          ensure_installed = vim.tbl_keys(servers),
          automatic_installation = true,
        },
      },
      {
        "pmizio/typescript-tools.nvim",
        ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
          on_attach = on_attach,
          settings = {
            tsserver_file_preferences = {
              includeInlayParameterNameHints = "all",
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
            },
          },
        },
      },
    },
    config = function()
      -- Get capabilities from blink.cmp
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Configure default settings for all servers
      vim.lsp.config("*", {
        capabilities = capabilities,
        root_markers = { ".git" },
        on_attach = on_attach,
      })

      -- Apply server-specific configurations
      for server_name, config in pairs(servers) do
        vim.lsp.config(server_name, config)
      end

      -- Enable all configured servers
      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  -- Treesitter
  -- ══════════════════════════════════════════════════════════════════════════

  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
      { "<c-space>", desc = "Increment Selection" },
      { "<bs>",      desc = "Decrement Selection", mode = "x" },
    },
    opts = {
      ensure_installed = {
        "bash", "c", "cpp", "css", "diff", "go", "html",
        "javascript", "jsdoc", "json", "jsonc", "lua", "luadoc",
        "luap", "markdown", "markdown_inline", "printf", "python",
        "query", "regex", "rust", "toml", "tsx", "typescript",
        "vim", "vimdoc", "xml", "yaml", "zig",
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  -- Git
  -- ══════════════════════════════════════════════════════════════════════════

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function gmap(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
        end

        -- Navigation
        gmap("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next Hunk")

        gmap("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev Hunk")

        gmap("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
        gmap("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")

        -- Actions
        gmap("n", "<leader>hs", gs.stage_hunk, "Stage Hunk")
        gmap("n", "<leader>hr", gs.reset_hunk, "Reset Hunk")
        gmap("v", "<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage Hunk")
        gmap("v", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset Hunk")

        gmap("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
        gmap("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
        gmap("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
        gmap("n", "<leader>hp", gs.preview_hunk_inline, "Preview Hunk Inline")
        gmap("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame Line")
        gmap("n", "<leader>hB", function() gs.blame() end, "Blame Buffer")
        gmap("n", "<leader>hd", gs.diffthis, "Diff This")
        gmap("n", "<leader>hD", function() gs.diffthis("~") end, "Diff This ~")

        -- Text object
        gmap({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end,
    },
  },
}, {
  defaults = { lazy = true },
  checker = { enabled = false },
  change_detection = { notify = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
        "netrwPlugin", "rplugin",
      },
    },
  },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Better escape
map("i", "jj", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear highlights" })

-- Save/Quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>confirm q<CR>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>confirm qall<CR>", { desc = "Quit all" })

-- Better movement
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up" })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down" })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up" })

-- Move to window using <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase Window Width" })

-- Move Lines
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move Line Down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move Line Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<CR>==gi", { desc = "Move Line Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<CR>==gi", { desc = "Move Line Up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move Selection Down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move Selection Up" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<CR>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<CR>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<CR>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete Buffer" })

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Better search
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Diagnostic navigation using vim.diagnostic.jump (0.11+)
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next Diagnostic" })

map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev Diagnostic" })

map("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Next Error" })

map("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Prev Error" })

map("n", "]w", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN, float = true })
end, { desc = "Next Warning" })

map("n", "[w", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN, float = true })
end, { desc = "Prev Warning" })

-- Diagnostic
map("n", "<leader>xx", "<cmd>FzfLua diagnostics_document<CR>", { desc = "Document Diagnostics" })
map("n", "<leader>xX", "<cmd>FzfLua diagnostics_workspace<CR>", { desc = "Workspace Diagnostics" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Location List" })
map("n", "<leader>xq", vim.diagnostic.setqflist, { desc = "Quickfix List" })

-- Toggle options
map("n", "<leader>uf", function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify("Autoformat " .. (vim.g.autoformat and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Autoformat" })

map("n", "<leader>ud", function()
  local enabled = vim.diagnostic.is_enabled and vim.diagnostic.is_enabled() or true
  vim.diagnostic.enable(not enabled)
  vim.notify("Diagnostics " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
end, { desc = "Toggle Diagnostics" })

map("n", "<leader>us", function()
  local spell = vim.wo.spell
  vim.wo.spell = not spell
  vim.notify("Spell " .. (vim.wo.spell and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Spelling" })

map("n", "<leader>uw", function()
  local wrap = vim.wo.wrap
  vim.wo.wrap = not wrap
  vim.notify("Wrap " .. (vim.wo.wrap and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Line Wrap" })

map("n", "<leader>ul", function()
  local relativenumber = vim.wo.relativenumber
  vim.wo.relativenumber = not relativenumber
  vim.notify("Relative Numbers " .. (vim.wo.relativenumber and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Relative Line Numbers" })

if vim.lsp.inlay_hint then
  map("n", "<leader>uh", function()
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
    vim.notify("Inlay Hints " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
  end, { desc = "Toggle Inlay Hints" })
end

-- Utilities
map("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Lazy" })
map("n", "<leader>fn", "<cmd>enew<CR>", { desc = "New File" })

map("n", "<leader>fp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify('Copied "' .. path .. '"', vim.log.levels.INFO)
end, { desc = "Copy File Path" })

-- Shell command in split
map("n", "<leader>o", function()
  vim.ui.input({ prompt = "Shell command: " }, function(cmd)
    if not cmd or cmd == "" then return end

    vim.cmd("vnew")
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false

    local ok, output = pcall(vim.fn.systemlist, cmd)
    if ok then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
      vim.api.nvim_buf_set_name(buf, "Shell: " .. cmd)

      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
      vim.keymap.set("n", "r", function()
        local new_output = vim.fn.systemlist(cmd)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_output)
      end, { buffer = buf, desc = "Re-run command" })
    else
      vim.notify("Failed to run: " .. cmd, vim.log.levels.ERROR)
      vim.cmd("close")
    end
  end)
end, { desc = "Run Shell Command" })

-- Quickfix
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Highlight on yank
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})

-- Resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- Go to last loc when opening a buffer
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit", "gitrebase" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
      return
    end
    vim.b[buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = augroup("close_with_q"),
  pattern = {
    "help",
    "lspinfo",
    "notify",
    "qf",
    "query",
    "startuptime",
    "checkhealth",
    "man",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", {
      buffer = event.buf,
      silent = true,
      desc = "Quit buffer",
    })
  end,
})

-- Auto toggle hlsearch
local ns = vim.api.nvim_create_namespace("toggle_hlsearch")
vim.on_key(function(char)
  if vim.fn.mode() == "n" then
    local keys = { "<CR>", "n", "N", "*", "#", "?", "/" }
    local new_hlsearch = vim.tbl_contains(keys, vim.fn.keytrans(char))

    if vim.opt.hlsearch:get() ~= new_hlsearch then
      vim.opt.hlsearch = new_hlsearch
    end
  end
end, ns)

-- Auto-toggle cursorline in insert mode
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  group = augroup("auto_cursorline_show"),
  callback = function(event)
    if vim.bo[event.buf].buftype == "" then
      vim.opt_local.cursorline = true
    end
  end,
})

vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  group = augroup("auto_cursorline_hide"),
  callback = function()
    vim.opt_local.cursorline = false
  end,
})

-- Show recording status
vim.api.nvim_create_autocmd({ "RecordingEnter" }, {
  group = augroup("recording"),
  callback = function()
    vim.opt.cmdheight = 1
  end,
})

vim.api.nvim_create_autocmd({ "RecordingLeave" }, {
  group = augroup("recording"),
  callback = function()
    vim.defer_fn(function()
      vim.opt.cmdheight = 0
    end, 100)
  end,
})

-- Command abbreviations
vim.schedule(function()
  for _, abbrev in ipairs({
    { "W!", "w!" }, { "Q!", "q!" }, { "Qall!", "qall!" },
    { "Wq", "wq" }, { "Wa", "wa" }, { "wQ", "wq" },
    { "WQ", "wq" }, { "W", "w" }, { "Q", "q" }, { "Qall", "qall" },
  }) do
    vim.cmd.cnoreabbrev(abbrev[1], abbrev[2])
  end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FLASH JUMP (Enhanced f/F movement)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Cache namespace
local flash_ns = vim.api.nvim_create_namespace("flash_jump")

-- Setup custom highlight groups for flash jump
vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#000000", bg = "#ff007c", bold = true })
vim.api.nvim_set_hl(0, "FlashMatch", { fg = "#ff007c", bg = "#3b4261", bold = true })

local function flash_jump(opts)
  opts = opts or {}
  local backward = opts.backward or false
  local multiline = opts.multiline or false

  -- Clear any previous marks
  vim.api.nvim_buf_clear_namespace(0, flash_ns, 0, -1)

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  -- Get character to search
  local prompt = multiline and "Flash (all): " or (backward and "Flash ← : " or "Flash → : ")
  vim.api.nvim_echo({ { prompt, "Question" } }, false, {})

  local ok, char_nr = pcall(vim.fn.getchar)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})

  if not ok then return end

  local char = type(char_nr) == "number" and vim.fn.nr2char(char_nr) or char_nr
  if char == "\27" or char == "" then return end

  -- Find matches
  local matches = {}

  if multiline then
    -- Search visible lines
    local win_info = vim.fn.winsaveview()
    local top = win_info.topline - 1
    local height = vim.api.nvim_win_get_height(0)
    local bottom = math.min(top + height, vim.api.nvim_buf_line_count(0))
    local lines = vim.api.nvim_buf_get_lines(0, top, bottom, false)

    for line_idx, line_text in ipairs(lines) do
      local actual_row = top + line_idx - 1
      for i = 1, #line_text do
        if line_text:sub(i, i) == char then
          table.insert(matches, { actual_row, i - 1 })
        end
      end
    end
  else
    -- Search current line
    local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
    if not line or line == "" then return end

    local start_pos = backward and 1 or (col + 1)
    local end_pos = backward and col or #line

    for i = start_pos, end_pos do
      if line:sub(i, i) == char then
        if backward then
          table.insert(matches, 1, { row, i - 1 })
        else
          table.insert(matches, { row, i - 1 })
        end
      end
    end
  end

  if #matches == 0 then
    vim.notify("No matches found", vim.log.levels.WARN, { timeout = 500 })
    return
  end

  if #matches == 1 then
    vim.api.nvim_win_set_cursor(0, { matches[1][1] + 1, matches[1][2] })
    return
  end

  -- Show labels with background highlight
  local labels = multiline and "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" or "abcdefghijklmnopqrstuvwxyz"

  for i, match in ipairs(matches) do
    if i <= #labels then
      local label = labels:sub(i, i)

      -- Highlight the character position
      vim.api.nvim_buf_set_extmark(0, flash_ns, match[1], match[2], {
        end_col = match[2] + 1,
        hl_group = "FlashMatch",
        priority = 4096,
      })

      -- Add label overlay
      vim.api.nvim_buf_set_extmark(0, flash_ns, match[1], match[2], {
        virt_text = { { label, "FlashLabel" } },
        virt_text_pos = "overlay",
        priority = 4097,
      })
    end
  end

  -- Force redraw
  vim.cmd.redraw()

  -- Get selection
  vim.api.nvim_echo({ { "Select: ", "Question" } }, false, {})
  ok, char_nr = pcall(vim.fn.getchar)

  -- Clear highlights
  vim.api.nvim_buf_clear_namespace(0, flash_ns, 0, -1)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})

  if not ok then return end

  local selected = type(char_nr) == "number" and vim.fn.nr2char(char_nr) or char_nr
  if selected == "\27" or selected == "" then return end

  -- Jump to selection
  local idx = labels:find(selected, 1, true)
  if idx and idx <= #matches then
    vim.api.nvim_win_set_cursor(0, { matches[idx][1] + 1, matches[idx][2] })
  end
end

-- Keymaps
map("n", "f", function() flash_jump({ backward = false }) end, { desc = "Flash Forward" })
map("n", "F", function() flash_jump({ backward = true }) end, { desc = "Flash Backward" })
map("n", "s", function() flash_jump({ multiline = true }) end, { desc = "Flash (visible)" })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EXTENDED UI (Neovim 0.11+ experimental)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Enable modern extended UI features (experimental)
if vim._extui then
  pcall(function()
    vim._extui.enable({
      enable = true,
      msg = {
        target = "msg",
        timeout = 3000,
      },
    })
  end)
end
