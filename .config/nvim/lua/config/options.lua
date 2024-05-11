--stylua: ignore start
-- Leader key =================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader= ' '

-- General ====================================================================
vim.o.backup       = false          -- Don't store backup
vim.o.mouse        = 'a'            -- Enable mouse
vim.o.mousescroll  = 'ver:25,hor:6' -- Customize mouse scroll
vim.o.switchbuf    = 'usetab'       -- Use already opened buffers when switching
vim.o.writebackup  = false          -- Don't store backup

vim.o.undodir  = vim.fn.stdpath('config') .. '/misc/undodir' -- Set directory for persistent undo
vim.o.undofile = true                                        -- Enable persistent undo

vim.cmd('filetype plugin indent on') -- Enable all filetype plugins

-- UI =========================================================================
vim.o.breakindent   = true      -- Indent wrapped lines to match line start
vim.o.colorcolumn   = '+1'      -- Draw colored column one step to the right of desired maximum width
vim.o.cursorline    = true      -- Enable highlighting of the current line
vim.o.laststatus    = 2         -- Always show statusline
vim.o.linebreak     = true      -- Wrap long lines at 'breakat' (if 'wrap' is set)
vim.o.list          = true      -- Show helpful character indicators
vim.o.number        = true      -- Show line numbers
vim.o.pumblend      = 10        -- Make builtin completion menus slightly transparent
vim.o.pumheight     = 10        -- Make popup menu smaller
vim.o.ruler         = false     -- Don't show cursor position
vim.o.shortmess     = 'aoOWFcS' -- Disable certain messages from |ins-completion-menu|
vim.o.showmode      = false     -- Don't show mode in command line
vim.o.showtabline   = 2         -- Always show tabline
vim.o.signcolumn    = 'yes'     -- Always show signcolumn or it would frequently shift
vim.o.splitbelow    = true      -- Horizontal splits will be below
vim.o.splitright    = true      -- Vertical splits will be to the right
vim.o.termguicolors = true      -- Enable gui colors
vim.cmd('let g:nvcode_termcolors=256')
vim.o.winblend      = 10        -- Make floating windows slightly transparent
vim.o.wrap          = false     -- Display long lines as just one line

vim.o.fillchars = table.concat(
  { 'eob: ', 'fold:╌', 'horiz:═', 'horizdown:╦', 'horizup:╩', 'vert:║', 'verthoriz:╬', 'vertleft:╣', 'vertright:╠' },
  ','
)
vim.o.listchars =table.concat(
  { 'extends:…', 'nbsp:␣', 'precedes:…', 'tab:> ' },
  ','
)

if vim.fn.has('nvim-0.9') == 1 then
  vim.opt.shortmess:append('C') -- Don't show "Scanning..." messages
  vim.o.splitkeep = 'screen'    -- Reduce scroll during window split
end

-- Colors =====================================================================
-- Enable syntax highlighing if it wasn't already (as it is time consuming)
-- Don't use defer it because it affects start screen appearance
if vim.fn.exists("syntax_on") ~= 1 then
  vim.cmd([[syntax enable]])
end

-- Editing ====================================================================
vim.o.autoindent    = true     -- Use auto indent
vim.o.expandtab     = true     -- Convert tabs to spaces
vim.o.formatoptions = 'rqnl1j' -- Improve comment editing
vim.o.ignorecase    = true     -- Ignore case when searching (use `\C` to force not doing that)
vim.o.incsearch     = true     -- Show search results while typing
vim.o.infercase     = true     -- Infer letter cases for a richer built-in keyword completion
vim.o.shiftwidth    = 2        -- Use this number of spaces for indentation
vim.o.smartcase     = true     -- Don't ignore case when searching if pattern has upper case
vim.o.smartindent   = true     -- Make indenting smart
vim.o.tabstop       = 2        -- Insert 2 spaces for a tab
vim.o.virtualedit   = 'block'  -- Allow going past the end of line in visual block mode

vim.opt.iskeyword:append('-')  -- Treat dash separated words as a word text object

vim.o.completeopt = 'menuone,noinsert,noselect' -- Customize completions

-- Define pattern for a start of 'numbered' list. This is responsible for
-- correct formatting of lists when using `gw`. This basically reads as 'at
-- least one special character (digit, -, +, *) possibly followed some
-- punctuation (. or `)`) followed by at least one space is a start of list
-- item'
vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]

-- Spelling ===================================================================
vim.o.spelllang    = 'en,ru,uk'   -- Define spelling dictionaries
vim.o.spelloptions = 'camel'      -- Treat parts of camelCase words as seprate words
vim.opt.complete:append('kspell') -- Add spellcheck options for autocomplete
vim.opt.complete:remove('t')      -- Don't use tags for completion

