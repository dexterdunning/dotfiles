-- avante.nvim configuration using cde claude as proxy
require("avante").setup({
  provider = "claude",
  providers = {
    claude = {
      __inherited_from = "openai",
      endpoint = "local",
      model = "claude",
      ["local"] = true,
      api_key_name = "",
      timeout = 30000,
      -- Use our wrapper script to call cde claude
      parse_curl_args = function(opts, code_opts)
        -- Extract the prompt from the messages
        local prompt = ""
        if opts.messages then
          for _, message in ipairs(opts.messages) do
            if message.role == "user" then
              prompt = message.content
              break
            end
          end
        end
        return {
          url = "local",
          headers = {},
          body = prompt,
        }
      end,
      parse_response_data = function(data_stream, event_state, opts)
        -- Call our wrapper script
        local handle = io.popen('echo "' .. (opts.body or "") .. '" | /Users/dexter/projects/rippling-main/cde-claude-wrapper.sh')
        local result = handle:read("*a")
        handle:close()
        return result or ""
      end,
    },
  },
  behaviour = {
    auto_suggestions = false, -- Set to true if you want auto suggestions
    auto_set_highlight_group = true,
    auto_set_keymaps = true,
    auto_apply_diff_after_generation = false,
    support_paste_from_clipboard = false,
  },
  mappings = {
    --- @class AvanteConflictMappings
    diff = {
      ours = "co",
      theirs = "ct",
      all_theirs = "ca",
      both = "cb",
      cursor = "cc",
      next = "]x",
      prev = "[x",
    },
    suggestion = {
      accept = "<M-l>",
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
    jump = {
      next = "]]",
      prev = "[[",
    },
    submit = {
      normal = "<CR>",
      insert = "<C-s>",
    },
    sidebar = {
      apply_all = "A",
      apply_cursor = "a",
      switch_windows = "<Tab>",
      reverse_switch_windows = "<S-Tab>",
    },
  },
  hints = { enabled = true },
  windows = {
    ---@type "right" | "left" | "top" | "bottom"
    position = "right", -- the position of the sidebar
    wrap = true, -- similar to vim.o.wrap
    width = 30, -- default % based on available width
    sidebar_header = {
      align = "center", -- left, center, right for title
      rounded = true,
    },
  },
  highlights = {
    ---@type AvanteConflictHighlights
    diff = {
      current = "DiffText",
      incoming = "DiffAdd",
    },
  },
  --- @class AvanteConflictUserConfig
  diff = {
    autojump = true,
    ---@type string | fun(): string
    list_opener = "copen",
  },
})
