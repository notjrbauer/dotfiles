-- Modern Neovim 0.11+ Configuration
-- ~/.config/nvim/init.lua

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- BOOTSTRAP & SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Leader keys (must be set before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Prevent colorscheme flash
vim.cmd.colorscheme("habamax")


-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
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
opt.mouse = "nvi"
opt.clipboard = "unnamedplus"
opt.completeopt = "menu,menuone,noinsert,noselect"
opt.conceallevel = 2
opt.confirm = true
opt.formatoptions = "jcroqlnt"
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.inccommand = "nosplit"
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.smoothscroll = true
opt.virtualedit = "block"
opt.winminwidth = 5
opt.wrap = true

-- Files and Backups
opt.autowrite = true
opt.backup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000
opt.undoreload = 10000
opt.writebackup = false

-- Ensure undo directory exists
local undodir = vim.fn.stdpath("data") .. "/undo"
if not vim.fn.isdirectory(undodir) then
  vim.fn.mkdir(undodir, "p")
end
opt.undodir = undodir
opt.shada = "'100,<50,s10,h,f1"

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

-- Timing
opt.timeout = true
opt.timeoutlen = 250
opt.updatetime = 100
opt.ttimeoutlen = 5

-- Scrolling
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Wildmenu
opt.wildmode = "longest:full,full"
opt.wildmenu = true
opt.wildoptions = "pum"
opt.wildignore:append({
  "*.o", "*.obj", "*.dylib", "*.bin", "*.dll", "*.exe",
  "*/.git/*", "*/.svn/*", "*/.DS_Store",
  "*/node_modules/*", "*/target/*", "*/.cargo/*"
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UTILITY FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { silent = true }, opts or {}))
end

local function augroup(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LSP CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- LSP server configurations
local servers = {
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim", "capabilities" } },
        runtime = { version = "LuaJIT" },
        hover = { expandAlias = false },
        type = {
          castNumberToInteger = true,
          inferParamType = true,
        },
        workspace = {
          checkThirdParty = false,
          library = {
            vim.env.VIMRUNTIME,
          },
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
        codeLens = {
          enable = false,
        },
      },
    },
  },
  gopls = {
    settings = {
      gopls = {
        gofumpt = true,
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          constantValues = true,
          parameterNames = true,
        },
        analyses = { unusedparams = true },
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
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
  marksman = { single_file_support = true },
}

-- Diagnostic configuration
vim.diagnostic.config({
  underline = false,
  update_in_insert = false,
  virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
  float = {
    source = true,
    border = 'rounded',
  },
})

-- LSP attach function
local function on_attach(client, bufnr)
  -- Enable inlay hints if supported
  if vim.lsp.inlay_hint and client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  -- Format on save
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end,
    })
  end

  -- Codelens
  --   if client.server_capabilities.codeLensProvider then
  --     vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
  --       buffer = bufnr,
  --       callback = vim.lsp.codelens.refresh,
  --     })
  --     vim.lsp.codelens.refresh()
  --   end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PLUGIN SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

