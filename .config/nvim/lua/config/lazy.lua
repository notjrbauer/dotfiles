-- local colorscheme = require 'lazyvim.plugins.colorscheme'
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

---@param opts LazyConfig
return function(opts)
  opts = vim.tbl_deep_extend('force', {
    spec = {
      {
        'LazyVim/LazyVim',
        import = 'lazyvim.plugins',
        opts = {
          -- colorscheme = 'catppuccin-macchiato',
          news = {
            lazyvim = true,
            neovim = true,
          },
        },
      },
      { import = 'plugins' },
    },
    defaults = { lazy = true, version = false },
    checker = { enabled = true },
    diff = {
      cmd = 'diffview.nvim',
    },
    rocks = { hererocks = true },
    performance = {
      cache = {
        enabled = false,
        -- disable_events = {},
      },
      rtp = {
        disabled_plugins = {
          'gzip',
          'health',
          'man',
          -- 'matchit',
          -- 'matchparen',
          -- 'netrwPlugin',
          'rplugin',
          'spellfile',
          'tarPlugin',
          'tohtml',
          'tutor',
          'zipPlugin',
        },
      },
    },
    ui = {
      custom_keys = {
        ['<localleader>d'] = function(plugin)
          dd(plugin)
        end,
      },
    },
    debug = false,
  }, opts or {})
  require('lazy').setup(opts)
end
