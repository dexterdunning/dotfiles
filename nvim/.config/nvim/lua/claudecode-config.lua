-- claudecode.nvim configuration
require("claudecode").setup({
	-- Use your custom cde claude command
	terminal_cmd = "claude",

	-- Window configuration
	window = {
		position = "right", -- Can be "left", "right", "top", "bottom"
		width = 0.4, -- 40% of screen width
		height = 1.0, -- 100% of screen height
	},

  -- Auto-start behavior
  auto_start = true,  -- Auto-start WebSocket server on nvim launch

	-- Enable selection tracking for real-time context
	track_selection = true,
	visual_demotion_delay_ms = 50,

	-- Send/Focus Behavior
	-- When true, successful sends will focus the Claude terminal if already connected
	focus_after_send = false,
})

-- Disable auto-scrolling in Claude Code terminal buffer
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*cde claude*",
	callback = function()
		-- Disable automatic scrolling to bottom on terminal output
		vim.opt_local.scrolloff = 999 -- Keep cursor centered

		-- Optional: Set scrollback buffer size
		vim.bo.scrollback = 100000
	end,
})

-- Key mappings for claudecode
-- Toggle Claude Code terminal
vim.keymap.set("n", "<leader>cc", ":ClaudeCode<CR>", { desc = "Toggle Claude Code Terminal" })

-- Focus/toggle Claude Code terminal (smart focus)
vim.keymap.set("n", "<leader>cf", ":ClaudeCodeFocus<CR>", { desc = "Focus Claude Code Terminal" })

-- Send visual selection to Claude (changed from <leader>cs to <leader>as per plugin default)
vim.keymap.set("v", "<leader>as", ":ClaudeCodeSend<CR>", { desc = "Send Selection to Claude" })

-- Select Claude model and open terminal
vim.keymap.set("n", "<leader>cm", ":ClaudeCodeSelectModel<CR>", { desc = "Select Claude Model" })

-- Add current file to Claude context (changed from <leader>ca to avoid LSP conflict)
vim.keymap.set("n", "<leader>caa", ":ClaudeCodeAdd %<CR>", { desc = "Add Current File to Claude Context" })
vim.keymap.set("v", "<leader>as", ":ClaudeCodeSend<CR>", { desc = "Send Selection to Claude" })
