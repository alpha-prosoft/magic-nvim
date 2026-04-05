-- Terraform development setup
return {
  -- Add terraformls to nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = {
          -- terraform-ls configuration
          -- The server will be automatically started for .tf and .tfvars files
          -- Important: terraform-ls does NOT support 'settings' via didChangeConfiguration
          -- Use init_options instead for any custom configuration
          
          -- Add both 'terraform' and 'tf' filetypes to handle Neovim's builtin
          filetypes = { "terraform", "terraform-vars", "tf" },
        },
      },
    },
  },

  -- Ensure terraform-ls is installed via Mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "terraform-ls", -- Terraform language server
      })
    end,
  },
}