require("lazy").setup({
  -- Theme
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

  -- Which-key
  {
    "folke/which-key.nvim",
    lazy = true,
    opts = {
      preset = "modern",
      delay = function(ctx) return ctx.plugin and 0 or 100 end,
      spec = {
        { "<leader>c", group = "code" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "git hunks" },
        { "<leader>q", group = "quit/session" },
        { "<leader>s", group = "search" },
        { "<leader>u", group = "ui" },
        { "<leader>w", group = "windows" },
        { "<leader>x", group = "diagnostics/quickfix" },
        { "[",         group = "prev" },
        { "]",         group = "next" },
        { "g",         group = "goto" },
        { "z",         group = "fold" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = true }) end, desc = "Buffer Keymaps" },
    },
  },

  -- Completion
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    dependencies = "rafamadriz/friendly-snippets",
    version = '*',
    opts = {
      keymap = {
        preset = "default",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide" },
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
        providers = { buffer = { max_items = 10 } },
      },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
          treesitter_highlighting = true,
          window = { border = "rounded" },
        },
        ghost_text = { enabled = true },
        menu = {
          border = "rounded",
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "kind_icon", "label", gap = 1 },
              { "kind" },
            },
            components = {
              kind_icon = {
                text = function(ctx)
                  local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                  return kind_icon
                end,
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                  return hl
                end,
              },
              kind = {
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                  return hl
                end,
              }
            }
          },
        },
      },
    },
  },

  -- Mason LSP Config
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = {
          ensure_installed = vim.tbl_keys(servers),
          automatic_installation = true,
        }
      },
      "saghen/blink.cmp",
      "neovim/nvim-lspconfig"
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      vim.lsp.config("*", {
        capabilities = capabilities,
        root_markers = { '.git' },
        on_attach = on_attach
      })

      for server_name, config in pairs(servers) do
        vim.lsp.config(server_name, config)
      end

      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },

  -- LSP setup using modern 0.11+ API
  -- {
  --   "neovim/nvim-lspconfig",
  --   dependencies = { "mason-org/mason-lspconfig.nvim",
  --   event = { "BufReadPre" },
  --   config = function()
  --     local capabilities = require("blink.cmp").get_lsp_capabilities()
  --
  --     vim.lsp.config("*", {
  --       capabilities = capabilities,
  --       root_markers = { '.git' },
  --       on_attach = on_attach
  --     })
  --
  --     for server_name, config in pairs(servers) do
  --       vim.lsp.config(server_name, config)
  --     end
  --
  --     vim.lsp.enable(vim.tbl_keys(servers))
  --   end,
  -- },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "VeryLazy",
    lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
    cmd = { "TSInstall", "TSUpdate", "TSInstallInfo", "TSEnable", "TSDisable", "TSModuleInfo", "TSUninstall" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "html", "javascript", "json", "lua", "make", "markdown", "markdown_inline",
          "python", "query", "regex", "tsx", "typescript", "vim", "yaml", "go", "css",
          "gitignore", "rust", "cpp", "c", "vimdoc",
        },
        sync_install = false,
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        indent = { enable = true },
      })
    end,
  },

  -- File Explorer
  {
    "stevearc/oil.nvim",
    event = "VeryLazy",
    dependencies = { "echasnovski/mini.icons" },
    cmd = "Oil",
    keys = {
      { "<leader>e",  "<cmd>Oil<cr>", desc = "Open File Explorer" },
      { "<leader>fe", "<cmd>Oil<cr>", desc = "Open File Explorer" },
    },
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      view_options = { show_hidden = true, natural_order = true },
      float = { padding = 2, max_width = 90, max_height = 0 },
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
        ["<C-h>"] = false, ["<C-l>"] = false, ["<C-k>"] = false, ["<C-j>"] = false,
      },
    },
  },

  -- Git Signs
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
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
        local function gmap(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- Navigation
        gmap("n", "]h", gs.next_hunk, "Next Hunk")
        gmap("n", "[h", gs.prev_hunk, "Prev Hunk")

        -- Actions
        gmap("n", "<leader>hs", gs.stage_hunk, "Stage Hunk")
        gmap("n", "<leader>hr", gs.reset_hunk, "Reset Hunk")
        gmap("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage Hunk")
        gmap("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset Hunk")
        gmap("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
        gmap("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
        gmap("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
        gmap("n", "<leader>hp", gs.preview_hunk, "Preview Hunk")
        gmap("n", "<leader>hd", gs.diffthis, "Diff This")
        gmap("n", "<leader>hD", function() gs.diffthis("~") end, "Diff This ~")
        gmap({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end,
    },
  },

  -- FZF
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    keys = {
      {
        'grr',
        function()
          require('fzf-lua').lsp_references()
        end,
        desc = 'Find LSP References',
      },
      {
        'gd',
        function()
          require('fzf-lua').lsp_definitions()
        end,
        desc = 'Goto Definition',
      },
      {
        'gI',
        function()
          require('fzf-lua').lsp_implementations()
        end,
        desc = 'Goto Implementation',
      },
      {
        '<leader>D',
        function()
          require('fzf-lua').lsp_typedefs()
        end,
        desc = 'Type Definition',
      },
      {
        '<leader>ds',
        function()
          require('fzf-lua').lsp_document_symbols()
        end,
        desc = 'Document Symbols',
      },
      {
        '<leader>ws',
        function()
          require('fzf-lua').lsp_live_workspace_symbols()
        end,
        desc = 'Workspace Symbols',
      },
      {
        '<leader>cr',
        vim.lsp.buf.rename,
        desc = 'Rename',
      },
      {
        '<leader>ca',
        vim.lsp.buf.code_action,
        desc = 'Code Action',
      },
      {
        'gD',
        vim.lsp.buf.declaration,
        desc = 'Goto Declaration',
      },
      {
        '<leader>fc',
        function()
          require('fzf-lua').files { cwd = vim.fn.stdpath 'config' }
        end,
        desc = 'Find in neovim configuration',
      },
      {
        '<leader>fh',
        function()
          require('fzf-lua').helptags()
        end,
        desc = '[F]ind [H]elp',
      },
      {
        '<leader>fk',
        function()
          require('fzf-lua').keymaps()
        end,
        desc = '[F]ind [K]eymaps',
      },
      {
        '<leader>fb',
        function()
          require('fzf-lua').builtin()
        end,
        desc = '[F]ind [B]uiltin FZF',
      },
      {
        '<leader>fw',
        function()
          require('fzf-lua').grep_cword()
        end,
        desc = '[F]ind current [W]ord',
      },
      {
        '<leader>fW',
        function()
          require('fzf-lua').grep_cWORD()
        end,
        desc = '[F]ind current [W]ORD',
      },
      {
        '<leader>fd',
        function()
          require('fzf-lua').diagnostics_document()
        end,
        desc = '[F]ind [D]iagnostics',
      },
      {
        '<leader>fr',
        function()
          require('fzf-lua').resume()
        end,
        desc = '[F]ind [R]esume',
      },
      {
        '<leader>fo',
        function()
          require('fzf-lua').oldfiles()
        end,
        desc = '[F]ind [O]ld Files',
      },
      {
        '<leader><leader>',
        function()
          require('fzf-lua').buffers()
        end,
        desc = '[,] Find existing buffers',
      },
      {
        '<leader>/',
        function()
          require('fzf-lua').lgrep_curbuf()
        end,
        desc = '[/] Live grep the current buffer',
      },
    },
    opts = {
      oldfiles = {
        -- In Telescope, when I used <leader>fr, it would load old buffers.
        -- fzf lua does the same, but by default buffers visited in the current
        -- session are not included. I use <leader>fr all the time to switch
        -- back to buffers I was just in. If you missed this from Telescope,
        -- give it a try.
        include_current_session = true,
      },
      previewers = {
        builtin = {
          syntax_limit_b = 1024 * 100, -- 100KB
        },
      },
      fzf_colors = true,
      fzf_opts = {
        ["--ansi"] = true,
        ["--info"] = "inline-right",
        ["--height"] = "100%",
        ["--layout"] = "reverse",
        ["--border"] = "none",
        ["--highlight-line"] = true,
      },
      defaults = { formatter = "path.filename_first" },
      winopts = { preview = { border = "border", layout = "flex", flip_columns = 120 } },
      keymap = {
        builtin = { ["<C-u>"] = "preview-page-up", ["<C-d>"] = "preview-page-down" },
        fzf = {
          -- use cltr-q to select all items and convert to quickfix list
          ["ctrl-q"] = "select-all+accept",
          ["ctrl-u"] = "preview-page-up",
          ["ctrl-d"] = "preview-page-down"
        },
      },
    },
    config = function(_, opts)
      require("fzf-lua").setup(opts)
      require("fzf-lua").register_ui_select()
    end,
  },

  -- Icons
  {
    "echasnovski/mini.icons",
    event = "VeryLazy",
    opts = {},
    specs = { { "nvim-tree/nvim-web-devicons", enabled = false, optional = true } },
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
}, {
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "man", "spellfile", "matchparen", "osc52", "shada", "2html_plugin", "tohtml",
        "getscript", "getscriptPlugin", "gzip", "logipat", "netrw", "netrwPlugin",
        "netrwSettings", "netrwFileHandlers", "matchit", "tar", "tarPlugin", "rrhelper",
        "spellfile_plugin", "vimball", "vimballPlugin", "zip", "zipPlugin", "tutor",
        "rplugin", "syntax", "synmenu", "optwin", "compiler", "bugreport", "ftplugin", "editorconfig",
      },
    },
  },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Essential keymaps
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear Search Highlights" })
map("i", "jj", "<ESC>", { desc = "Exit Insert Mode" })

-- File operations
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit All" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- Better movement
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window" })

-- Resize windows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

-- Better search
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")


-- Utilities
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>fp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy File Path" })

-- Toggle functions
map("n", "<leader>ud", function()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  vim.notify("Diagnostics " .. (enabled and "disabled" or "enabled"))
end, { desc = "Toggle Diagnostics" })

if vim.lsp.inlay_hint then
  map("n", "<leader>uh", function()
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
    vim.notify("Inlay hints " .. (enabled and "disabled" or "enabled"))
  end, { desc = "Toggle Inlay Hints" })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Defer command abbreviations until after startup
vim.schedule(function()
  local abbrevs = {
    { "W!", "w!" }, { "Q!", "q!" }, { "Qall!", "qall!" }, { "Wq", "wq" },
    { "Wa", "wa" }, { "wQ", "wq" }, { "WQ", "wq" }, { "W", "w" },
    { "Q", "q" }, { "Qall", "qall" },
  }
  for _, abbrev in ipairs(abbrevs) do
    vim.cmd.cnoreabbrev(abbrev[1], abbrev[2])
  end
end)

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function() vim.highlight.on_yank() end,
})

