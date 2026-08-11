-- Neovim 0.12+ init.lua
-- Built for a modern, low-bloat setup using vim.pack, native LSP, and a
-- small set of plugins that earn their keep.

vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.autoformat = true

-- Disable built-ins we do not use. netrw is disabled because oil.nvim replaces it.
for _, plugin in ipairs({
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "netrw",
  "netrwPlugin",
}) do
  vim.g["loaded_" .. plugin] = 1
end

local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.cursorlineopt = "number,line"
opt.termguicolors = true
opt.showmode = false
opt.laststatus = 3
opt.cmdheight = 0
opt.showcmdloc = "statusline"
opt.pumheight = 15
opt.pumborder = "rounded"
opt.pummaxwidth = 80
opt.winborder = "rounded"
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
}

-- Treesitter-driven folds (0.11+ native foldexpr; degrades to no folds for
-- buffers without a parser). foldlevelstart=99 keeps files open on load.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevelstart = 99

-- Render whitespace uniformly as dots: leading (indent) spaces AND tabs both show
-- as middle-dots so tab-indented files (Go, Makefiles) look the same as space-
-- indented ones; trailing whitespace gets a distinct mark. oil.nvim disables list
-- in its own win_options, so the file explorer stays clean. Inter-word spaces are
-- left blank via `lead` (not `space`).
opt.list = true
opt.listchars = {
  tab = "··",
  lead = "·",
  trail = "•",
  nbsp = "␣",
  extends = "›",
  precedes = "‹",
}

-- Editing / behavior
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.completeopt = "menu,menuone,noinsert,noselect,nearest"
opt.confirm = true
opt.formatoptions = "jcroqlnt"
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"
opt.inccommand = "split"
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.smoothscroll = true
opt.virtualedit = "block"
opt.wrap = false
opt.linebreak = true
opt.breakindent = true
opt.winminwidth = 5

-- Files / undo
opt.autowrite = true
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000

do
  local undodir = vim.fn.stdpath("data") .. "/undo"
  if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, "p")
  end
  opt.undodir = undodir
end

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

-- Indentation
opt.expandtab = true
opt.shiftround = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2

-- Splits / timing / scrolling
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"
opt.timeoutlen = 300
opt.updatetime = 200
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Cmdline completion / globbing
opt.wildmode = "longest:full,full"
opt.wildignore:append({
  "*.o",
  "*.obj",
  "*.a",
  "*.so",
  "*.dylib",
  "*.dll",
  "*.exe",
  "*/.git/*",
  "*/.svn/*",
  "*/.DS_Store",
  "*/node_modules/*",
  "*/target/*",
})

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function augroup(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

local function gh(repo)
  return "https://github.com/" .. repo
end

local function open_undotree()
  vim.cmd("packadd nvim.undotree")

  local ok, undotree = pcall(require, "undotree")
  if not ok then
    vim.notify("Built-in undotree is unavailable", vim.log.levels.ERROR)
    return
  end

  undotree.open()
end

local ts_languages = {
  "bash",
  "c",
  "cpp",
  "css",
  "diff",
  "go",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "printf",
  "python",
  "query",
  "regex",
  "rust",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
  "zig",
}

local function autoformat_enabled(bufnr)
  if vim.g.autoformat == false then
    return false
  end
  if vim.b[bufnr].autoformat == false then
    return false
  end
  return true
end

local function lsp_format(client, bufnr)
  if client:supports_method("textDocument/formatting") then
    vim.lsp.buf.format({ bufnr = bufnr, id = client.id, timeout_ms = 3000 })
  end
end

-- Run source.organizeImports code actions for `client` on `bufnr`.
--   opts.use_diagnostics : send current buffer diagnostics in the action context
--                          (gopls wants them; ruff sends none). Evaluated here,
--                          at format time, so diagnostics are never stale.
--   opts.run_commands    : also execute action.command (gopls needs it; ruff only
--                          applies the edit).
local function organize_imports(client, bufnr, opts)
  if not client:supports_method("textDocument/codeAction") then
    return
  end
  -- Params come from `bufnr`, never from the current window: make_range_params()
  -- resolves its first argument as a WINDOW (nvim_win_get_buf), so on `:wa` or
  -- `confirm qall` -- which write buffers that aren't on screen -- window 0 names
  -- the wrong document. source.* actions ignore the range, so an empty one is fine.
  local position = { line = 0, character = 0 }
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = { start = position, ["end"] = position },
  }
  params.context = {
    only = { "source.organizeImports" },
    diagnostics = opts.use_diagnostics and vim.diagnostic.get(bufnr) or {},
  }

  local resp = client:request_sync("textDocument/codeAction", params, 1000, bufnr)
  for _, action in ipairs((resp and resp.result) or {}) do
    if not action.disabled then
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      end
      if opts.run_commands and action.command then
        client:exec_cmd(action.command, { bufnr = bufnr })
      end
    end
  end
