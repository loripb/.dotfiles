return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.format_on_save = nil

      local format_modified = function(bufnr)
        local ignore_filetypes = { "lua" }
        if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
          return
        end

        local hunks = require("gitsigns").get_hunks(bufnr)

        -- If no hunks (or not git), do nothing
        if not hunks then
          return
        end

        -- 1. Collect all valid ranges from hunks first
        local ranges = {}
        for _, hunk in ipairs(hunks) do
          local start_line = hunk.added.start
          local end_line = start_line + hunk.added.count
          start_line = math.max(1, start_line)
          end_line = math.max(start_line, end_line)

          table.insert(ranges, {
            start = { start_line, 0 },
            ["end"] = { end_line, 0 },
          })
        end

        -- 2. Define a recursive function to process ranges sequentially
        -- We process in reverse (popping from the end) to preserve line numbers
        local function format_next()
          if #ranges == 0 then
            return
          end

          local range = table.remove(ranges) -- Pops the last element (reverse order)

          require("conform").format({
            bufnr = bufnr,
            range = range,
            lsp_fallback = true,
            -- FIXED: Suppress error popups when Rubocop returns exit code 1
            notify_on_error = false,
            quiet = true,
          }, function(err, did_edit)
            -- FIXED: Only call the next format AFTER the current one finishes
            format_next()
          end)
        end

        -- 3. Kick off the chain
        format_next()
      end

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*",
        callback = function(args)
          format_modified(args.buf)
        end,
      })
    end,
  },
}
