-- OpenCode AI Assistant Integration for LazyVim
-- Popup dialog for quick AI questions
-- https://opencode.ai

return {
  {
    name = "opencode",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    config = function()
      local function show_opencode_result(question, context)
        local buf = vim.api.nvim_create_buf(false, true)

        -- Loading message
        local loading = { "OpenCode is thinking...", "", "Question: " .. question }
        if context then
          vim.list_extend(loading, { "", "Context:", string.rep("-", 40) })
          vim.list_extend(loading, context)
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, loading)

        -- Floating window (80% of screen)
        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.8)
        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          row = math.floor((vim.o.lines - height) / 2),
          col = math.floor((vim.o.columns - width) / 2),
          style = "minimal",
          border = "rounded",
          title = " OpenCode ",
          title_pos = "center",
        })

        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].filetype = "markdown"
        vim.bo[buf].modifiable = false

        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
        vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })

        -- Build prompt
        local prompt
        if context then
          prompt = string.format("Question: %s\n\nCode context:\n```\n%s\n```", question, table.concat(context, "\n"))
        else
          prompt = "Answer concisely: " .. question
        end

        local cmd_args = {
          "opencode",
          "run",
          "--format",
          "json",
          "--model",
          "github-copilot/claude-sonnet-4.5",
          prompt,
        }

        local content_lines = {}
        local has_error = false

        local function update_buf(lines)
          if vim.api.nvim_buf_is_valid(buf) then
            vim.bo[buf].modifiable = true
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.bo[buf].modifiable = false
          end
        end

        -- Timeout
        local timeout_timer = vim.defer_fn(function()
          vim.schedule(function()
            if #content_lines == 0 and not has_error then
              update_buf({
                "Question: " .. question,
                "",
                "Timeout: No response received within 15 seconds.",
                "",
                "Press 'q' or <Esc> to close",
              })
            end
          end)
        end, 15000)

        vim.fn.jobstart(cmd_args, {
          stdout_buffered = false,
          on_stdout = function(_, data)
            if not data then
              return
            end
            vim.schedule(function()
              for _, line in ipairs(data) do
                if line ~= "" then
                  local ok, json = pcall(vim.json.decode, line)
                  if ok then
                    if json.type == "error" then
                      if timeout_timer then
                        vim.fn.timer_stop(timeout_timer)
                      end
                      has_error = true
                      local msg = "Unknown error"
                      if json.error and json.error.data and json.error.data.message then
                        msg = json.error.data.message
                      elseif json.error and json.error.message then
                        msg = json.error.message
                      end
                      local lines_out = { "Question: " .. question, "", "Error:", string.rep("-", 40) }
                      for err_line in msg:gmatch("[^\r\n]+") do
                        table.insert(lines_out, err_line)
                      end
                      table.insert(lines_out, "")
                      table.insert(lines_out, "Press 'q' or <Esc> to close")
                      update_buf(lines_out)
                    elseif
                      (json.type == "content" and json.content)
                      or (json.type == "text" and json.part and json.part.text)
                    then
                      local text = json.content or (json.part and json.part.text) or ""
                      for cl in (text .. "\n"):gmatch("([^\r\n]*)\r?\n") do
                        table.insert(content_lines, cl)
                      end
                      local lines_out = { "Question: " .. question, "", "Answer:", string.rep("-", 40), "" }
                      vim.list_extend(lines_out, content_lines)
                      if context then
                        vim.list_extend(lines_out, { "", string.rep("-", 40), "Code Context:", "" })
                        for _, ctx_line in ipairs(context) do
                          table.insert(lines_out, "  " .. ctx_line)
                        end
                      end
                      table.insert(lines_out, "")
                      table.insert(lines_out, "Streaming... Press 'q' or <Esc> to close")
                      update_buf(lines_out)
                    end
                  end
                end
              end
            end)
          end,
          on_exit = function(_, exit_code)
            vim.schedule(function()
              if timeout_timer then
                vim.fn.timer_stop(timeout_timer)
              end
              if not has_error and #content_lines == 0 then
                update_buf({
                  "Question: " .. question,
                  "",
                  "No response from OpenCode (exit " .. exit_code .. ").",
                  "",
                  "Press 'q' or <Esc> to close",
                })
              elseif #content_lines > 0 and vim.api.nvim_buf_is_valid(buf) then
                local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                for i, l in ipairs(current) do
                  if l:match("Streaming%.%.%.") then
                    current[i] = "Complete. Press 'q' or <Esc> to close"
                    update_buf(current)
                    break
                  end
                end
              end
            end)
          end,
        })
      end

      local function opencode_popup()
        local question = vim.fn.input("Ask OpenCode: ")
        if question ~= "" then
          show_opencode_result(question, nil)
        end
      end

      local function get_visual_lines()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.fn.getline(start_pos[2], end_pos[2])
        if #lines == 0 then
          return nil
        end
        if #lines == 1 then
          lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
        else
          if start_pos[3] > 0 and start_pos[3] <= #lines[1] then
            lines[1] = string.sub(lines[1], start_pos[3])
          end
          if end_pos[3] > 0 and end_pos[3] <= #lines[#lines] then
            lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
          end
        end
        return lines
      end

      vim.keymap.set("n", "<leader>a", opencode_popup, { desc = "OpenCode Quick Ask", silent = true })
      vim.keymap.set("x", "<leader>a", function()
        local lines = get_visual_lines()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
        vim.defer_fn(function()
          if not lines or #lines == 0 then
            vim.notify("No selection", vim.log.levels.WARN)
            return
          end
          local question = vim.fn.input("Ask about this code: ")
          if question ~= "" then
            show_opencode_result(question, lines)
          end
        end, 10)
      end, { desc = "OpenCode Ask About Code", silent = true })
    end,
  },
}