end

-- augroup() clears on every call, so it can't be used for a group that several
-- buffers register into. Cache one handle per server name instead; a per-buffer
-- group (the old approach) leaked an empty augroup for every buffer a server
-- ever attached to.
local format_groups = {}
local function format_augroup(name)
  local group = format_groups[name]
  if not group then
    group = vim.api.nvim_create_augroup("user_" .. name, { clear = true })
    format_groups[name] = group
  end
  return group
end

-- Register a BufWritePre formatter for `client` on `bufnr`.
--   opts.name     : augroup suffix (kept per-server so groups stay distinct)
--   opts.gate     : optional extra predicate(bufnr) that must pass to run
--   opts.organize : optional { use_diagnostics, run_commands } for organizeImports
local function register_format_on_save(client, bufnr, opts)
  local group = format_augroup(opts.name)
  -- Clear only THIS buffer's handler, preserving the reattach-dedup the old
  -- per-buffer group gave us without disturbing other buffers.
  vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    buffer = bufnr,
    callback = function()
      if not autoformat_enabled(bufnr) then
        return
      end
      if opts.gate and not opts.gate(bufnr) then
        return
      end
      if opts.organize then
        organize_imports(client, bufnr, opts.organize)
      end
      lsp_format(client, bufnr)
    end,
  })
end

local function setup_format_on_save(client, bufnr)
  -- gopls/ruff/typescript-tools are dispatched to their own handlers in
  -- LspAttach; this generic path only runs for everything else.
  if not client:supports_method("textDocument/formatting") then
    return
  end
  -- conform owns every filetype it has a formatter for (lua -> stylua, web ->
  -- prettier). Without this the server's own formatter would also fire on
  -- BufWritePre and the two would fight over the buffer -- lua_ls advertises
  -- documentFormattingProvider, so .stylua.toml would lose to EmmyLua's style.
  local ok, conform = pcall(require, "conform")
  if ok and #conform.list_formatters_for_buffer(bufnr) > 0 then
    return
  end
  register_format_on_save(client, bufnr, { name = "lsp_format_" .. client.name })
end

local function setup_gopls_on_save(client, bufnr)
  if
    not client:supports_method("textDocument/codeAction") and not client:supports_method("textDocument/formatting")
  then
    return
  end
  register_format_on_save(client, bufnr, {
    name = "gopls_format",
    organize = { use_diagnostics = true, run_commands = true },
  })
end

local function ruff_format_opted_in(bufnr)
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  if dir == "" then
    return false
  end

  local config = vim.fs.find({ "ruff.toml", ".ruff.toml", "pyproject.toml" }, {
    upward = true,
    path = dir,
    stop = vim.uv.os_homedir(),
  })[1]
  if not config then
    return false
  end

  local ok, lines = pcall(vim.fn.readfile, config)
  if not ok then
    return false
  end

  local is_pyproject = vim.fs.basename(config) == "pyproject.toml"
  local pattern = is_pyproject and "^%[tool%.ruff%.format%]" or "^%[format%]"

  for _, line in ipairs(lines) do
    if line:match(pattern) then
      return true
    end
  end
  return false
end

local function setup_ruff_on_save(client, bufnr)
  register_format_on_save(client, bufnr, {
    name = "ruff_format",
    gate = ruff_format_opted_in,
    organize = { use_diagnostics = false, run_commands = false },
  })
end

local servers = {
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = {
          checkThirdParty = false,
          library = {
            vim.env.VIMRUNTIME,
            vim.fn.stdpath("config"),
          },
        },
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
          shadow = true,
          unusedparams = true,
          unusedwrite = true,
          useany = true,
        },
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
        semanticTokens = true,
        directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
      },
    },
  },

  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        check = { command = "clippy" },
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

  pyright = {
    settings = {
      pyright = {
        -- ruff (below) owns import organization on save; drop pyright's
        -- duplicate "Organize Imports" code action.
        disableOrganizeImports = true,
      },
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          -- "openFilesOnly" keeps things fast on large projects; switch to
          -- "workspace" if you want whole-project diagnostics.
          diagnosticMode = "openFilesOnly",
          typeCheckingMode = "basic",
        },
      },
    },
  },

  ruff = {
    -- Let pyright own hover/docs; ruff focuses on lint + format + imports.
    on_attach = function(client)
      client.server_capabilities.hoverProvider = false
    end,
  },

  zls = {},
  marksman = {},
}

vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  virtual_text = { spacing = 2, source = "if_many", prefix = "●" },
  float = { source = true }, -- border inherits global winborder
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

vim.api.nvim_create_autocmd("PackChanged", {
  group = augroup("pack_treesitter_sync"),
  callback = function(ev)
    local data = ev.data or {}
    local spec = data.spec or {}

    if data.kind ~= "install" and data.kind ~= "update" then
      return
    end

    if spec.name ~= "nvim-treesitter" and spec.src ~= gh("nvim-treesitter/nvim-treesitter") then
      return
    end

    if not data.active then
      vim.cmd("packadd nvim-treesitter")
    end

    local ok, ts = pcall(require, "nvim-treesitter")
    if ok then
      -- update(), not install(): install() skips any language already on disk, so
      -- a plugin bump advanced the bundled queries while leaving the compiled
      -- parsers frozen. That skew is what broke the `diff` highlights query.
      ts.update(ts_languages)
    end
  end,
})

vim.pack.add({
  -- UI
  { src = gh("catppuccin/nvim") },
  { src = gh("echasnovski/mini.icons") },
  { src = gh("folke/which-key.nvim") },

  -- Navigation
  { src = gh("stevearc/oil.nvim") },
  { src = gh("ibhagwan/fzf-lua") },

  -- Completion
  { src = gh("rafamadriz/friendly-snippets") },
  -- stylua: ignore
  { src = gh("saghen/blink.cmp"),                version = vim.version.range("1.x") },

  -- LSP / tooling
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("nvim-lua/plenary.nvim") },
  { src = gh("pmizio/typescript-tools.nvim") },

  -- Formatting
  { src = gh("stevearc/conform.nvim") },

  -- Treesitter (main rewrite for Nvim 0.12+)
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },

  -- Git
  { src = gh("lewis6991/gitsigns.nvim") },
})

require("catppuccin").setup({
  flavour = "mocha",
  transparent_background = true,
  show_end_of_buffer = true,
  term_colors = true,
  integrations = {
    blink_cmp = true,
    fzf = true,
    gitsigns = true,
    native_lsp = { enabled = true },
    which_key = true,
  },
})
vim.cmd.colorscheme("catppuccin")

require("mini.icons").setup({ style = "glyph" })
require("mini.icons").mock_nvim_web_devicons()

local which_key = require("which-key")
which_key.setup({
  preset = "modern",
  delay = function(ctx)
    return ctx.plugin and 0 or 200
  end,
  spec = {
    { "<leader>c", group = "code" },
    { "<leader>f", group = "file/find" },
    { "<leader>h", group = "hunks" },
    { "<leader>s", group = "search" },
    { "<leader>u", group = "ui" },
    { "<leader>x", group = "diagnostics" },
    -- stylua: ignore start
    { "[",         group = "prev" },
    { "]",         group = "next" },
    { "g",         group = "goto" },
    { "z",         group = "fold" },
    -- stylua: ignore end
  },
})

require("oil").setup({
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
})

local fzf = require("fzf-lua")
local fzf_actions = require("fzf-lua.actions")

fzf.setup({
  fzf_colors = true,
  fzf_opts = {
    ["--no-scrollbar"] = true,
    ["--info"] = "inline-right",
  },
  defaults = { formatter = "path.filename_first" },
  previewers = { builtin = { syntax_limit_b = 1024 * 100 } },
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
    actions = { ["ctrl-g"] = fzf_actions.toggle_ignore },
  },
  grep = {
    prompt = "Grep❯ ",
    rg_glob = true,
    actions = { ["ctrl-g"] = fzf_actions.toggle_ignore },
  },
  lsp = { symbols = { symbol_style = 1 } },
  oldfiles = { include_current_session = true },
})
fzf.register_ui_select()

