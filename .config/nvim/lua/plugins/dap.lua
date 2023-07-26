return {
  {
    'mason-nvim-dap.nvim',
    lazy = false,
    config = function(_, opts)
      require('mason-nvim-dap').setup {
        handlers = {
          delve = function(config)
            config = {
              adapters = {
                executable = {
                  command = 'b5env',
                  args = { '-d', './environments/lcl', '-c', 'dlv dap -l 127.0.0.1:${port}' },
                  -- args = { "dap", "-l", "127.0.0.1:${port}" },
                  -- command = "/Users/johnbauer/.local/share/nvim/mason/bin/dlv",
                },
                port = '${port}',
                type = 'server',
              },
              configurations = {
                {
                  name = 'LOL Delve: Debug',
                  program = '${file}',
                  request = 'launch',
                  type = 'delve',
                },
                {
                  mode = 'test',
                  name = 'Delve: Debug test',
                  program = '${file}',
                  request = 'launch',
                  type = 'delve',
                },
                {
                  mode = 'test',
                  name = 'Delve: Debug test (go.mod)',
                  program = './${relativeFileDirname}',
                  request = 'launch',
                  type = 'delve',
                },
              },
              filetypes = { 'go' },
              name = 'delve',
            }
            require('mason-nvim-dap').default_setup(config) -- don't forget this!
          end,
        },
      }
    end,
  },

  -- {
  --   "sainnhe/gruvbox-material",
  --   priority = 10000,
  --   lazy = false,
  --   config = function()
  --     vim.g.gruvbox_material_foreground = "original"
  --     vim.g.gruvbox_material_background = "medium"
  --     vim.cmd.colorscheme("gruvbox-material")
  --   end,
  -- },
}
