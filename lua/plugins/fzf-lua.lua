-- fzf-lua plugin configuration for LazyVim
return {
  -- fzf-lua: Improved fzf.vim written in lua
  {
    "ibhagwan/fzf-lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- optional for file icons
    },
    cmd = "FzfLua",
    keys = {
      -- File pickers
      { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find Files (fzf)" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<CR>", desc = "Recent Files (fzf)" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "Buffers (fzf)" },

      -- Grep pickers
      { "<leader>sg", "<cmd>FzfLua live_grep<CR>", desc = "Live Grep (fzf)" },
      { "<leader>sw", "<cmd>FzfLua grep_cword<CR>", desc = "Grep Word (fzf)" },
      { "<leader>sW", "<cmd>FzfLua grep_cWORD<CR>", desc = "Grep WORD (fzf)" },
      { "<leader>sv", "<cmd>FzfLua grep_visual<CR>", mode = "v", desc = "Grep Visual (fzf)" },

      -- Git pickers
      { "<leader>gc", "<cmd>FzfLua git_commits<CR>", desc = "Git Commits (fzf)" },
      { "<leader>gs", "<cmd>FzfLua git_status<CR>", desc = "Git Status (fzf)" },
      { "<leader>gb", "<cmd>FzfLua git_branches<CR>", desc = "Git Branches (fzf)" },

      -- LSP pickers
      { "gr", "<cmd>FzfLua lsp_references<CR>", desc = "LSP References (fzf)" },
      { "gd", "<cmd>FzfLua lsp_definitions<CR>", desc = "LSP Definitions (fzf)" },
      { "gI", "<cmd>FzfLua lsp_implementations<CR>", desc = "LSP Implementations (fzf)" },
      { "gy", "<cmd>FzfLua lsp_typedefs<CR>", desc = "LSP Type Definitions (fzf)" },
      { "<leader>ca", "<cmd>FzfLua lsp_code_actions<CR>", desc = "Code Actions (fzf)" },
      { "<leader>ss", "<cmd>FzfLua lsp_document_symbols<CR>", desc = "Document Symbols (fzf)" },
      { "<leader>sS", "<cmd>FzfLua lsp_workspace_symbols<CR>", desc = "Workspace Symbols (fzf)" },

      -- Diagnostics
      { "<leader>xd", "<cmd>FzfLua diagnostics_document<CR>", desc = "Document Diagnostics (fzf)" },
      { "<leader>xD", "<cmd>FzfLua diagnostics_workspace<CR>", desc = "Workspace Diagnostics (fzf)" },

      -- Other pickers
      { "<leader>sh", "<cmd>FzfLua help_tags<CR>", desc = "Help Tags (fzf)" },
      { "<leader>sk", "<cmd>FzfLua keymaps<CR>", desc = "Key Maps (fzf)" },
      { "<leader>sc", "<cmd>FzfLua commands<CR>", desc = "Commands (fzf)" },
      { "<leader>:", "<cmd>FzfLua command_history<CR>", desc = "Command History (fzf)" },
      { "<leader>/", "<cmd>FzfLua search_history<CR>", desc = "Search History (fzf)" },
      { "<leader>sm", "<cmd>FzfLua marks<CR>", desc = "Marks (fzf)" },
      { "<leader>sj", "<cmd>FzfLua jumps<CR>", desc = "Jumps (fzf)" },
      { "<leader>sr", "<cmd>FzfLua resume<CR>", desc = "Resume Last Search (fzf)" },
    },
    opts = {
      -- Global defaults
      defaults = {
        file_icons = true,
        git_icons = true,
        color_icons = true,
      },

      -- Window configuration
      winopts = {
        height = 0.85,
        width = 0.85,
        row = 0.35,
        col = 0.50,
        border = "rounded",
        preview = {
          default = "bat", -- use bat for previews if available
          border = "border",
          wrap = "nowrap",
          hidden = "nohidden",
          vertical = "down:45%",
          horizontal = "right:50%",
          layout = "flex",
          flip_columns = 120,
          title = true,
          scrollbar = "float",
          delay = 100,
        },
      },

      -- Key mappings inside fzf window
      keymap = {
        builtin = {
          ["<F1>"] = "toggle-help",
          ["<F2>"] = "toggle-fullscreen",
          ["<F3>"] = "toggle-preview-wrap",
          ["<F4>"] = "toggle-preview",
          ["<F5>"] = "toggle-preview-ccw",
          ["<F6>"] = "toggle-preview-cw",
          ["<C-d>"] = "preview-page-down",
          ["<C-u>"] = "preview-page-up",
          ["<S-down>"] = "preview-down",
          ["<S-up>"] = "preview-up",
        },
        fzf = {
          ["ctrl-z"] = "abort",
          ["ctrl-f"] = "half-page-down",
          ["ctrl-b"] = "half-page-up",
          ["ctrl-a"] = "beginning-of-line",
          ["ctrl-e"] = "end-of-line",
          ["alt-a"] = "toggle-all",
          ["f3"] = "toggle-preview-wrap",
          ["f4"] = "toggle-preview",
          ["shift-down"] = "preview-down",
          ["shift-up"] = "preview-up",
        },
      },

      -- File picker configuration
      files = {
        prompt = "Files> ",
        multiprocess = true,
        git_icons = true,
        file_icons = true,
        color_icons = true,
        find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
        rg_opts = "--color=never --files --hidden --follow -g '!.git'",
        fd_opts = "--color=never --type f --hidden --follow --exclude .git",
      },

      -- Grep configuration
      grep = {
        prompt = "Rg> ",
        input_prompt = "Grep For> ",
        multiprocess = true,
        git_icons = true,
        file_icons = true,
        color_icons = true,
        grep_opts = "--binary-files=without-match --line-number --recursive --color=auto --perl-regexp",
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=512",
        rg_glob = true, -- enable glob parsing
        glob_flag = "--iglob",
        glob_separator = "%s%-%-",
      },

      -- LSP configuration
      lsp = {
        prompt_postfix = "> ",
        cwd_only = false,
        async_or_timeout = 5000,
        file_icons = true,
        git_icons = false,
        symbols = {
          prompt_postfix = "> ",
          symbol_fmt = function(s)
            return "[" .. s .. "]"
          end,
        },
      },

      -- Git configuration
      git = {
        files = {
          prompt = "Git Files> ",
          cmd = "git ls-files --exclude-standard",
          multiprocess = true,
          git_icons = true,
          file_icons = true,
          color_icons = true,
        },
        status = {
          prompt = "Git Status> ",
          cmd = "git status -s",
          file_icons = true,
          git_icons = true,
          color_icons = true,
          previewer = "git_diff",
        },
        commits = {
          prompt = "Git Commits> ",
          cmd = "git log --color --pretty=format:'%C(yellow)%h%Creset %Cgreen(%><(12)%cr%><|(12))%Creset %s %C(blue)<%an>%Creset'",
          preview = "git show --pretty='%Cred%H%n%Cblue%an <%ae>%n%C(yellow)%cD%n%Cgreen%s' --color {1}",
          actions = {
            ["default"] = false,
          },
        },
        branches = {
          prompt = "Branches> ",
          cmd = "git branch --all --color",
          preview = "git log --graph --pretty=oneline --abbrev-commit --color {1}",
          actions = {
            ["default"] = false,
          },
        },
      },
    },
    config = function(_, opts)
      -- Setup fzf-lua with our options
      require("fzf-lua").setup(opts)

      -- Optional: Override some Telescope mappings if you prefer fzf-lua
      -- This makes fzf-lua the default fuzzy finder
      -- Uncomment the following lines if you want to replace Telescope completely:
      --
      -- vim.keymap.set("n", "<leader><space>", "<cmd>FzfLua files<CR>", { desc = "Find Files (fzf)" })
      -- vim.keymap.set("n", "<leader>,", "<cmd>FzfLua buffers<CR>", { desc = "Switch Buffer (fzf)" })
      -- vim.keymap.set("n", "<leader>/", "<cmd>FzfLua live_grep<CR>", { desc = "Grep (fzf)" })
    end,
  },
}

