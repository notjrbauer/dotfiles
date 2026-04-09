-- Modern Neovim 0.12.2 Configuration
-- ~/.config/nvim/init.lua
--
-- ┌─ vim.pack (Neovim 0.12 built-in package manager) ──────────────────────────
-- │
-- │  vim.pack.add({ spec, spec, ... })
-- │    spec = { src = "https://full-url" }
-- │    spec = { src = "https://full-url", version = "branch-or-tag" }
-- │    spec = "https://full-url"   (string shorthand)
-- │
-- │  Rules:
-- │    • Full URLs required — use the gh() helper below for GitHub
-- │    • No lazy loading, no `config`, `deps`, `event`, `cmd`, `ft`, `keys`
-- │    • Plugins are available immediately after vim.pack.add() returns
-- │    • Configure every plugin with plain require() calls *after* vim.pack.add
-- │    • Entry order in the list = load order (put colorscheme first)
-- │    • Lock file written automatically — commit it for reproducibility
-- │
-- │  Operations:
-- │    vim.pack.update({})  — opens a buffer; :w to confirm updates
-- │    :restart             — in-process Neovim restart (new in 0.12)
-- └─────────────────────────────────────────────────────────────────────────────

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PERFORMANCE: Enable loader cache for faster startup
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.loader.enable()

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- BOOTSTRAP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- Disable legacy Vimscript built-ins before any plugin is loaded.
for _, p in ipairs({
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin",
  "getscript", "getscriptPlugin", "vimball", "vimballPlugin",
  "2html_plugin", "logiPat", "rrhelper",
  "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers",
}) do
  vim.g["loaded_" .. p] = 1
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CORE SETTINGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local opt          = vim.opt

-- UI
opt.number         = true
opt.relativenumber = true
opt.signcolumn     = "yes:1"
opt.cursorline     = true
opt.laststatus     = 3
opt.showmode       = false
opt.cmdheight      = 0
opt.pumheight      = 15
opt.termguicolors  = true
opt.winborder      = "rounded"

-- Editing
opt.mouse          = "a"
opt.clipboard      = "unnamedplus"
-- blink.cmp manages completeopt; set a sensible baseline.
-- Do NOT set vim.o.autocomplete = true — that enables native completion
-- which conflicts with blink.cmp.
opt.completeopt    = "menu,menuone,noinsert,noselect"
opt.conceallevel   = 2
opt.confirm        = true
opt.formatoptions  = "jcroqlnt"
opt.grepformat     = "%f:%l:%c:%m"
opt.grepprg        = "rg --vimgrep"
opt.inccommand     = "split"
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.smoothscroll = true
opt.virtualedit  = "block"
opt.winminwidth  = 5
opt.wrap         = false
opt.linebreak    = true

-- Files / undo
opt.autowrite    = true
opt.backup       = false
opt.swapfile     = false
opt.undofile     = true
opt.undolevels   = 10000
opt.writebackup  = false
-- 'shelltemp' now defaults to false in 0.12 — no need to set it explicitly.

do
  local d = vim.fn.stdpath("data") .. "/undo"
  if vim.fn.isdirectory(d) == 0 then vim.fn.mkdir(d, "p") end
  opt.undodir = d
end

-- Search
opt.ignorecase    = true
opt.smartcase     = true
opt.hlsearch      = true
opt.incsearch     = true

-- Indentation
opt.autoindent    = true
opt.smartindent   = true
opt.expandtab     = true
opt.shiftround    = true
opt.shiftwidth    = 2
opt.tabstop       = 2
opt.softtabstop   = 2

-- Splits
opt.splitbelow    = true
opt.splitright    = true
opt.splitkeep     = "screen"

-- Timeouts
opt.timeout       = true
opt.timeoutlen    = 300
opt.updatetime    = 200

-- Scrolling
opt.scrolloff     = 8
opt.sidescrolloff = 8

