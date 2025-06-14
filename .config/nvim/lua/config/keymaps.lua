-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- Move to window using the movement keys
vim.keymap.set("i", "jj", "<ESC>")

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
-- vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- code action
-- (using https://github.com/aznhe21/actions-preview.nvim instead)
-- vim.keymap.set('n', '<space>c', '<cmd>lua vim.lsp.buf.code_action()<CR>')

-- gitsigns
vim.keymap.set("n", "<space>q", "<cmd>Gitsigns blame_line<CR>")
