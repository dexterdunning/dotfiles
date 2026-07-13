require("octo").setup({
	picker = "telescope",
	enable_builtin = true,
	use_local_fs = true,
	reviews = {
		-- Don't steal the alternate pane on every cursor move.
		auto_show_threads = false,
		focus = "right",
	},
	picker_config = {
		mappings = {
			open_in_browser = { lhs = "<C-b>", desc = "open in browser" },
			copy_url = { lhs = "<C-y>", desc = "copy url" },
			checkout_pr = { lhs = "<C-o>", desc = "checkout pull request" },
		},
	},
	mappings = {
		review_diff = {
			add_review_comment = { lhs = "gcc", desc = "add review comment", mode = { "n", "x" } },
			add_review_suggestion = { lhs = "gcs", desc = "add review suggestion", mode = { "n", "x" } },
			submit_review = { lhs = "<leader>oS", desc = "submit review" },
			next_thread = { lhs = "]t", desc = "next thread" },
			prev_thread = { lhs = "[t", desc = "prev thread" },
			select_next_entry = { lhs = "]q", desc = "next file" },
			select_prev_entry = { lhs = "[q", desc = "prev file" },
		},
		review_thread = {
			add_reply = { lhs = "gcc", desc = "reply", mode = { "n", "i" } },
		},
	},
})