-- Wildmenu
opt.wildmode      = "longest:full,full"
opt.wildignore:append({
  "*.o", "*.obj", "*.dylib", "*.bin", "*.dll", "*.exe",
  "*/.git/*", "*/.svn/*", "*/.DS_Store",
  "*/node_modules/*", "*/target/*", "*/.cargo/*",
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UTILITY HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function augroup(name)
  return vim.api.nvim_create_augroup("config_" .. name, { clear = true })
end

-- Full GitHub URL helper — vim.pack requires complete URLs, not author/repo shorthands.
local gh = function(repo) return "https://github.com/" .. repo end
-- local cb = function(repo) return "https://codeberg.org/" .. repo end  -- if needed

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LSP: on-attach functions
-- Invoked by the LspAttach autocmd below; NOT stored in server config tables.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function on_attach(client, bufnr)
  -- Disable semantic tokens globally (re-enable per-server as desired).
  if client.server_capabilities.semanticTokensProvider then
    client.server_capabilities.semanticTokensProvider = nil
  end

  -- Format on save when the server supports document formatting.
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group    = augroup("lsp_fmt_" .. bufnr),
      buffer   = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 3000, async = false })
      end,
    })
  end
end

-- gopls: organise imports then format on every save.
-- Uses the 0.12 OOP client:request_sync() with a legacy fallback.
local function gopls_on_attach(client, bufnr)
  on_attach(client, bufnr)

  vim.api.nvim_create_autocmd("BufWritePre", {
    group    = augroup("gopls_fmt_" .. bufnr),
    buffer   = bufnr,
    callback = function()
      local params = vim.lsp.util.make_range_params(
        vim.api.nvim_get_current_win(),
        client.offset_encoding
      )
      params.context = { only = { "source.organizeImports" }, diagnostics = {} }

      -- Prefer 0.12 OOP client:request_sync(); fall back to the module API
      -- (vim.lsp.buf_request_sync is deprecated in 0.12 but still present).
      local result
      if type(client.request_sync) == "function" then
        result = client:request_sync("textDocument/codeAction", params, 1000, bufnr)
      else
        local all = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000) -- luacheck: ignore
        result    = all and all[client.id]
      end

      if result and result.result then
        for _, action in pairs(result.result) do
          -- 0.12: code actions support a `disabled` field; skip disabled actions.
          if action.edit and not action.disabled then
            vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
          end
        end
      end

      vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 3000, async = false })
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LSP: server-specific settings
-- `on_attach` is intentionally absent — dispatched via LspAttach autocmd below.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local servers = {
  lua_ls        = {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
        runtime     = { version = "LuaJIT" },
        workspace   = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
        telemetry   = { enable = false },
        hint        = {
          enable     = true,
          setType    = false,
          paramType  = true,
          paramName  = "Disable",
          semicolon  = "Disable",
          arrayIndex = "Disable",
        },
      },
    },
  },

  gopls         = {
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
        cargo       = { allFeatures = true },
        checkOnSave = { command = "clippy" },
        procMacro   = { enable = true },
      },
    },
  },

  clangd        = {
    cmd = {
      "clangd", "--background-index", "--clang-tidy",
      "--header-insertion=iwyu", "--completion-style=detailed",
      "--function-arg-placeholders",
    },
  },

  zls           = {},
  marksman      = {},
}

-- Diagnostic presentation.
-- 0.12 breaking change: diagnostic-signs can no longer be configured with
-- :sign-define. The signs.text table here is the correct and only way.
vim.diagnostic.config({
  underline        = true,
  update_in_insert = false,
  virtual_text     = { spacing = 4, source = "if_many", prefix = "●" },
  severity_sort    = true,
  signs            = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN]  = "",
      [vim.diagnostic.severity.HINT]  = " ",
      [vim.diagnostic.severity.INFO]  = " ",
    },
  },
  float            = { border = "rounded", source = true },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PACKAGE MANAGEMENT — vim.pack.add()