-- fzf-lua runs previews and actions through headless `nvim -l .../fzf-lua/rpc.lua`
-- workers, but *fzf* spawns them, not us, so we hold no job handle to stop them.
-- They block in a libuv loop with no signal handler (SIGTERM is ignored) and exit
-- only on EOF from this instance -- so anything still alive when we go away
-- reparents to PID 1 and lingers. Reap our own descendants on the way out.
-- Fires on :q, pane close (SIGHUP) and SIGTERM; a SIGKILL/crash still strays,
-- sweep those by hand with `pkill -9 -f 'fzf-lua/.*\.lua'`.
local function fzf_descendants(pid, acc)
  for _, child in ipairs(vim.api.nvim_get_proc_children(pid) or {}) do
    acc[#acc + 1] = child
    fzf_descendants(child, acc)
  end
  return acc
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = augroup("fzf_reap"),
  callback = function()
    local pids = fzf_descendants(vim.uv.os_getpid(), {})
    if #pids == 0 then
      return
    end
    local ps = { "ps", "-o", "pid=,command=", "-p", table.concat(pids, ",") }
    for _, line in ipairs(vim.fn.systemlist(ps)) do
      local pid, cmd = line:match("^%s*(%d+)%s+(.*)$")
      -- only ever touch processes whose argv names an fzf-lua script, so a
      -- nested `:terminal` nvim is never a candidate
      if pid and cmd:match("fzf%-lua/[a-z]+%.lua") then
        pcall(vim.uv.kill, tonumber(pid), 9)
      end
    end
  end,
})

local blink = require("blink.cmp")
blink.setup({
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
      buffer = { max_items = 4, min_keyword_length = 4 },
    },
  },
  completion = {
    accept = { auto_brackets = { enabled = true } },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
      treesitter_highlighting = true,
    },
    ghost_text = { enabled = true },
    menu = {
      draw = {
        treesitter = { "lsp" },
        columns = {
          { "kind_icon" },
          -- stylua: ignore
          { "label",    "label_description", gap = 1 },
          { "kind" },
        },
      },
    },
  },
  signature = { enabled = true }, -- window border inherits global winborder
})

-- LSP servers are installed to the system PATH (brew / go / rustup / uv / npm),
-- not via mason. nvim-lspconfig supplies the default cmd/root_markers/filetypes
-- from its lsp/ dir; we enable them explicitly with vim.lsp.enable() below.
-- Transient bottom-right popup announcing an LSP server loaded. Fired once per
-- server instance (deduped by client id in LspAttach below), not once per buffer.
-- Several stack upward and repack down as each closes itself after ~1.6s.
local lsp_toasts = {} -- active float handles, oldest first (bottom-most)

local function lsp_toast_relayout()
  for i, win in ipairs(lsp_toasts) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      cfg.row = math.max(1, vim.o.lines - vim.o.cmdheight - 2 - ((i - 1) * 3))
      vim.api.nvim_win_set_config(win, cfg)
    end
  end
end

local function notify_lsp_loaded(name)
  local text = " ● " .. name .. " loaded "
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  vim.bo[buf].bufhidden = "wipe"

  local ok, win = pcall(vim.api.nvim_open_win, buf, false, {
    relative = "editor",
    anchor = "SE",
    row = math.max(1, vim.o.lines - vim.o.cmdheight - 2),
    col = vim.o.columns - 1,
    width = vim.fn.strdisplaywidth(text),
    height = 1,
    style = "minimal",
    border = "rounded",
    focusable = false,
    noautocmd = true,
    zindex = 200,
  })
  if not ok then
    return
  end

  vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:DiagnosticOk"
  vim.wo[win].winblend = 10
  table.insert(lsp_toasts, win)
  lsp_toast_relayout()

  vim.defer_fn(function()
    pcall(vim.api.nvim_win_close, win, true)
    for i, w in ipairs(lsp_toasts) do
      if w == win then
        table.remove(lsp_toasts, i)
        break
      end
    end
    lsp_toast_relayout()
  end, 1600)
end

local lsp_toast_seen = {} -- client ids already announced this session
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup("lsp_attach"),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))

    -- One toast per server instance (a restart gets a fresh id -> re-announces).
    if not lsp_toast_seen[ev.data.client_id] then
      lsp_toast_seen[ev.data.client_id] = true
      notify_lsp_loaded(client.name)
    end

    if client.name == "gopls" then
      setup_gopls_on_save(client, ev.buf)
    elseif client.name == "ruff" then
      setup_ruff_on_save(client, ev.buf)
    elseif client.name == "typescript-tools" then
    -- conform (Prettier) owns TS/JS formatting; never let tsserver format on
    -- save, since it ignores .prettierrc and reformats the whole buffer.
    else
      setup_format_on_save(client, ev.buf)
    end
  end,
})

local capabilities = blink.get_lsp_capabilities()
vim.lsp.config("*", {
  capabilities = capabilities,
})

for name, cfg in pairs(servers) do
  vim.lsp.config(name, cfg)
end
vim.lsp.enable(vim.tbl_keys(servers))

require("typescript-tools").setup({
  settings = {
    tsserver_file_preferences = {
      includeInlayParameterNameHints = "all",
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = true,
    },
  },
})