-- Resize splits when vim is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- Go to last location when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
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
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "lspinfo", "qf", "query", "startuptime", "checkhealth" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    map("n", "q", "<cmd>close<cr>", { buffer = event.buf })
  end,
})

-- Show recording status
vim.api.nvim_create_autocmd("RecordingEnter", {
  group = augroup("recording"),
  callback = function() vim.opt.cmdheight = 1 end,
})

vim.api.nvim_create_autocmd("RecordingLeave", {
  group = augroup("recording"),
  callback = function() vim.opt.cmdheight = 0 end,
})

-- LSP notifications
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup("lsp_attach_notify"),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      vim.notify(
        string.format("🚀 %s ready", client.name),
        vim.log.levels.INFO,
        { title = "LSP Server Started", timeout = 2000 }
      )
    end
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = augroup("lsp_detach_notify"),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      vim.lsp.stop_client(client.id, true)
      vim.notify(
        string.format("⚠️  %s disconnected", client.name),
        vim.log.levels.WARN,
        { title = "LSP Server Stopped", timeout = 1500 }
      )
    end
  end,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CUSTOM FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Flash jump functions for enhanced f/F movement
local function flash_jump()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
  if not line then return end

  vim.api.nvim_echo({ { "Flash: ", "Question" } }, false, {})
  local char_nr = vim.fn.getchar()
  local char = type(char_nr) == "string" and char_nr or vim.fn.nr2char(char_nr)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})

  if char == "\27" or char == "" then return end

  local matches = {}
  for i = col + 1, #line do
    if line:sub(i, i) == char then
      table.insert(matches, i - 1)
    end
  end

  if #matches == 0 then
    vim.notify("No matches found", vim.log.levels.WARN)
    return
  elseif #matches == 1 then
    vim.api.nvim_win_set_cursor(0, { row + 1, matches[1] })
    return
  end

  local ns_id = vim.api.nvim_create_namespace("flash_jump")
  local labels = "abcdefghijklmnopqrstuvwxyz"

  for i, match_col in ipairs(matches) do
    if i <= #labels then
      local label = labels:sub(i, i)
      vim.api.nvim_buf_set_extmark(0, ns_id, row, match_col, {
        virt_text = { { label, "IncSearch" } },
        virt_text_pos = "overlay",
        priority = 200,
      })
    end
  end

  vim.api.nvim_echo({ { "Select: ", "Question" } }, false, {})
  local label_nr = vim.fn.getchar()
  local selected_label = type(label_nr) == "string" and label_nr or vim.fn.nr2char(label_nr)

  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})

  if selected_label == "\27" or selected_label == "" then return end

  for i = 1, #labels do
    if labels:sub(i, i) == selected_label and i <= #matches then
      vim.api.nvim_win_set_cursor(0, { row + 1, matches[i] })
      break
    end
  end