--
-- Single call; entry order is load order.
-- Colorscheme listed first so it is sourced before any other plugin renders.
--
-- vim.pack specs accept ONLY { src = "url" } and { src = "url", version = "..." }.
-- There are no config, deps, event, cmd, ft, keys, build, lazy, or priority
-- fields — those are lazy.nvim concepts that do not exist in vim.pack.
-- All plugin configuration happens below with plain require() calls.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.pack.add({
  -- UI / Appearance
  { src = gh("catppuccin/nvim") },
  { src = gh("echasnovski/mini.icons") },
  { src = gh("folke/which-key.nvim") },

  -- Navigation
  { src = gh("stevearc/oil.nvim") },
  { src = gh("ibhagwan/fzf-lua") },

  -- Completion
  { src = gh("rafamadriz/friendly-snippets") },
  { src = gh("saghen/blink.cmp"),                 version = "v1.10.2" },

  -- LSP tooling
  { src = gh("williamboman/mason.nvim") },
  { src = gh("williamboman/mason-lspconfig.nvim") },
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("nvim-lua/plenary.nvim") },
  { src = gh("pmizio/typescript-tools.nvim") },

  -- Treesitter — 'main' branch is more up-to-date than 'master'
  { src = gh("nvim-treesitter/nvim-treesitter"),  version = "main" },

  -- Git
  { src = gh("lewis6991/gitsigns.nvim") },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PLUGIN CONFIGURATION
-- Plain require() calls — vim.pack.add() is synchronous so everything is ready.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── 1. Colorscheme ────────────────────────────────────────────────────────────
-- Configure and apply before any other plugin renders UI elements.

require("catppuccin").setup({
  flavour                = "mocha",
  transparent_background = true,
  show_end_of_buffer     = true,
  term_colors            = true,
  integrations           = {
    blink_cmp  = true,
    fzf        = true,
    mason      = true,
    native_lsp = { enabled = true },
    treesitter = true,
    which_key  = true,
    gitsigns   = true,
  },
})
vim.cmd.colorscheme("catppuccin")

-- ── 2. mini.icons ─────────────────────────────────────────────────────────────
-- Set up before other plugins that call require("nvim-web-devicons").
-- mock_nvim_web_devicons() registers mini.icons as the nvim-web-devicons module
-- so any subsequent require("nvim-web-devicons") resolves to mini.icons.

require("mini.icons").setup({ style = "glyph" })
require("mini.icons").mock_nvim_web_devicons()

-- ── 3. which-key ─────────────────────────────────────────────────────────────

require("which-key").setup({
  preset = "modern",
  delay  = function(ctx) return ctx.plugin and 0 or 200 end,
  spec   = {
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
})

-- ── 4. oil.nvim ───────────────────────────────────────────────────────────────

require("oil").setup({
  default_file_explorer         = true,
  delete_to_trash               = true,
  skip_confirm_for_simple_edits = true,
  view_options                  = {
    show_hidden      = true,
    natural_order    = true,
    is_always_hidden = function(name)
      return name == ".." or name == ".git"
    end,
  },
  win_options                   = {
    wrap = false,
    signcolumn = "no",
    cursorcolumn = false,
    foldcolumn = "0",
    spell = false,
    list = false,
    conceallevel = 3,
    concealcursor = "nvic",
  },
  keymaps                       = {
    ["g?"]    = "actions.show_help",
    ["<CR>"]  = "actions.select",
    ["<C-v>"] = "actions.select_vsplit",
    ["<C-s>"] = "actions.select_split",
    ["<C-t>"] = "actions.select_tab",
    ["<C-p>"] = "actions.preview",
    ["<C-c>"] = "actions.close",
    ["<C-r>"] = "actions.refresh",
    ["-"]     = "actions.parent",
    ["_"]     = "actions.open_cwd",
    ["`"]     = "actions.cd",
    ["~"]     = "actions.tcd",
    ["gs"]    = "actions.change_sort",
    ["gx"]    = "actions.open_external",
    ["g."]    = "actions.toggle_hidden",
    ["g\\"]   = "actions.toggle_trash",
  },
})

-- ── 5. fzf-lua ────────────────────────────────────────────────────────────────

local fzf_actions = require("fzf-lua.actions")
require("fzf-lua").setup({
  fzf_colors = true,
  fzf_opts   = { ["--no-scrollbar"] = true, ["--info"] = "inline-right" },
  defaults   = { formatter = "path.filename_first" },
  previewers = { builtin = { syntax_limit_b = 1024 * 100 } },
  winopts    = {
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
  keymap     = {
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
  files      = {
    prompt = "Files❯ ",
    cwd_prompt = false,
    actions = { ["ctrl-g"] = fzf_actions.toggle_ignore }
  },
  grep       = {
    prompt = "Grep❯ ",
    rg_glob = true,
    actions = { ["ctrl-g"] = fzf_actions.toggle_ignore }
  },
  lsp        = { symbols = { symbol_style = 1 } },
  oldfiles   = { include_current_session = true },
})
require("fzf-lua").register_ui_select()

-- ── 6. blink.cmp ─────────────────────────────────────────────────────────────

require("blink.cmp").setup({
  keymap = {
    preset        = "default",
    ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-e>"]     = { "hide", "fallback" },
    ["<CR>"]      = { "accept", "fallback" },
    ["<Tab>"]     = { "snippet_forward", "select_next", "fallback" },
    ["<S-Tab>"]   = { "snippet_backward", "select_prev", "fallback" },
    ["<Up>"]      = { "select_prev", "fallback" },
    ["<Down>"]    = { "select_next", "fallback" },
    ["<C-p>"]     = { "select_prev", "fallback" },
    ["<C-n>"]     = { "select_next", "fallback" },
    ["<C-u>"]     = { "scroll_documentation_up", "fallback" },
    ["<C-d>"]     = { "scroll_documentation_down", "fallback" },
  },
  appearance = { use_nvim_cmp_as_default = true, nerd_font_variant = "mono" },
  sources = {
    default   = { "lsp", "path", "snippets", "buffer" },
    providers = { buffer = { max_items = 4, min_keyword_length = 4 } },
  },
  completion = {
    accept        = { auto_brackets = { enabled = true } },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
      treesitter_highlighting = true,
      window = { border = "rounded" },
    },
    ghost_text    = { enabled = true },
    menu          = {
      border = "rounded",
      draw   = {
        treesitter = { "lsp" },
        columns    = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } },
      },
    },
  },
  signature = { enabled = true, window = { border = "rounded" } },
})

-- ── 7. Mason ─────────────────────────────────────────────────────────────────

require("mason").setup({
  ui = {
    border = "rounded",
    icons  = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
  },
})

-- ── 8. mason-lspconfig ───────────────────────────────────────────────────────
-- Ensures the servers listed in the `servers` table are installed via Mason.

require("mason-lspconfig").setup({
  ensure_installed       = vim.tbl_keys(servers),
  automatic_installation = true,
})

-- ── 9. LspAttach autocmd ─────────────────────────────────────────────────────
-- Registered BEFORE vim.lsp.enable() so it fires when servers first attach.
-- Dispatches to the correct on_attach function by client name.

vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup("lsp_attach_dispatch"),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end
    if client.name == "gopls" then
      gopls_on_attach(client, args.buf)
    else
      on_attach(client, args.buf)
    end
  end,
})

