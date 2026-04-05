-- Clojure development setup
return {
  -- Add clojure-lsp to nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clojure_lsp = {
          -- clojure-lsp configuration
          -- The server will be automatically started for .clj, .cljs, .cljc, and .edn files
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
        },
      },
    },
  },

  -- Ensure clojure-lsp is installed via Mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "clojure-lsp", -- Clojure language server
      })
    end,
  },

  -- Conjure for Clojure REPL integration
  {
    "Olical/conjure",
    ft = { "clojure", "fennel", "janet" },
    config = function()
      -- Disable diagnostics in virtual text by conjure
      vim.g["conjure#log#hud#enabled"] = false
    end,
  },

  -- Optional: Parinfer for better parentheses handling
  -- Uncomment if you want automatic parentheses balancing
  -- {
  --   "gpanders/nvim-parinfer",
  --   ft = { "clojure", "fennel", "scheme", "lisp" },
  -- },
}
