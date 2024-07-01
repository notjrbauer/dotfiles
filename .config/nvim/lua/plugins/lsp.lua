return {
  -- tools
  -- lsp servers
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    opts = {
      inlay_hints = {
        enabled = false,
      },
    },
  },
  {
    'stevearc/conform.nvim',
    lazy = false,
    opts = {
      formatters_by_ft = {
        ['markdown'] = { { 'prettierd', 'prettier' } },
        ['markdown.mdx'] = { { 'prettierd', 'prettier' } },
        ['json'] = { 'jq' },
        ['javascript'] = { 'dprint' },
        ['javascriptreact'] = { 'dprint' },
        ['typescript'] = { 'dprint' },
        ['typescriptreact'] = { 'dprint' },
        ['go'] = { 'gofumpt', 'goimports' },
      },
      -- Set up format-on-save
      format = { timeout_ms = 2000, lsp_fallback = true, async = false, quiet = false },
      formatters = {
        shfmt = {
          prepend_args = { '-i', '2', '-ci' },
        },
        dprint = {
          condition = function(self, ctx)
            return vim.fs.find({ 'dprint.json' }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      opts.servers.gopls.settings.gopls.semanticTokens = false
      opts.setup.gopls = function(_, _)
        LazyVim.lsp.on_attach(function(client, _) end, 'gopls')
      end
      return opts
    end,
  },
  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        lua = { 'selene', 'luacheck' },
        markdown = { 'markdownlint' },
      },
      linters = {
        selene = {
          condition = function(ctx)
            return vim.fs.find({ 'selene.toml' }, { path = ctx.filename, upward = true })[1]
          end,
        },
        luacheck = {
          condition = function(ctx)
            return vim.fs.find({ '.luacheckrc' }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
    },
  },
  -- {
  --   -- LSP VIRTUAL TEXT
  --   'Maan2003/lsp_lines.nvim', -- See also: https://git.sr.ht/~whynothugo/lsp_lines.nvim
  --   config = function(_, opts)
  --     require('lsp_lines').setup(opts)
  --
  --     -- disable virtual_text since it's redundant due to lsp_lines.
  --     vim.diagnostic.config { virtual_text = false }
  --   end,
  -- },
  {
    -- -- CODE ACTION INDICATOR
    'luckasRanarison/clear-action.nvim',
    opts = {},
  },
  {
    'aznhe21/actions-preview.nvim',
    config = function()
      vim.keymap.set({ 'v', 'n' }, '<leader>ca', require('actions-preview').code_actions)
    end,
  },
}