-- ── 10. LSP server configuration and activation ───────────────────────────────
-- nvim-lspconfig is on rtp; blink.cmp is configured; wire them up.
--
-- 0.12 note: vim.lsp.config() and vim.lsp.enable() are native since 0.11.
-- Use :lsp to interactively inspect and manage running LSP clients (new in 0.12).

local capabilities = require("blink.cmp").get_lsp_capabilities()

-- Apply defaults to every server (on_attach handled by LspAttach autocmd above).
vim.lsp.config("*", {
  capabilities = capabilities,
  root_markers = { ".git" },
})

-- Apply server-specific settings from the servers table.
for name, cfg in pairs(servers) do
  vim.lsp.config(name, cfg)
end

-- Activate all servers; Mason has ensured they are installed.
vim.lsp.enable(vim.tbl_keys(servers))

-- ── 11. typescript-tools ─────────────────────────────────────────────────────
-- plenary.nvim is on rtp (added via vim.pack.add above).
-- on_attach is handled globally by the LspAttach autocmd.

require("typescript-tools").setup({
  settings = {
    tsserver_file_preferences = {
      includeInlayParameterNameHints         = "all",
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints          = true,
    },
  },
})

-- ── 12. nvim-treesitter ───────────────────────────────────────────────────────
-- Installed from the 'main' branch (more up-to-date than 'master').
-- Run :TSUpdate after first install to fetch compiled grammars.
--
-- 0.12 note: v_an / v_in are now native LSP incremental selection via
-- textDocument/selectionRange. The treesitter keymaps below (<C-space> / <bs>)
-- are distinct and complementary.

