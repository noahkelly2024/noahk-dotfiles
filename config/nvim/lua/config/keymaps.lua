-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Make <C-\> exit terminal mode (instead of <C-\><C-n>)
vim.keymap.set("t", "<C-\\>", "<C-\\><C-n>", {
  noremap = true,
  silent = true,
  desc = "Exit terminal mode",
})