end

local function flash_jump_backward()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
  if not line then return end

  vim.api.nvim_echo({ { "Flash backward: ", "Question" } }, false, {})
  local char_nr = vim.fn.getchar()
  local char = type(char_nr) == "string" and char_nr or vim.fn.nr2char(char_nr)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})

  if char == "\27" or char == "" then return end

  local matches = {}
  for i = 1, col do
    if line:sub(i, i) == char then
      table.insert(matches, 1, i - 1)
    end
  end

  if #matches == 0 then
    vim.notify("No matches found", vim.log.levels.WARN)
    return
  elseif #matches == 1 then
    vim.api.nvim_win_set_cursor(0, { row + 1, matches[1] })
    return
  end

  local ns_id = vim.api.nvim_create_namespace("flash_jump_backward")
  local labels = "abcdefghijklmnopqrstuvwxyz"

  for i, match_col in ipairs(matches) do
    if i <= #labels then
      local label = labels:sub(i, i)
      vim.api.nvim_buf_set_extmark(0, ns_id, row, match_col, {
        virt_text = { { label, "IncSearch" } },
        virt_text_pos = "overlay",
        priority = 200,
      })
    end
  end

  vim.api.nvim_echo({ { "Select: ", "Question" } }, false, {})
  local label_nr = vim.fn.getchar()
  local selected_label = type(label_nr) == "string" and label_nr or vim.fn.nr2char(label_nr)

  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})

  if selected_label == "\27" or selected_label == "" then return end

  for i = 1, #labels do
    if labels:sub(i, i) == selected_label and i <= #matches then
      vim.api.nvim_win_set_cursor(0, { row + 1, matches[i] })
      break
    end
  end