require("nvim-treesitter").setup({
  ensure_installed      = {
    "bash", "c", "cpp", "css", "diff", "go", "html",
    "javascript", "jsdoc", "json", "jsonc", "lua", "luadoc",
    "luap", "markdown", "markdown_inline", "printf", "python",
    "query", "regex", "rust", "toml", "tsx", "typescript",
    "vim", "vimdoc", "xml", "yaml", "zig",
  },
  auto_install          = true,
  highlight             = { enable = true, additional_vim_regex_highlighting = false },
  indent                = { enable = true },
  incremental_selection = {
    enable  = true,
    keymaps = {
      init_selection    = "<C-space>",
      node_incremental  = "<C-space>",
      scope_incremental = false,
      node_decremental  = "<bs>",
    },
  },
})

-- ── 13. gitsigns ─────────────────────────────────────────────────────────────

require("gitsigns").setup({
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
  on_attach = function(buf)
    local gs = package.loaded.gitsigns

    local function gmap(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = buf, desc = desc, silent = true })
    end

    gmap("n", "]h", function()
      if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
    end, "Next Hunk")
    gmap("n", "[h", function()
      if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
    end, "Prev Hunk")
    gmap("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
    gmap("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")

    gmap("n", "<leader>hs", gs.stage_hunk, "Stage Hunk")
    gmap("n", "<leader>hr", gs.reset_hunk, "Reset Hunk")
    gmap("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage Hunk")
    gmap("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset Hunk")

    gmap("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
    gmap("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
    gmap("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
    gmap("n", "<leader>hp", gs.preview_hunk_inline, "Preview Hunk Inline")
    gmap("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame Line")
    gmap("n", "<leader>hB", function() gs.blame() end, "Blame Buffer")
    gmap("n", "<leader>hd", gs.diffthis, "Diff This")
    gmap("n", "<leader>hD", function() gs.diffthis("~") end, "Diff This ~")

    gmap({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
  end,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Escape / search
map("i", "jj", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear highlights" })

-- Save / quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>confirm q<CR>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>confirm qall<CR>", { desc = "Quit all" })

-- Movement respecting soft-wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up" })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down" })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Window resize
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase Window Width" })

-- Move lines
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

-- Indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Search direction consistency
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Diagnostic navigation (vim.diagnostic.jump — stable since 0.11)
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next Diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev Diagnostic" })
map("n", "]e", function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true }) end,
  { desc = "Next Error" })
map("n", "[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true }) end,
  { desc = "Prev Error" })
map("n", "]w", function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN, float = true }) end,
  { desc = "Next Warning" })
map("n", "[w", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN, float = true }) end,
  { desc = "Prev Warning" })