-- Prettier (via conform) owns web/JS/TS formatting so on-save diffs match the
-- project's own .prettierrc instead of tsserver's built-in style. Prettier only
-- runs when the project actually configures it (require_cwd + a prettier config
-- file), so repos without Prettier are never reformatted. It also prefers the
-- project-local node_modules/.bin/prettier, matching the repo's exact version.
local conform = require("conform")
local conform_util = require("conform.util")

local prettier_root = conform_util.root_file({
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.yml",
  ".prettierrc.yaml",
  ".prettierrc.json5",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  ".prettierrc.ts",
  ".prettierrc.toml",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
  "prettier.config.ts",
})

local prettier = { "prettierd", "prettier", stop_after_first = true }

conform.setup({
  formatters = {
    prettierd = { require_cwd = true, cwd = prettier_root },
    prettier = { require_cwd = true, cwd = prettier_root },
  },
  formatters_by_ft = {
    -- stylua reads the repo's .stylua.toml; lua_ls's built-in formatter does not,
    -- so conform owns lua and setup_format_on_save stands down for it.
    lua = { "stylua" },
    javascript = prettier,
    javascriptreact = prettier,
    typescript = prettier,
    typescriptreact = prettier,
    json = prettier,
    jsonc = prettier,
    css = prettier,
    scss = prettier,
    html = prettier,
    yaml = prettier,
    markdown = prettier,
    graphql = prettier,
  },
  format_on_save = function(bufnr)
    if not autoformat_enabled(bufnr) then
      return
    end
    return { timeout_ms = 3000, lsp_format = "never" }
  end,
})

local ts = require("nvim-treesitter")
ts.setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})
-- Only install parsers that are actually missing, so warm starts don't schedule
-- install work every launch. New parsers on plugin update are handled by the
-- PackChanged handler above.
do
  local installed = {}
  for _, lang in ipairs(ts.get_installed()) do
    installed[lang] = true
  end
  local missing = vim.tbl_filter(function(lang)
    return not installed[lang]
  end, ts_languages)
  if #missing > 0 then
    ts.install(missing)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("treesitter_start"),
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    local lang = vim.treesitter.language.get_lang(ft)
    if not lang then
      return
    end

    local ok = vim.treesitter.language.add(lang)
    if not ok then
      return
    end

    pcall(vim.treesitter.start, ev.buf, lang)
    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

require("gitsigns").setup({
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },
  signs_staged = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
  },
  on_attach = function(bufnr)
    local gs = require("gitsigns")

    local function gmap(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
    end

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

    gmap("n", "]H", function()
      gs.nav_hunk("last")
    end, "Last Hunk")
    gmap("n", "[H", function()
      gs.nav_hunk("first")
    end, "First Hunk")

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
    -- stage_hunk is a toggle now: on a staged hunk it unstages (replaces the
    -- deprecated undo_stage_hunk).
    gmap("n", "<leader>hu", gs.stage_hunk, "Unstage Hunk (toggle)")
    gmap("n", "<leader>hp", gs.preview_hunk_inline, "Preview Hunk Inline")
    gmap("n", "<leader>hb", function()
      gs.blame_line({ full = true })
    end, "Blame Line")
    gmap("n", "<leader>hB", gs.blame, "Blame Buffer")
    gmap("n", "<leader>hd", gs.diffthis, "Diff This")
    gmap("n", "<leader>hD", function()
      gs.diffthis("~")
    end, "Diff This ~")

    gmap({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Git Hunk")
  end,
})

local function diagnostic_jump(count, severity)
  return function()
    vim.diagnostic.jump({
      count = count,
      severity = severity,
      on_jump = function(diagnostic, bufnr)
        if not diagnostic then
          return
        end
        vim.diagnostic.open_float({
          bufnr = bufnr,
          scope = "line",
          source = "if_many",
          focus = false,
        })
      end,
    })
  end
end

-- Escape / search
map("i", "jj", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Save / quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>confirm q<CR>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>confirm qall<CR>", { desc = "Quit all" })

-- Movement respecting wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up" })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down" })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up" })