end

local function flash_jump_multiline()
  vim.api.nvim_echo({ { "Flash (multiline): ", "Question" } }, false, {})
  local char_nr = vim.fn.getchar()
  local char = type(char_nr) == "string" and char_nr or vim.fn.nr2char(char_nr)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})

  if char == "\27" or char == "" then return end

  local win_info = vim.fn.winsaveview()
  local top_line = win_info.topline - 1
  local bot_line = math.min(top_line + vim.api.nvim_win_get_height(0), vim.api.nvim_buf_line_count(0))
  local lines = vim.api.nvim_buf_get_lines(0, top_line, bot_line, false)
  local matches = {}

  for line_idx, line in ipairs(lines) do
    local actual_row = top_line + line_idx - 1
    for col = 1, #line do
      if line:sub(col, col) == char then
        table.insert(matches, { actual_row, col - 1 })
      end
    end
  end

  if #matches == 0 then
    vim.notify("No matches found", vim.log.levels.WARN)
    return
  elseif #matches == 1 then
    vim.api.nvim_win_set_cursor(0, { matches[1][1] + 1, matches[1][2] })
    return
  end

  local ns_id = vim.api.nvim_create_namespace("flash_jump_multiline")
  local labels = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  for i, match in ipairs(matches) do
    if i <= #labels then
      local label = labels:sub(i, i)
      vim.api.nvim_buf_set_extmark(0, ns_id, match[1], match[2], {
        virt_text = { { label, "IncSearch" } },
        virt_text_pos = "overlay",
        priority = 200,
      })
    end
  end

  vim.api.nvim_echo({ { "Select: ", "Question" } }, false, {})
  local label_nr = vim.fn.getchar()
  local selected_label = type(label_nr) == "string" and label_nr or vim.fn.nr2char(label_nr)

  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})

  if selected_label == "\27" or selected_label == "" then return end

  for i = 1, #labels do
    if labels:sub(i, i) == selected_label and i <= #matches then
      local target = matches[i]
      vim.api.nvim_win_set_cursor(0, { target[1] + 1, target[2] })
      break
    end
  end
end

-- Flash jump keymaps
map("n", "f", flash_jump, { desc = "Flash Jump Forward" })
map("n", "F", flash_jump_backward, { desc = "Flash Jump Backward" })
map("n", "<leader>s", flash_jump_multiline, { desc = "Flash Jump (Multiline)" })

-- Keep original f/F behavior available
map("n", "<leader>of", "f", { desc = "Original f" })
map("n", "<leader>oF", "F", { desc = "Original F" })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FINAL SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Enable modern UI
require('vim._extui').enable({
  enable = true,
  msg = { target = 'msg', timeout = 4000 },
})
