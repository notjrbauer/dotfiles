-- stylua: ignore start
-- Leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Backup, Swap, Undo Paths
local prefix = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")
vim.opt.backup = true
vim.opt.writebackup = true
vim.opt.undodir = { prefix .. "/nvim/.undo//" }
vim.opt.backupdir = { prefix .. "/nvim/.backup//" }
vim.opt.directory = { prefix .. "/nvim/.swp//" }

-- General
vim.opt.mouse = 'a'
vim.opt.mousescroll = 'ver:25,hor:6'
vim.opt.switchbuf = 'usetab'
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.clipboard = 'unnamedplus'
vim.cmd('filetype plugin indent on')

-- UI
vim.opt.breakindent = true
vim.opt.colorcolumn = '+1'
vim.opt.cursorline = true
vim.opt.laststatus = 2
vim.opt.linebreak = true
vim.opt.list = true
vim.opt.number = true
vim.opt.pumblend = 10
vim.opt.pumheight = 10
vim.opt.ruler = false
vim.opt.showmode = false
vim.opt.showtabline = 2
vim.opt.signcolumn = 'yes'
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.winblend = 10
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.cmd('let g:nvcode_termcolors=256')

vim.opt.fillchars = {
  eob = ' ',
  fold = '╌',
  horiz = '═',
  horizdown = '╦',
  horizup = '╩',
  vert = '║',
  verthoriz = '╬',
  vertleft = '╣',
  vertright = '╠',
}

vim.opt.listchars = {
  extends = '…',
  nbsp = '␣',
  precedes = '…',
  tab = '> ',
}

if vim.fn.has('nvim-0.9') == 1 then
  vim.opt.shortmess:append("C")
  vim.opt.splitkeep = "screen"
end
vim.opt.shortmess:append("I")

-- Syntax
if vim.fn.exists("syntax_on") ~= 1 then
  vim.cmd([[syntax enable]])
end

-- Editing
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.formatoptions = 'rqnl1j'
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.infercase = true
vim.opt.shiftwidth = 2
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.virtualedit = 'block'
vim.opt.completeopt = 'menuone,noinsert,noselect'
vim.opt.iskeyword:append('-')
vim.g.editorconfig = false
vim.opt.matchtime = 2
vim.opt.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]

-- Spelling
vim.opt.spelllang = 'en'
vim.opt.spelloptions = 'camel'
vim.opt.complete:append('kspell')
vim.opt.complete:remove('t')
vim.opt.dictionary = prefix .. "/nvim/misc/dict/english.txt"

-- Folds
vim.opt.foldmethod = 'indent'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldnestmax = 10
vim.opt.foldenable = true
vim.opt.foldcolumn = "1"

-- Grep
if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --smart-case --vimgrep $*"
  vim.opt.grepformat = "%f:%l:%c:%m"
elseif vim.fn.executable("ag") == 1 then
  vim.opt.grepprg = "ag --nogroup --nocolor --vimgrep"
  vim.opt.grepformat = "%f:%l:%c:%m"
end

-- LSP Diagnostics UI
vim.diagnostic.config({
  virtual_text = {
    spacing = 4,
    prefix = "●",
  },
  severity_sort = true,
})

-- Disable unused providers
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- Root spec
vim.g.root_spec = { "cwd" }

-- Custom autocmds
vim.cmd([[
  augroup CustomSettings
    autocmd!
    autocmd FileType * setlocal formatoptions-=c formatoptions-=o
  augroup END
]])
-- stylua: ignore end
