return {
  { 'justinsgithub/wezterm-types' },
  {
    'folke/flash.nvim',
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, false },
      { 'S', mode = { 'n', 'o', 'x' }, false },
      { 'r', mode = 'o', false },
      { 'R', mode = { 'o', 'x' }, false },
      { '<c-s>', mode = { 'c' }, false },
      {
        'S',
        mode = { 'n', 'o', 'x' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
    },
    opts = {
      -- labels = "#abcdef",
      modes = {
        char = { jump_labels = true },
        -- treesitter = {
        --   label = {
        --     rainbow = { enabled = true },
        --   },
        -- },
        treesitter_search = {
          label = {
            rainbow = { enabled = true },
            -- format = function(opts)
            --   local label = opts.match.label
            --   if opts.after then
            --     label = label .. ">"
            --   else
            --     label = "<" .. label
            --   end
            --   return { { label, opts.hl_group } }
            -- end,
          },
        },
      },
    },
  },
}
