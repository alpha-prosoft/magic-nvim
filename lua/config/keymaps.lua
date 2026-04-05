-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Clojure: Copy fully qualified symbol name
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "clojure", "clojurescript" },
  callback = function()
    vim.keymap.set("n", "<leader>yf", function()
      -- Get current word under cursor
      local word = vim.fn.expand("<cword>")
      
      -- Find the namespace declaration
      local ns_line_num = vim.fn.search("(ns ", "bn")
      if ns_line_num == 0 then
        vim.notify("Could not find namespace declaration", vim.log.levels.WARN)
        return
      end
      
      -- Get namespace line and extract namespace name
      local ns_line = vim.fn.getline(ns_line_num)
      local ns_name = ns_line:match("%(ns%s+([%w%.%-]+)")
      
      if not ns_name then
        vim.notify("Could not parse namespace name", vim.log.levels.WARN)
        return
      end
      
      -- Create fully qualified name
      local fqn = ns_name .. "/" .. word
      
      -- Copy to system clipboard (+ register) and unnamed register
      vim.fn.setreg("+", fqn)
      vim.fn.setreg('"', fqn)
      
      vim.notify("Copied: " .. fqn, vim.log.levels.INFO)
    end, { buffer = true, desc = "Copy Fully Qualified Symbol Name" })

    -- Copy file path where function is defined (using LSP)
    vim.keymap.set("n", "<leader>yp", function()
      local params = vim.lsp.util.make_position_params()
      vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx, config)
        if err then
          vim.notify("LSP error: " .. vim.inspect(err), vim.log.levels.ERROR)
          return
        end

        if not result or vim.tbl_isempty(result) then
          vim.notify("No definition found", vim.log.levels.WARN)
          return
        end

        -- Handle both single result and array of results
        local location = result[1] or result
        local uri = location.uri or location.targetUri
        
        if not uri then
          vim.notify("Could not get file path", vim.log.levels.WARN)
          return
        end

        -- Convert URI to file path
        local filepath = vim.uri_to_fname(uri)
        
        -- Get line number if available
        local range = location.range or location.targetRange
        local line_num = range and (range.start.line + 1) or nil
        
        -- Format: filepath:line_number (if line number available)
        local path_with_line = line_num and (filepath .. ":" .. line_num) or filepath
        
        -- Copy to clipboard
        vim.fn.setreg("+", path_with_line)
        vim.fn.setreg('"', path_with_line)
        
        vim.notify("Copied: " .. path_with_line, vim.log.levels.INFO)
      end)
    end, { buffer = true, desc = "Copy File Path of Definition" })

    -- Copy current file path (absolute)
    vim.keymap.set("n", "<leader>yP", function()
      local filepath = vim.fn.expand("%:p")
      vim.fn.setreg("+", filepath)
      vim.fn.setreg('"', filepath)
      vim.notify("Copied: " .. filepath, vim.log.levels.INFO)
    end, { buffer = true, desc = "Copy Current File Path (absolute)" })

    -- Copy current file path (relative to project root)
    vim.keymap.set("n", "<leader>yr", function()
      local filepath = vim.fn.expand("%:.")
      vim.fn.setreg("+", filepath)
      vim.fn.setreg('"', filepath)
      vim.notify("Copied: " .. filepath, vim.log.levels.INFO)
    end, { buffer = true, desc = "Copy Current File Path (relative)" })
  end,
})
