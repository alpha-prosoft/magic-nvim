-- Markdown configuration to prevent hiding of code block delimiters
return {
  -- Configure vim-markdown or other markdown plugins to not conceal syntax
  {
    "preservim/vim-markdown",
    enabled = false, -- Disable if you don't want this plugin
  },

  -- Override treesitter settings for markdown
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Ensure markdown parsers are installed
      vim.list_extend(opts.ensure_installed or {}, {
        "markdown",
        "markdown_inline",
      })

      -- Disable highlighting that might cause concealment
      opts.highlight = opts.highlight or {}
      opts.highlight.disable = opts.highlight.disable or {}

      return opts
    end,
  },

  -- Additional autocmd to ensure concealment is disabled
  {
    "LazyVim/LazyVim",
    opts = function()
      -- Set up autocmd to disable concealment in markdown files
      vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter" }, {
        pattern = { "markdown", "*.md" },
        callback = function()
          vim.opt_local.conceallevel = 0
          vim.opt_local.concealcursor = ""
          -- Also disable spell checking if it's causing issues
          -- vim.opt_local.spell = false
        end,
      })
    end,
  },
}