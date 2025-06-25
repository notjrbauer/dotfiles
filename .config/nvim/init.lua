-- bootstrap lazy.nvim, LazyVim and your plugins
-- require("config.lazy")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
  local out = vim.fn.system({ "git", "-C", lazypath, "checkout", "tags/stable" })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- ✅ Always update runtimepath, even if already cloned
vim.opt.rtp:prepend(lazypath)

vim.lsp.config("*", {
  capabilities = {
    textDocument = {
      semanticTokens = {
        multilineTokenSupport = true,
      },
    },
  },
  root_markers = { ".git" },
})



-- Source core config
require("config.options")

require("lazy").setup({
  { import = "plugins" },
})

-- Defer loading of mappings and LSP after plugins finish
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    require("config.keymaps")
    require("plugins.lspconfig")


vim.lsp.enable({
    "lua_ls"
})
    
  end,
})