-- Windows. C-hjkl moves between nvim windows and, at an edge, hops to the
-- adjacent tmux pane (plugin-free vim-tmux-navigator: .tmux.conf forwards
-- C-hjkl into nvim when it's focused, so nvim must hand back off at edges).
local function win_or_tmux(dir, tmux_flag)
  return function()
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(dir)
    if vim.api.nvim_get_current_win() == win and vim.env.TMUX then
      vim.system({ "tmux", "select-pane", tmux_flag })
    end
  end
end
map("n", "<C-h>", win_or_tmux("h", "-L"), { desc = "Go to Left Window / tmux pane" })
map("n", "<C-j>", win_or_tmux("j", "-D"), { desc = "Go to Lower Window / tmux pane" })
map("n", "<C-k>", win_or_tmux("k", "-U"), { desc = "Go to Upper Window / tmux pane" })
map("n", "<C-l>", win_or_tmux("l", "-R"), { desc = "Go to Right Window / tmux pane" })
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
map("n", "<leader>bb", "<cmd>e #<CR>", { desc = "Other Buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete Buffer" })

-- Visual indent stay selected
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Search direction consistency
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Diagnostics
map("n", "]d", diagnostic_jump(1), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_jump(-1), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_jump(1, vim.diagnostic.severity.ERROR), { desc = "Next Error" })
map("n", "[e", diagnostic_jump(-1, vim.diagnostic.severity.ERROR), { desc = "Prev Error" })
map("n", "]w", diagnostic_jump(1, vim.diagnostic.severity.WARN), { desc = "Next Warning" })
map("n", "[w", diagnostic_jump(-1, vim.diagnostic.severity.WARN), { desc = "Prev Warning" })
map("n", "<leader>xx", fzf.diagnostics_document, { desc = "Document Diagnostics" })
map("n", "<leader>xX", fzf.diagnostics_workspace, { desc = "Workspace Diagnostics" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Location List" })
map("n", "<leader>xq", vim.diagnostic.setqflist, { desc = "Quickfix List" })

-- Quickfix
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- LSP / symbols — align with Neovim's native gr* namespace (0.11+) so there's a
-- single convention; the fzf pickers back the native keys (gri/grt/gO) instead
-- of living under parallel aliases (gI/gy/<leader>ds).
map("n", "grr", fzf.lsp_references, { desc = "LSP References" })
map("n", "gri", fzf.lsp_implementations, { desc = "LSP Implementations" })
map("n", "grt", fzf.lsp_typedefs, { desc = "LSP Type Definitions" })
map("n", "gO", fzf.lsp_document_symbols, { desc = "Document Symbols" })
map("n", "gd", fzf.lsp_definitions, { desc = "Goto Definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" })
map("n", "<leader>ws", fzf.lsp_live_workspace_symbols, { desc = "Workspace Symbols" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename" })
map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
map({ "n", "v" }, "<leader>cf", function()
  conform.format({ async = false, lsp_format = "fallback" })
end, { desc = "Format Buffer" })

-- Files / grep / picker
map("n", "<leader><leader>", fzf.files, { desc = "Find Files" })
map("n", "<leader>ff", fzf.files, { desc = "Find Files" })
map("n", "<leader>fc", function()
  fzf.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Config Files" })
map("n", "<leader>fr", fzf.oldfiles, { desc = "Recent Files" })
map("n", "<leader>sg", fzf.live_grep, { desc = "Live Grep" })
map("n", "<leader>sw", fzf.grep_cword, { desc = "Grep Word" })
map("n", "<leader>sW", fzf.grep_cWORD, { desc = "Grep WORD" })
map("n", "<leader>sb", fzf.lgrep_curbuf, { desc = "Grep Buffer" })
map("n", "<leader>ss", fzf.builtin, { desc = "Search Select" })
map("n", "<leader>,", fzf.buffers, { desc = "Buffers" })
map("n", "<leader>/", fzf.lgrep_curbuf, { desc = "Grep Buffer" })
map("n", "<leader>fh", fzf.helptags, { desc = "Help Tags" })
map("n", "<leader>fk", fzf.keymaps, { desc = "Keymaps" })
map("n", "<leader>fd", fzf.diagnostics_document, { desc = "Document Diagnostics" })
map("n", "<leader>fD", fzf.diagnostics_workspace, { desc = "Workspace Diagnostics" })

-- File explorer
map("n", "-", "<cmd>Oil<CR>", { desc = "Open Parent Directory" })
map("n", "<leader>e", "<cmd>Oil<CR>", { desc = "File Explorer" })
map("n", "<leader>fe", "<cmd>Oil<CR>", { desc = "File Explorer" })

-- which-key helper
map("n", "<leader>?", function()
  which_key.show({ global = false })
end, { desc = "Buffer Keymaps" })

-- Packages
map("n", "<leader>pu", function()
  -- No argument = all plugins; an empty list would filter to zero plugins.
  vim.pack.update()
end, { desc = "Update Packages" })

-- File helpers
map("n", "<leader>fn", "<cmd>enew<CR>", { desc = "New File" })
map("n", "<leader>uu", open_undotree, { desc = "Undo Tree" })
map("n", "<leader>fp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify('Copied "' .. path .. '"', vim.log.levels.INFO)
end, { desc = "Copy File Path" })

-- :Retab — convert the current buffer's tabs to spaces (expandtab + retab).
-- Guarded: refuses on filetypes where literal tabs are required (Go, Makefiles),
-- since converting those corrupts the file. Manual only — never automatic.
vim.api.nvim_create_user_command("Retab", function()
  local tab_required = { go = true, gomod = true, gowork = true, make = true }
  local ft = vim.bo.filetype
  if tab_required[ft] then
    vim.notify(("Retab skipped: %s requires literal tabs"):format(ft), vim.log.levels.WARN)
    return
  end
  local view = vim.fn.winsaveview()
  vim.bo.expandtab = true
  vim.cmd("retab")
  vim.fn.winrestview(view)
  vim.notify("Converted tabs to spaces", vim.log.levels.INFO)
end, { desc = "Convert buffer tabs to spaces (guarded)" })

-- Toggles
map("n", "<leader>uf", function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify("Autoformat " .. (vim.g.autoformat and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Autoformat" })

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
end, { desc = "Toggle Wrap" })

map("n", "<leader>ul", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
  vim.notify("Relative Numbers " .. (vim.wo.relativenumber and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle Relative Numbers" })

map("n", "<leader>uh", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
  vim.notify("Inlay Hints " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
end, { desc = "Toggle Inlay Hints" })

local function set_scratch_lines(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function run_shell_command(buf, cmd)
  local output = vim.fn.systemlist(cmd)
  local exit_code = vim.v.shell_error

  if vim.tbl_isempty(output) then
    output = { "" }
  end

  set_scratch_lines(buf, output)

  if exit_code ~= 0 then
    vim.notify(string.format("Command failed (%d): %s", exit_code, cmd), vim.log.levels.WARN)
  end
end

-- Shell command scratch buffer
map("n", "<leader>o", function()
  vim.ui.input({ prompt = "Shell command: " }, function(cmd)
    if not cmd or cmd == "" then
      return
    end

    vim.cmd("vnew")
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buflisted = false
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "log"

    vim.api.nvim_buf_set_name(buf, "[Shell] " .. cmd)
    run_shell_command(buf, cmd)

    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true, desc = "Quit buffer" })
    vim.keymap.set("n", "r", function()
      run_shell_command(buf, cmd)
    end, { buffer = buf, desc = "Re-run command" })
  end)
end, { desc = "Run Shell Command" })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- Keep splits balanced after terminal resize
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd.tabnext(current_tab)
  end,
})

-- Restore cursor position on reopen
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_location"),
  callback = function(ev)
    if vim.tbl_contains({ "gitcommit", "gitrebase" }, vim.bo[ev.buf].filetype) or vim.b[ev.buf].last_loc then
      return
    end

    vim.b[ev.buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close auxiliary buffers with q
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "lspinfo", "notify", "qf", "query", "startuptime", "checkhealth", "man" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true, desc = "Quit buffer" })
  end,
})

-- Toggle hlsearch only while actively searching
local hlsearch_keys = {
  ["<CR>"] = true,
  ["n"] = true,
  ["N"] = true,
  ["*"] = true,
  ["#"] = true,
  ["?"] = true,
  ["/"] = true,
}

local hlsearch_ns = vim.api.nvim_create_namespace("toggle_hlsearch")
vim.on_key(function(char)
  if vim.fn.mode() ~= "n" then
    return
  end

  local active = hlsearch_keys[vim.fn.keytrans(char)] == true
  -- scalar accessor: this runs on every keystroke, avoid building an Option obj
  if vim.o.hlsearch ~= active then
    vim.o.hlsearch = active
  end
end, hlsearch_ns)

-- Cursorline only in normal mode and focused windows
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  group = augroup("cursorline_on"),
  callback = function(ev)
    if vim.bo[ev.buf].buftype == "" then
      vim.wo.cursorline = true
    end
  end,
})

vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  group = augroup("cursorline_off"),
  callback = function()
    vim.wo.cursorline = false
  end,
})

-- Show command line while recording macros (cmdheight is 0 otherwise).
-- Both autocmds must share ONE group handle: augroup() clears on each call, so
-- calling it twice with the same name would delete the RecordingEnter autocmd.
local macro_group = augroup("macro_cmdheight")
vim.api.nvim_create_autocmd("RecordingEnter", {
  group = macro_group,
  callback = function()
    vim.opt.cmdheight = 1
  end,
})

vim.api.nvim_create_autocmd("RecordingLeave", {
  group = macro_group,
  callback = function()
    vim.defer_fn(function()
      vim.opt.cmdheight = 0
    end, 100)
  end,
})

-- Command-line abbreviations for common typos
vim.schedule(function()
  for _, abbr in ipairs({
    -- stylua: ignore start
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
    -- stylua: ignore end
  }) do
    vim.cmd.cnoreabbrev(abbr[1], abbr[2])
  end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FLASH JUMP  (zero-dependency f / F / s motion enhancement)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local flash_ns = vim.api.nvim_create_namespace("flash_jump")
local flash_labels_line = "abcdefghijklmnopqrstuvwxyz"
local flash_labels_multi = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local flash_esc = "\27"

-- :colorscheme clears every highlight group, so setting these once at startup
-- left the labels invisible after any theme reload (including re-running our own).
local function flash_set_hl()
  vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#000000", bg = "#ff007c", bold = true })
  vim.api.nvim_set_hl(0, "FlashMatch", { fg = "#ff007c", bg = "#3b4261", bold = true })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup("flash_highlights"),
  callback = flash_set_hl,
})
flash_set_hl()

local function flash_clear(bufnr)
  bufnr = bufnr or 0
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, flash_ns, 0, -1)
end