-- Diagnostic lists
map("n", "<leader>xx", "<cmd>FzfLua diagnostics_document<CR>", { desc = "Document Diagnostics" })
map("n", "<leader>xX", "<cmd>FzfLua diagnostics_workspace<CR>", { desc = "Workspace Diagnostics" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Location List" })
map("n", "<leader>xq", vim.diagnostic.setqflist, { desc = "Quickfix List" })

-- Quickfix
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- LSP — fzf-lua wrappers
-- 0.12 adds default bindings: grt (type_definition), grx (codelens.run).
-- grr, grn, gra, gri were added in 0.11. We override some with fzf-lua below
-- to get a richer UI; the others fall through to the Neovim defaults.
map("n", "grr", function() require("fzf-lua").lsp_references() end, { desc = "LSP References" })
map("n", "gd", function() require("fzf-lua").lsp_definitions() end, { desc = "Goto Definition" })
map("n", "gI", function() require("fzf-lua").lsp_implementations() end, { desc = "Goto Implementation" })
map("n", "gy", function() require("fzf-lua").lsp_typedefs() end, { desc = "Goto Type Definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" })
map("n", "<leader>ds", function() require("fzf-lua").lsp_document_symbols() end, { desc = "Document Symbols" })
map("n", "<leader>ws", function() require("fzf-lua").lsp_live_workspace_symbols() end, { desc = "Workspace Symbols" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename" })
map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- fzf-lua: files, grep, misc
map("n", "<leader><leader>", function() require("fzf-lua").files() end, { desc = "Find Files" })
map("n", "<leader>ff", function() require("fzf-lua").files() end, { desc = "Find Files" })
map("n", "<leader>fc", function() require("fzf-lua").files({ cwd = vim.fn.stdpath("config") }) end,
  { desc = "Config Files" })
map("n", "<leader>fr", function() require("fzf-lua").oldfiles() end, { desc = "Recent Files" })
map("n", "<leader>sg", function() require("fzf-lua").live_grep() end, { desc = "Live Grep" })
map("n", "<leader>sw", function() require("fzf-lua").grep_cword() end, { desc = "Grep Word" })
map("n", "<leader>sW", function() require("fzf-lua").grep_cWORD() end, { desc = "Grep WORD" })
map("n", "<leader>sb", function() require("fzf-lua").lgrep_curbuf() end, { desc = "Grep Buffer" })
map("n", "<leader>ss", function() require("fzf-lua").builtin() end, { desc = "Search Select" })
map("n", "<leader>,", function() require("fzf-lua").buffers() end, { desc = "Buffers" })
map("n", "<leader>/", function() require("fzf-lua").lgrep_curbuf() end, { desc = "Grep Buffer" })
map("n", "<leader>fh", function() require("fzf-lua").helptags() end, { desc = "Help Tags" })
map("n", "<leader>fk", function() require("fzf-lua").keymaps() end, { desc = "Keymaps" })
map("n", "<leader>fd", function() require("fzf-lua").diagnostics_document() end, { desc = "Document Diagnostics" })
map("n", "<leader>fD", function() require("fzf-lua").diagnostics_workspace() end, { desc = "Workspace Diagnostics" })

-- oil.nvim
map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
map("n", "<leader>e", "<cmd>Oil<cr>", { desc = "File Explorer" })
map("n", "<leader>fe", "<cmd>Oil<cr>", { desc = "File Explorer" })

-- which-key
map("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Keymaps" })

-- Package management (vim.pack native)
map("n", "<leader>pu", function()
  vim.pack.update({})
end, { desc = "Update Packages" })

-- File utilities
map("n", "<leader>fn", "<cmd>enew<CR>", { desc = "New File" })
map("n", "<leader>fp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify('Copied "' .. path .. '"', vim.log.levels.INFO)
end, { desc = "Copy File Path" })

-- Toggle options
map("n", "<leader>uf", function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify("Autoformat " .. (vim.g.autoformat and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Autoformat" })

-- Diagnostic toggle.
-- 0.12 breaking change: vim.diagnostic.disable() is removed.
-- Use vim.diagnostic.enable(bool) exclusively.
-- vim.diagnostic.is_enabled() is stable in 0.12 (no fallback needed).
map("n", "<leader>ud", function()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  vim.notify("Diagnostics " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
end, { desc = "Toggle Diagnostics" })

map("n", "<leader>us", function()
  vim.wo.spell = not vim.wo.spell
  vim.notify("Spell " .. (vim.wo.spell and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Spelling" })

map("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify("Wrap " .. (vim.wo.wrap and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Line Wrap" })

map("n", "<leader>ul", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
  vim.notify("Relative Numbers " .. (vim.wo.relativenumber and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Relative Line Numbers" })

if vim.lsp.inlay_hint then
  map("n", "<leader>uh", function()
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
    vim.notify("Inlay Hints " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
  end, { desc = "Toggle Inlay Hints" })
end

-- Shell command in a scratch split
map("n", "<leader>o", function()
  vim.ui.input({ prompt = "Shell command: " }, function(cmd)
    if not cmd or cmd == "" then return end
    vim.cmd("vnew")
    local buf             = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype   = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile  = false
    local ok, output      = pcall(vim.fn.systemlist, cmd)
    if ok then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
      vim.api.nvim_buf_set_name(buf, "Shell: " .. cmd)
      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
      vim.keymap.set("n", "r", function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.systemlist(cmd))
      end, { buffer = buf, desc = "Re-run command" })
    else
      vim.notify("Failed to run: " .. cmd, vim.log.levels.ERROR)
      vim.cmd("close")
    end
  end)
end, { desc = "Run Shell Command" })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Highlight on yank.
-- vim.hl is the 0.12-preferred namespace; fall back to vim.highlight for safety.
vim.api.nvim_create_autocmd("TextYankPost", {
  group    = augroup("highlight_yank"),
  callback = function() (vim.hl or vim.highlight).on_yank({ timeout = 150 }) end,
})

-- Keep splits equal after terminal resize
vim.api.nvim_create_autocmd("VimResized", {
  group    = augroup("resize_splits"),
  callback = function()
    local t = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. t)
  end,
})

-- Return to last cursor position when reopening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group    = augroup("last_loc"),
  callback = function(ev)
    if vim.tbl_contains({ "gitcommit", "gitrebase" }, vim.bo[ev.buf].filetype)
        or vim.b[ev.buf].last_loc then
      return
    end
    vim.b[ev.buf].last_loc = true
    local mark             = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount           = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close auxiliary buffers with <q>
vim.api.nvim_create_autocmd("FileType", {
  group    = augroup("close_with_q"),
  pattern  = { "help", "lspinfo", "notify", "qf", "query", "startuptime", "checkhealth", "man" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true, desc = "Quit buffer" })
  end,
})

-- Auto-toggle hlsearch: on while searching, off otherwise
local hlns = vim.api.nvim_create_namespace("toggle_hlsearch")
vim.on_key(function(char)
  if vim.fn.mode() == "n" then
    local active = vim.tbl_contains({ "<CR>", "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
    if vim.opt.hlsearch:get() ~= active then vim.opt.hlsearch = active end
  end
end, hlns)

-- Cursorline: visible only in normal mode and the focused window
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  group    = augroup("cursorline_show"),
  callback = function(ev)
    if vim.bo[ev.buf].buftype == "" then vim.opt_local.cursorline = true end
  end,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  group    = augroup("cursorline_hide"),
  callback = function() vim.opt_local.cursorline = false end,
})

-- Show cmdline during macro recording (cmdheight is 0 otherwise)
vim.api.nvim_create_autocmd("RecordingEnter", {
  group    = augroup("macro_cmdheight"),
  callback = function() vim.opt.cmdheight = 1 end,
})
vim.api.nvim_create_autocmd("RecordingLeave", {
  group    = augroup("macro_cmdheight"),
  callback = function() vim.defer_fn(function() vim.opt.cmdheight = 0 end, 100) end,
})

-- Command-line abbreviations for common typos
vim.schedule(function()
  for _, ab in ipairs({
    { "W!", "w!" }, { "Q!", "q!" }, { "Qall!", "qall!" },
    { "Wq", "wq" }, { "Wa", "wa" }, { "wQ", "wq" },
    { "WQ",   "wq" }, { "W", "w" }, { "Q", "q" },
    { "Qall", "qall" },
  }) do
    vim.cmd.cnoreabbrev(ab[1], ab[2])
  end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FLASH JUMP  (zero-dependency f / F / s motion enhancement)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local flash_ns = vim.api.nvim_create_namespace("flash_jump")
vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#000000", bg = "#ff007c", bold = true })
vim.api.nvim_set_hl(0, "FlashMatch", { fg = "#ff007c", bg = "#3b4261", bold = true })

local function flash_jump(opts)
  opts            = opts or {}
  local backward  = opts.backward or false
  local multiline = opts.multiline or false

  vim.api.nvim_buf_clear_namespace(0, flash_ns, 0, -1)

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local prompt = multiline and "Flash (all): " or (backward and "Flash ← : " or "Flash → : ")
  vim.api.nvim_echo({ { prompt, "Question" } }, false, {})

  local ok, char_nr = pcall(vim.fn.getchar)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})
  if not ok then return end

  local char = type(char_nr) == "number" and vim.fn.nr2char(char_nr) or char_nr
  if char == "\27" or char == "" then return end

  local matches = {}

  if multiline then
    local info   = vim.fn.winsaveview()
    local top    = info.topline - 1
    local bottom = math.min(top + vim.api.nvim_win_get_height(0), vim.api.nvim_buf_line_count(0))
    for li, line in ipairs(vim.api.nvim_buf_get_lines(0, top, bottom, false)) do
      local arow = top + li - 1
      for i = 1, #line do
        if line:sub(i, i) == char then table.insert(matches, { arow, i - 1 }) end
      end
    end
  else
    local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
    if not line or line == "" then return end
    local s = backward and 1 or (col + 1)
    local e = backward and col or #line
    for i = s, e do
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

  local labels = multiline
      and "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
      or "abcdefghijklmnopqrstuvwxyz"

  for i, m in ipairs(matches) do
    if i <= #labels then
      local lbl = labels:sub(i, i)
      vim.api.nvim_buf_set_extmark(0, flash_ns, m[1], m[2],
        { end_col = m[2] + 1, hl_group = "FlashMatch", priority = 4096 })
      vim.api.nvim_buf_set_extmark(0, flash_ns, m[1], m[2],
        { virt_text = { { lbl, "FlashLabel" } }, virt_text_pos = "overlay", priority = 4097 })
    end
  end

  vim.cmd.redraw()
  vim.api.nvim_echo({ { "Select: ", "Question" } }, false, {})
  ok, char_nr = pcall(vim.fn.getchar)

  vim.api.nvim_buf_clear_namespace(0, flash_ns, 0, -1)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})
  if not ok then return end

  local sel = type(char_nr) == "number" and vim.fn.nr2char(char_nr) or char_nr
  if sel == "\27" or sel == "" then return end

  local idx = labels:find(sel, 1, true)
  if idx and idx <= #matches then
    vim.api.nvim_win_set_cursor(0, { matches[idx][1] + 1, matches[idx][2] })
  end
end

map("n", "f", function() flash_jump({ backward = false }) end, { desc = "Flash Forward" })
map("n", "F", function() flash_jump({ backward = true }) end, { desc = "Flash Backward" })
map("n", "s", function() flash_jump({ multiline = true }) end, { desc = "Flash (visible)" })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UI2  (Neovim 0.12 redesigned message / commandline UI)
--
-- Redesign of core messages and commandline UI. Replaces the legacy message
-- grid in the TUI. Removes "Press Enter" interruptions; highlights the command
-- line as you type; provides the pager as a buffer + window.
--
-- Still experimental in 0.12 — opt in with require('vim._core.ui2').enable().
-- Wrapped in pcall so an API rename in a future release doesn't break startup.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local parsersInstalled = require("nvim-treesitter").get_installed("parsers")
local treesitterStart = vim.api.nvim_create_augroup("treesitter-start-files", {})

for _, parser in pairs(parsersInstalled) do
  local filetypes = vim.treesitter.language.get_filetypes(parser)
  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = treesitterStart,
    pattern = filetypes,
    callback = function()
      vim.treesitter.start()
    end,
  })
end

pcall(function()
  require("vim._core.ui2").enable({})
end)
