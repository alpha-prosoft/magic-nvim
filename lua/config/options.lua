-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use system clipboard for all yank, delete, change and put operations
vim.opt.clipboard = "unnamedplus"

-- Disable folding in markdown files (fixes code block visibility issue)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.foldenable = false
    -- Disable concealing to show ``` quotes and other markdown syntax
    vim.opt_local.conceallevel = 0
    vim.opt_local.concealcursor = ""
  end,
})

-- Override filetype detection for Terraform files
-- Neovim's builtin uses 'tf' but terraform-ls expects 'terraform'
vim.filetype.add({
  extension = {
    tf = "terraform",
    tfvars = "terraform-vars",
  },
  pattern = {
    [".*%.tf"] = "terraform",
    [".*%.tfvars"] = "terraform-vars",
  },
})