local function flash_jump(opts)
  opts = opts or {}
  local backward = opts.backward or false
  local multiline = opts.multiline or false

  flash_clear(0)

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local prompt = multiline and "Flash (all): " or (backward and "Flash ← : " or "Flash → : ")
  vim.api.nvim_echo({ { prompt, "Question" } }, false, {})

  local ok, char = pcall(vim.fn.getcharstr)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})
  if not ok then
    flash_clear(0)
    return
  end

  if char == flash_esc or char == "" then
    flash_clear(0)
    return
  end

  if not multiline then
    vim.fn.setcharsearch({
      char = char,
      forward = backward and 0 or 1,
      ["until"] = 0,
    })
  end

  local matches = {}

  if multiline then
    local view = vim.fn.winsaveview()
    local top = view.topline - 1
    local bottom = math.min(top + vim.api.nvim_win_get_height(0), vim.api.nvim_buf_line_count(0))

    for li, line in ipairs(vim.api.nvim_buf_get_lines(0, top, bottom, false)) do
      local arow = top + li - 1
      -- plain find, not byte-at-a-time: getcharstr() returns whole characters, so
      -- a multi-byte one never equals a single-byte sub(i, i).
      local init = 1
      while true do
        local s = line:find(char, init, true)
        if not s then
          break
        end
        table.insert(matches, { arow, s - 1 })
        init = s + #char
      end
    end
  else
    local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
    if not line or line == "" then
      return
    end

    local start_col = backward and 1 or (col + 1)
    local end_col = backward and col or #line

    local init = start_col
    while true do
      local s = line:find(char, init, true)
      if not s or s > end_col then
        break
      end
      if backward then
        table.insert(matches, 1, { row, s - 1 })
      else
        table.insert(matches, { row, s - 1 })
      end
      init = s + #char
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

  local labels = multiline and flash_labels_multi or flash_labels_line

  for i, match in ipairs(matches) do
    if i <= #labels then
      local label = labels:sub(i, i)

      vim.api.nvim_buf_set_extmark(0, flash_ns, match[1], match[2], {
        end_col = match[2] + 1,
        hl_group = "FlashMatch",
        priority = 4096,
      })

      vim.api.nvim_buf_set_extmark(0, flash_ns, match[1], match[2], {
        virt_text = { { label, "FlashLabel" } },
        virt_text_pos = "overlay",
        priority = 4097,
      })
    end
  end

  vim.cmd.redraw()
  vim.api.nvim_echo({ { "Select: ", "Question" } }, false, {})

  ok, char = pcall(vim.fn.getcharstr)

  flash_clear(0)
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})
  if not ok then
    return
  end

  if char == flash_esc or char == "" then
    return
  end

  local idx = labels:find(char, 1, true)
  if idx and idx <= #matches then
    vim.api.nvim_win_set_cursor(0, { matches[idx][1] + 1, matches[idx][2] })
  end
end

map("n", "f", function()
  flash_jump({ backward = false })
end, { desc = "Flash Forward" })

map("n", "F", function()
  flash_jump({ backward = true })
end, { desc = "Flash Backward" })

map("n", "s", function()
  flash_jump({ multiline = true })
end, { desc = "Flash (visible)" })

-- Intentionally not enabling ui2 by default here.
-- It is still experimental in 0.12, so keep it opt-in.
if vim.g.enable_ui2 == true then
  pcall(function()
    require("vim._core.ui2").enable({
      enable = true,
      msg = { target = "msg", timeout = 4000 },
    })
  end)
end
