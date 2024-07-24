return {

  -- floating winbar
  -- {
  --   "b0o/incline.nvim",
  --   event = "BufReadPre",
  --   enabled = false,
  --   config = function()
  --     local colors = require("tokyonight.colors").setup()
  --     require("incline").setup({
  --       highlight = {
  --         groups = {
  --           InclineNormal = { guibg = "#FC56B1", guifg = colors.black },
  --           InclineNormalNC = { guifg = "#FC56B1", guibg = colors.black },
  --         },
  --       },
  --       window = { margin = { vertical = 0, horizontal = 1 } },
  --       render = function(props)
  --         local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
  --         local icon, color = require("nvim-web-devicons").get_icon_color(filename)
  --         return { { icon, guifg = color }, { " " }, { filename } }
  --       end,
  --     })
  --   end,
  -- },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    opts = {
      flavour = 'mocha',
      transparent_background = true,
      term_colors = true,
      dim_inactive = { enabled = false },
    },
  },
  {
    'LazyVim/LazyVim',
    opts = {
      colorscheme = 'catppuccin',
    },
  },
  -- auto-resize windows
  {
    'anuvyklack/windows.nvim',
    enabled = true,
    event = 'WinNew',
    dependencies = {
      { 'anuvyklack/middleclass' },
      { 'anuvyklack/animation.nvim', enabled = false },
    },
    keys = { { '<leader>m', '<cmd>WindowsMaximize<cr>', desc = 'Zoom' } },
    config = function()
      vim.o.winwidth = 5
      vim.o.equalalways = false
      require('windows').setup {
        animation = { enable = false, duration = 150 },
      }
    end,
  },

  -- scrollbar
  -- { "lewis6991/satellite.nvim", opts = {}, event = "VeryLazy", enabled = false },
  -- {
  --   "echasnovski/mini.map",
  --   main = "mini.map",
  --   event = "VeryLazy",
  --   enabled = false,
  --   config = function()
  --     local map = require("mini.map")
  --     map.setup({
  --       integrations = {
  --         map.gen_integration.builtin_search(),
  --         map.gen_integration.gitsigns(),
  --         map.gen_integration.diagnostic(),
  --       },
  --     })
  --     map.open()
  --   end,
  -- },
  -- {
  --   "petertriho/nvim-scrollbar",
  --   event = "BufReadPost",
  --   enabled = false,
  --   config = function()
  --     local scrollbar = require("scrollbar")
  --     local colors = require("tokyonight.colors").setup()
  --     scrollbar.setup({
  --       handle = { color = colors.bg_highlight },
  --       excluded_filetypes = { "prompt", "TelescopePrompt", "noice", "notify" },
  --       marks = {
  --         Search = { color = colors.orange },
  --         Error = { color = colors.error },
  --         Warn = { color = colors.warning },
  --         Info = { color = colors.info },
  --         Hint = { color = colors.hint },
  --         Misc = { color = colors.purple },
  --       },
  --     })
  --   end,
  -- },

  -- style windows with different colorschemes
  -- {
  --   "folke/styler.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     themes = {
  --       -- markdown = { colorscheme = "catppuccin" },
  --       help = { colorscheme = "catppuccin", background = "dark" },
  --     },
  --   },
  -- },

  -- silly drops
  -- {
  --   "folke/drop.nvim",
  --   enabled = false,
  --   event = "VeryLazy",
  --   config = function()
  --     math.randomseed(os.time())
  --     -- local theme = ({ "stars", "snow" })[math.random(1, 3)]
  --     require("drop").setup({ theme = "spring" })
  --   end,
  -- },

  -- lualine
  {
    'nvim-lualine/lualine.nvim',
    opts = function(_, opts)
      ---@type table<string, {updated:number, total:number, enabled: boolean, status:string[]}>
      local mutagen = {}

      local function mutagen_status()
        local cwd = vim.uv.cwd() or '.'
        mutagen[cwd] = mutagen[cwd]
          or {
            updated = 0,
            total = 0,
            enabled = vim.fs.find('mutagen.yml', { path = cwd, upward = true })[1] ~= nil,
            status = {},
          }
        local now = vim.uv.now() -- timestamp in milliseconds
        local refresh = mutagen[cwd].updated + 10000 < now
        if #mutagen[cwd].status > 0 then
          refresh = mutagen[cwd].updated + 1000 < now
        end
        if mutagen[cwd].enabled and refresh then
          ---@type {name:string, status:string, idle:boolean}[]
          local sessions = {}
          local lines = vim.fn.systemlist 'mutagen project list'
          local status = {}
          local name = nil
          for _, line in ipairs(lines) do
            local n = line:match '^Name: (.*)'
            if n then
              name = n
            end
            local s = line:match '^Status: (.*)'
            if s then
              table.insert(sessions, {
                name = name,
                status = s,
                idle = s == 'Watching for changes',
              })
            end
          end
          for _, session in ipairs(sessions) do
            if not session.idle then
              table.insert(status, session.name .. ': ' .. session.status)
            end
          end
          mutagen[cwd].updated = now
          mutagen[cwd].total = #sessions
          mutagen[cwd].status = status
          if #sessions == 0 then
            vim.notify('Mutagen is not running', vim.log.levels.ERROR, { title = 'Mutagen' })
          end
        end
        return mutagen[cwd]
      end

      local error_color = LazyVim.ui.fg 'DiagnosticError'
      local ok_color = LazyVim.ui.fg 'DiagnosticInfo'
      table.insert(opts.sections.lualine_x, {
        cond = function()
          return mutagen_status().enabled
        end,
        color = function()
          return (mutagen_status().total == 0 or mutagen_status().status[1]) and error_color or ok_color
        end,
        function()
          local s = mutagen_status()
          local msg = s.total
          if #s.status > 0 then
            msg = msg .. ' | ' .. table.concat(s.status, ' | ')
          end
          return (s.total == 0 and '󰋘 ' or '󰋙 ') .. msg
        end,
      })

      -- local keys = {}
      --
      -- vim.on_key(function(_, key)
      --   if not key then
      --     return
      --   end
      --   if #key > 0 then
      --     table.insert(keys, vim.fn.keytrans(key))
      --     -- require("lualine").refresh()
      --     -- vim.cmd.redraw()
      --   end
      -- end)
      --
      -- table.insert(opts.sections.lualine_x, {
      --   function()
      --     if #keys > 10 then
      --       keys = vim.list_slice(keys, #keys - 10)
      --     end
      --     return table.concat(keys)
      --   end,
      -- })
      --
      -- local count = 0
      -- table.insert(opts.sections.lualine_x, {
      --   function()
      --     count = count + 1
      --     return tostring(count)
      --   end,
      -- })
    end,
  },

  'folke/twilight.nvim',
  {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    opts = {
      window = { backdrop = 0.7 },
      plugins = {
        gitsigns = true,
        tmux = true,
        kitty = { enabled = false, font = '+2' },
      },
    },
    keys = { { '<leader>z', '<cmd>ZenMode<cr>', desc = 'Zen Mode' } },
  },
}