vim.o.dictionary = vim.fn.stdpath('config') .. '/misc/dict/english.txt' -- Use specific dictionaries

-- Folds ======================================================================
vim.o.foldmethod  = 'indent' -- Set 'indent' folding method
vim.o.foldlevel = 99
-- vim.o.foldlevel   = 2        -- Display all folds except top ones
vim.o.foldnestmax = 10       -- Create folds only for some number of nested levels

-- Custom autocommands ========================================================
vim.cmd([[augroup CustomSettings]])
  vim.cmd([[autocmd!]])

  -- Don't auto-wrap comments and don't insert comment leader after hitting 'o'
  -- If don't do this on `FileType`, this keeps magically reappearing.
  vim.cmd([[autocmd FileType * setlocal formatoptions-=c formatoptions-=o]])
vim.cmd([[augroup END]])
--stylua: ignore end
--
-- vim.g.mapleader = ' '
-- vim.g.maplocalleader = ' '
--
-- -- Set highlight on search
-- vim.o.hlsearch = false
--
-- -- Make line numbers default
-- vim.wo.number = true
--
-- -- Enable mouse mode
-- vim.o.mouse = 'a'
--
-- -- Sync clipboard between OS and Neovim.
-- --  Remove this option if you want your OS clipboard to remain independent.
-- --  See `:help 'clipboard'`
-- vim.o.clipboard = 'unnamedplus'
--
-- -- Enable break indent
-- vim.o.breakindent = true
--
-- -- Save undo history
-- vim.o.undofile = true
--
-- -- Case-insensitive searching UNLESS \C or capital in search
-- vim.o.ignorecase = true
-- vim.o.smartcase = true
--
-- -- Keep signcolumn on by default
-- vim.wo.signcolumn = 'yes'
--
-- -- Decrease update time
-- vim.o.updatetime = 250
-- vim.o.timeout = true
-- vim.o.timeoutlen = 300
--
-- -- Set completeopt to have a better completion experience
-- vim.o.completeopt = 'menuone,noselect'
--
-- -- NOTE: You should make sure your terminal supports this
-- vim.o.termguicolors = true
--
-- vim.opt.fillchars = {
--   foldopen = '',
--   foldclose = '',
--   fold = ' ',
--   foldsep = ' ',
--   diff = '╱',
--   eob = ' ',
-- }
--
-- vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
-- vim.o.foldlevelstart = 99
-- vim.o.foldenable = true
-- vim.o.foldcolumn = '0'
--
-- if vim.fn.has 'nvim-0.8' == 1 then
--   vim.opt.backup = true
--   vim.opt.cmdheight = 0
--   vim.opt.backupdir = vim.fn.stdpath 'state' .. '/backup'
-- end
--
-- if vim.g.neovide then
--   vim.opt.guifont = { 'FiraCode Nerd Font Mono', 'h9' }
--   vim.g.neovide_scale_factor = 0.3
-- end
--
-- -- vim.g.node_host_prog = "/Users/folke/.pnpm-global/5/node_modules/neovim/bin/cli.js"
-- vim.g.loaded_python3_provider = 0
-- vim.g.loaded_perl_provider = 0
-- vim.g.loaded_ruby_provider = 0
-- vim.g.loaded_node_provider = 0
--
-- -- Set highlight on search
-- vim.o.hlsearch = false
--
-- -- Make line numbers default
-- vim.wo.number = true
--
-- -- Enable mouse mode
-- vim.o.mouse = 'a'
--
-- -- Sync clipboard between OS and Neovim.
-- --  Remove this option if you want your OS clipboard to remain independent.
-- --  See `:help 'clipboard'`
-- vim.o.clipboard = 'unnamedplus'
--
-- -- Enable break indent
-- vim.o.breakindent = true
--
-- -- Save undo history
-- vim.o.undofile = true
--
-- -- Case-insensitive searching UNLESS \C or capital in search
-- vim.o.ignorecase = true
-- vim.o.smartcase = true
--
-- -- Keep signcolumn on by default
-- vim.wo.signcolumn = 'yes'
--
-- -- Decrease update time
-- vim.o.updatetime = 250
-- vim.o.timeout = true
-- vim.o.timeoutlen = 300
--
-- -- Set completeopt to have a better completion experience
-- vim.o.completeopt = 'menuone,noselect'
--
-- -- NOTE: You should make sure your terminal supports this
-- vim.o.termguicolors = true
--
-- local keymap_set = vim.keymap.set
-- ---@diagnostic disable-next-line: duplicate-set-field
-- vim.keymap.set = function(mode, lhs, rhs, opts)
--   opts = opts or {}
--   opts.silent = opts.silent ~= false
--   return keymap_set(mode, lhs, rhs, opts)
-- end
