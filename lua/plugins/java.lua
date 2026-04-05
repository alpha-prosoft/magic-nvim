-- Java LSP configuration for LazyVim
return {
  -- nvim-jdtls for enhanced Java support
  {
    "mfussenegger/nvim-jdtls",
    dependencies = {
      "folke/which-key.nvim",
      "mason-org/mason.nvim",
    },
  },

  -- Configure nvim-lspconfig with jdtls
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- jdtls will be automatically installed with mason and loaded with lspconfig
        jdtls = {},
      },
      setup = {
        jdtls = function()
          -- Return true to prevent lspconfig from setting up jdtls
          -- nvim-jdtls will handle the setup
          return true
        end,
      },
    },
  },

  -- Ensure Java-related tools are installed via Mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "jdtls", -- Java language server
        "java-debug-adapter", -- Java debugger
        "java-test", -- Java test runner
        "google-java-format", -- Java formatter (optional)
      })
    end,
  },

  -- Add Java to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "java",
      })
    end,
  },

  -- Optional: nvim-dap for Java debugging
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "mason-org/mason.nvim",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, {
          "java-debug-adapter",
          "java-test",
        })
      end,
    },
  },
}