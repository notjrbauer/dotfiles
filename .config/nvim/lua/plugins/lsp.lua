local servers = {
  -- clangd = {},
  gopls = {},
  -- pyright = {},
  -- rust_analyzer = {},
  -- tsserver = {},

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
}

local on_attach = function(_, bufnr)
  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

  nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
  nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
  nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
  nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

  -- Lesser used LSP functionality
  nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
  nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
  nmap('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[W]orkspace [L]ist Folders')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end

return {
  -- neodev
  {
    'folke/neodev.nvim',
    opts = {
      debug = true,
      experimental = {
        pathStrict = true,
      },
      library = {
        runtime = '~/projects/neovim/runtime/',
      },
    },
  },

  -- tools
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        'stylua',
        'selene',
        'luacheck',
        'shellcheck',
        'shfmt',
      })
    end,
  },

  -- lsp servers
  {
    'neovim/nvim-lspconfig',
    opts = {
      inlay_hints = { enabled = true },
      capabilities = {
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = false,
          },
        },
      },
      ---@type lspconfig.options
      servers = {
        ansiblels = {},
        bashls = {},
        clangd = {},
        -- denols = {},
        cssls = {},
        dockerls = {},
        -- ruff_lsp = {},
        tailwindcss = {
          root_dir = function(...)
            return require('lspconfig.util').root_pattern '.git'(...)
          end,
        },
        tsserver = {
          -- root_dir = function(...)
          --   return require("lspconfig.util").root_pattern(".git")(...)
          -- end,
          single_file_support = false,
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = 'literal',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = 'all',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },
        -- svelte = {},
        html = {},
        -- gopls = {},
        marksman = {},
        -- pyright = {
        --   enabled = false,
        -- },
        -- rust_analyzer = {
        -- settings = {
        --   ["rust-analyzer"] = {
        --     procMacro = { enable = true },
        --     cargo = { allFeatures = true },
        --     checkOnSave = {
        --       command = "clippy",
        --       extraArgs = { "--no-deps" },
        --     },
        --   },
        -- },
        -- },
        yamlls = {
          settings = {
            yaml = {
              keyOrdering = false,
            },
          },
        },
        lua_ls = {
          -- enabled = false,
          -- cmd = { "/home/folke/projects/lua-language-server/bin/lua-language-server" },
          single_file_support = true,
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              completion = {
                workspaceWord = true,
                callSnippet = 'Both',
              },
              misc = {
                parameters = {
                  -- "--log-level=trace",
                },
              },
              hover = { expandAlias = false },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = 'Disable',
                semicolon = 'Disable',
                arrayIndex = 'Disable',
              },
              doc = {
                privateName = { '^_' },
              },
              type = {
                castNumberToInteger = true,
              },
              diagnostics = {
                disable = { 'incomplete-signature-doc', 'trailing-space' },
                -- enable = false,
                groupSeverity = {
                  strong = 'Warning',
                  strict = 'Warning',
                },
                groupFileStatus = {
                  ['ambiguity'] = 'Opened',
                  ['await'] = 'Opened',
                  ['codestyle'] = 'None',
                  ['duplicate'] = 'Opened',
                  ['global'] = 'Opened',
                  ['luadoc'] = 'Opened',
                  ['redefined'] = 'Opened',
                  ['strict'] = 'Opened',
                  ['strong'] = 'Opened',
                  ['type-check'] = 'Opened',
                  ['unbalanced'] = 'Opened',
                  ['unused'] = 'Opened',
                },
                unusedLocalExclude = { '_*' },
              },
              format = {
                enable = true,
                defaultConfig = {
                  indent_style = 'space',
                  indent_size = '2',
                  continuation_indent_size = '2',
                },
              },
            },
          },
        },
        vimls = {},
      },
      setup = {},
    },
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      diagnostics = { virtual_text = { prefix = 'icons' } },
    },
  },

  {
    'stevearc/conform.nvim',
    optional = true,
    opts = {
      formatters_by_ft = {
        ['markdown'] = { { 'prettierd', 'prettier' } },
        ['markdown.mdx'] = { { 'prettierd', 'prettier' } },
        ['javascript'] = { 'dprint' },
        ['javascriptreact'] = { 'dprint' },
        ['typescript'] = { 'dprint' },
        ['typescriptreact'] = { 'dprint' },
      },
      formatters = {
        shfmt = {
          prepend_args = { '-i', '2', '-ci' },
        },
        dprint = {
          condition = function(ctx)
            return vim.fs.find({ 'dprint.json' }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
    },
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
}
