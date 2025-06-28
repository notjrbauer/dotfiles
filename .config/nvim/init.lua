-- Modern Neovim 0.11+ Configuration
-- ~/.config/nvim/init.lua

-- Leader keys (must be set before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Prevent colorscheme flash
vim.cmd.colorscheme("habamax")

-- Defer command abbreviations until after startup
vim.schedule(function()
  local abbrevs = {
    { "W!",    "w!" },
    { "Q!",    "q!" },
    { "Qall!", "qall!" },
    { "Wq",    "wq" },
    { "Wa",    "wa" },
    { "wQ",    "wq" },
    { "WQ",    "wq" },
    { "W",     "w" },
    { "Q",     "q" },
    { "Qall",  "qall" },
  }

  for _, abbrev in ipairs(abbrevs) do
    vim.cmd.cnoreabbrev(abbrev[1], abbrev[2])
  end
end)


-- Disable built-in plugins for performance
vim.g.loaded_2html_plugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_logipat = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_matchit = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tutor = 1
vim.g.loaded_rplugin = 1
vim.g.loaded_syntax = 1
vim.g.loaded_synmenu = 1
vim.g.loaded_optwin = 1
vim.g.loaded_compiler = 1
vim.g.loaded_bugreport = 1
vim.g.loaded_ftplugin = 1

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

-- Core settings
local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes:1"
opt.colorcolumn = "100"
opt.cursorline = true
opt.laststatus = 3
opt.showmode = false
opt.cmdheight = 0
opt.pumheight = 15
opt.termguicolors = true

-- Editor behavior
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

-- Files and backups
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

-- Configure shada for session persistence
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

-- LSP server configurations
local servers = {
  lua_ls = {
    settings = {
      Lua = {
        completion = { callSnippet = "Replace" },
        diagnostics = { globals = { "vim", "capabilities" } },
        hint = { enable = false },
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" },
        },
        telemetry = { enable = false },
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

-- Utility functions
local function map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { silent = true }, opts or {}))
end

local function augroup(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Diagnostic configuration
vim.diagnostic.config({
  underline = false,
  update_in_insert = false,
  -- virtual_lines = { only_current_line = true },
  -- virtual_text = false,
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
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP: " .. desc }
  end
  -- vim.print(vim.inspect(client))
  -- vim.print(require("blink.cmp").get_lsp_capabilities())

  -- Enable inlay hints if supported
  if vim.lsp.inlay_hint and client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  -- Essential LSP keymaps
  map("n", "gd", "<cmd>FzfLua lsp_definitions<cr>", opts("Goto Definition"))
  map("n", "gr", "<cmd>FzfLua lsp_references<cr>", opts("References"))
  map("n", "gI", "<cmd>FzfLua lsp_implementations<cr>", opts("Goto Implementation"))
  map("n", "gy", "<cmd>FzfLua lsp_typedefs<cr>", opts("Goto Type Definition"))
  map("n", "gD", vim.lsp.buf.declaration, opts("Goto Declaration"))
  map("n", "K", vim.lsp.buf.hover, opts("Hover"))
  map("n", "gK", vim.lsp.buf.signature_help, opts("Signature Help"))
  map("i", "<c-k>", vim.lsp.buf.signature_help, opts("Signature Help"))
  map("n", "<leader>ca", "<cmd>FzfLua lsp_code_actions<cr>", opts("Code Action"))
  map("n", "<leader>cr", vim.lsp.buf.rename, opts("Rename"))

  -- Diagnostics
  map("n", "<leader>cd", vim.diagnostic.open_float, opts("Line Diagnostics"))

  -- Format on save
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end,
    })
  end

  -- Codelens
  if client.server_capabilities.codeLensProvider then
    vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
      buffer = bufnr,
      callback = vim.lsp.codelens.refresh,
    })
    vim.lsp.codelens.refresh()
  end
end

-- Plugin setup
require("lazy").setup({
  -- Theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      show_end_of_buffer = true,
      term_colors = true,
      integrations = {
        blink_cmp = true,
        fzf = true,
        mason = true,
        native_lsp = { enabled = true },
        treesitter = true,
        which_key = true,
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
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = function(ctx) return ctx.plugin and 0 or 100 end,
      spec = {
        { "<leader>c", group = "code" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
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

  -- Mason LSP Config
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { { "mason-org/mason.nvim", opts = {} }, "neovim/nvim-lspconfig" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = vim.tbl_keys(servers),
      automatic_installation = true,
    },
  },

  -- LSP setup using modern 0.11+ API
  {
    "neovim/nvim-lspconfig",
    dependencies = { "mason-org/mason-lspconfig.nvim", "saghen/blink.cmp" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Configure servers using vim.lsp.config
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      vim.lsp.config("*", {
        capabilities = capabilities,
        root_markers = { '.git' },
        on_attach = on_attach
      })

      for server_name, config in pairs(servers) do
        vim.lsp.config(server_name, config)
      end

      -- Simply enable all configured servers
      -- vim.lsp.enable() auto-starts based on filetypes in server config
      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },

  -- nvim-treesitter: Syntax Highlighting {{{2
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {},
    event = { "BufReadPost", "BufNewFile" },
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
          "make",
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
  -- Completion
  {
    "saghen/blink.cmp",
    lazy = false,
    dependencies = "rafamadriz/friendly-snippets",
    version = '1.*',
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
        menu = {
          draw = {
            treesitter = { "lsp" },
            columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
            components = {
              kind_icon = {
                text = function(ctx) return require("mini.icons").get("lsp", ctx.kind) end,
                highlight = function(ctx)
                  local _, hl = require("mini.icons").get("lsp", ctx.kind); return hl
                end,
              }
            }
          },
        },
        documentation = { auto_show = true },
        ghost_text = { enabled = true },
      },
    },
  },

  -- FZF
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    keys = {
      { "<leader><leader>", "<cmd>FzfLua files<cr>",                 desc = "Find Files" },
      { "<leader>/",        "<cmd>FzfLua live_grep<cr>",             desc = "Live Grep" },
      { "<leader>ff",       "<cmd>FzfLua files<cr>",                 desc = "Find Files" },
      { "<leader>fg",       "<cmd>FzfLua live_grep<cr>",             desc = "Live Grep" },
      { "<leader>fb",       "<cmd>FzfLua buffers<cr>",               desc = "Find Buffers" },
      { "<leader>fh",       "<cmd>FzfLua help_tags<cr>",             desc = "Help Tags" },
      { "<leader>fo",       "<cmd>FzfLua oldfiles<cr>",              desc = "Recent Files" },
      { "<leader>gs",       "<cmd>FzfLua git_status<cr>",            desc = "Git Status" },
      { "<leader>gc",       "<cmd>FzfLua git_commits<cr>",           desc = "Git Commits" },
      { "<leader>sw",       "<cmd>FzfLua grep_cword<cr>",            desc = "Search Word",          mode = "n" },
      { "<leader>sw",       "<cmd>FzfLua grep_visual<cr>",           desc = "Search Selection",     mode = "v" },
      { "<leader>xd",       "<cmd>FzfLua diagnostics_document<cr>",  desc = "Buffer Diagnostics" },
      { "<leader>xw",       "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Workspace Diagnostics" },
    },
    opts = {
      fzf_colors = true,
      fzf_opts = {
        ["--ansi"]           = true,
        ["--info"]           = "inline-right",
        ["--height"]         = "100%",
        ["--layout"]         = "reverse",
        ["--border"]         = "none",
        ["--highlight-line"] = true,
      },
      defaults = { formatter = "path.filename_first" },
      winopts = {
        preview = { border = "border", layout = "flex", flip_columns = 120 },
      },
      keymap = {
        builtin = {
          ["<C-u>"] = "preview-page-up",
          ["<C-d>"] = "preview-page-down",
        },
        fzf = {
          ["ctrl-u"] = "preview-page-up",
          ["ctrl-d"] = "preview-page-down",
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
    opts = {},
    lazy = true,
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
        "2html_plugin",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
})

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

-- Disable mouse wheel scrolling
-- for _, mode in ipairs({ "n", "i", "v" }) do
--   map(mode, "<ScrollWheelUp>", "<nop>")
--   map(mode, "<ScrollWheelDown>", "<nop>")
-- end

-- Essential autocmds
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function() vim.highlight.on_yank() end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

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
  callback = function()
    vim.opt.cmdheight = 1
  end,
})

vim.api.nvim_create_autocmd("RecordingLeave", {
  callback = function()
    vim.opt.cmdheight = 0
  end,
})

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

-- require('vim._extui').enable({
--   enable = true, -- Whether to enable or disable the UI.
--   msg = {        -- Options related to the message module.
--     ---@type 'cmd'|'msg' Where to place regular messages, either in the
--     ---cmdline or in a separate ephemeral message window.
--     target = 'msg',
--     timeout = 4000, -- Time a message is visible in the message window.
--   },
-- })
