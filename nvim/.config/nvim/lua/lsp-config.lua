-- from warp ai
local cmp = require("cmp")

-- Helper function to go to definition in a new tab
local function go_to_definition_new_tab()
	-- Save current position
	local current_buf = vim.api.nvim_get_current_buf()
	local current_pos = vim.api.nvim_win_get_cursor(0)
	
	-- Open new tab
	vim.cmd('tabnew')
	
	-- Set the buffer in new tab
	vim.api.nvim_set_current_buf(current_buf)
	vim.api.nvim_win_set_cursor(0, current_pos)
	
	-- Go to definition
	vim.lsp.buf.definition()
end

-- diagnostic setup
vim.diagnostic.config({
	virtual_text = true, -- Show errors inline
	signs = true, -- Show error signs in gutter
	underline = true, -- Underline errors
	update_in_insert = false, -- Don't show errors while typing
	severity_sort = true, -- Sort by severity
	float = {
		focusable = false,
		close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
		border = "rounded",
		source = "always", -- Show error source
		prefix = " ",
		scope = "cursor", -- Show errors for current line
	},
})

-- Add keymaps for viewing diagnostics
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open diagnostic float" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
-- <leader>lq: all diagnostics, errors first.
vim.keymap.set("n", "<leader>lq", function()
	local diags = vim.diagnostic.get(0)
	table.sort(diags, function(a, b) return a.severity < b.severity end)
	local items = vim.diagnostic.toqflist(diags)
	vim.fn.setloclist(0, {}, ' ', { title = 'Diagnostics', items = items })
	vim.cmd('lopen')
end, { desc = "Diagnostics sorted by severity" })
-- <leader>le: errors only.
vim.keymap.set("n", "<leader>le", function()
	vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Errors only" })

-- LSP debugging commands
vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<cr>", { desc = "LSP Info" })
vim.keymap.set("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "LSP Restart" })

-- Configure nvim-cmp with better sorting for function signatures
cmp.setup({
	snippet = {
		expand = function(args)
			vim.fn["vsnip#anonymous"](args.body)
		end,
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({
			select = true,
			behavior = cmp.ConfirmBehavior.Replace,
		}),
		["<Tab>"] = cmp.mapping(function(fallback)
		if cmp.visible() then
				cmp.select_next_item()
			elseif vim.fn["vsnip#available"](1) == 1 then
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(vsnip-expand-or-jump)", true, true, true), "")
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif vim.fn["vsnip#jumpable"](-1) == 1 then
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(vsnip-jump-prev)", true, true, true), "")
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "vsnip" },
		{ name = "buffer" },
		{ name = "path" },
	}),
	sorting = {
		priority_weight = 2,
		comparators = {
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			cmp.config.compare.score,
			cmp.config.compare.recently_used,
			cmp.config.compare.locality,
			-- Custom comparator to prioritize function signatures
			function(entry1, entry2)
				local kind1 = entry1:get_kind()
				local kind2 = entry2:get_kind()

				-- Prefer TypeParameter (function with params) over Function
				if
					kind1 == require("cmp").lsp.CompletionItemKind.TypeParameter
					and kind2 == require("cmp").lsp.CompletionItemKind.Function
				then
					return true
				elseif
					kind1 == require("cmp").lsp.CompletionItemKind.Function
					and kind2 == require("cmp").lsp.CompletionItemKind.TypeParameter
				then
					return false
				end

				return nil
			end,
			cmp.config.compare.kind,
			cmp.config.compare.sort_text,
			cmp.config.compare.length,
			cmp.config.compare.order,
		},
	},
	formatting = {
		format = function(entry, vim_item)
			if vim_item.kind == "TypeParameter" and entry.completion_item.detail then
				vim_item.kind = "Function"
				vim_item.menu = "[LSP-Sig]"
			elseif entry.completion_item.detail then
				-- Truncate detail to avoid verbose ty type signatures flooding the menu column.
				local detail = entry.completion_item.detail
				vim_item.menu = #detail > 40 and detail:sub(1, 40) .. "…" or detail
			else
				vim_item.menu = ({
					nvim_lsp = "[LSP]",
					vsnip = "[Snippet]",
					buffer = "[Buffer]",
					path = "[Path]",
				})[entry.source.name]
			end
			return vim_item
		end,
	},
	experimental = {
		ghost_text = true,
	},
	preselect = cmp.PreselectMode.Item,
	completion = {
		completeopt = "menu,menuone,noinsert,preview",
	},
})

-- Configure lsp_signature for parameter hints
local signature_config = {
	bind = true,
	handler_opts = {
		border = "rounded",
	},
	floating_window = true,
	floating_window_above_cur_line = true,
	hint_enable = false,
	hint_prefix = "",
	hint_scheme = "String",
	use_lspsaga = false,
	hi_parameter = "LspSignatureActiveParameter",
	max_height = 12,
	max_width = 120,
	extra_trigger_chars = { "(", "," },
	zindex = 200,
	debug = false,
}

-- Enhanced LSP capabilities
local capabilities = require("cmp_nvim_lsp").default_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
	properties = {
		"documentation",
		"detail",
		"additionalTextEdits",
		"insertText",
		"textEdit",
	},
}

-- pylsp: commented out in favour of ty as the sole Python LSP.
-- ty now has full LSP feature coverage (completion, hover, gd, references, rename, etc.)
-- To revert: uncomment this block, comment out the ty block below, and :LspRestart.
--
-- vim.lsp.config('pylsp', {
-- 	capabilities = capabilities,
-- 	settings = {
-- 		pylsp = {
-- 			plugins = {
-- 				pycodestyle = { enabled = true },
-- 				pyflakes = { enabled = true },
-- 				flake8 = { enabled = false },
-- 				pylint = { enabled = false },
-- 				yapf = { enabled = false },
-- 				autopep8 = { enabled = false },
-- 				black = { enabled = true, line_length = 120 },
-- 				jedi_completion = {
-- 					enabled = true, include_params = true,
-- 					include_class_objects = false, include_function_objects = true,
-- 					fuzzy = true, eager = false, resolve_at_most = 15,
-- 					cache_for = { "pandas", "numpy", "tensorflow", "matplotlib" },
-- 				},
-- 				jedi_hover = { enabled = true },
-- 				jedi_references = { enabled = true },
-- 				jedi_signature_help = { enabled = true },
-- 				jedi_symbols = { enabled = true, all_scopes = false, include_import_symbols = true },
-- 				rope_completion = { enabled = false },
-- 				rope_autoimport = { enabled = false },
-- 			},
-- 		},
-- 	},
-- 	on_attach = function(client, bufnr)
-- 		require("lsp_signature").on_attach(signature_config, bufnr)
-- 		if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
-- 			vim.lsp.inlay_hint.enable(bufnr, true)
-- 		end
-- 		local opts = { noremap = true, silent = true, buffer = bufnr }
-- 		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
-- 		vim.keymap.set("n", "<leader>gtd", go_to_definition_new_tab, opts)
-- 		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
-- 		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
-- 		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
-- 		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
-- 		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
-- 		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
-- 		vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, opts)
-- 		vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts)
-- 	end,
-- })
-- vim.lsp.enable('pylsp')

-- ty: sole Python LSP. Full-featured as of v0.0.59 (completion, hover, gd, references,
-- rename, code actions, inlay hints, signature help, workspace symbols).
-- Does NOT support: textDocument/implementation (gi), formatting (use ruff instead).
vim.lsp.config('ty', {
	cmd = { 'ty', 'server' },
	filetypes = { 'python' },
	root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
	capabilities = capabilities,
	on_attach = function(client, bufnr)
		require("lsp_signature").on_attach(signature_config, bufnr)

		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		-- Warm the workspace symbol index so the first search is fast.
		vim.lsp.buf_request(bufnr, 'workspace/symbol', { query = '' }, function() end)

		local opts = { noremap = true, silent = true, buffer = bufnr }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "<leader>gtd", go_to_definition_new_tab, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		-- gi (implementation) not supported by ty yet; omitted to avoid silent no-op.
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "grr", function()
			vim.lsp.buf.references(nil, {
				on_list = function(options)
					vim.fn.setqflist({}, ' ', options)
					vim.cmd('botright copen')
				end,
			})
		end, opts)
		-- <leader>f: formatting handled by ruff LSP (configured below).
		vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts)

		-- vsnip key mappings
		vim.keymap.set({ "i", "s" }, "<C-j>", function()
			if vim.fn["vsnip#available"](1) == 1 then
				return "<Plug>(vsnip-expand-or-jump)"
			else
				return "<C-j>"
			end
		end, { expr = true, buffer = bufnr })

		vim.keymap.set({ "i", "s" }, "<C-k>", function()
			if vim.fn["vsnip#jumpable"](-1) == 1 then
				return "<Plug>(vsnip-jump-prev)"
			else
				return "<C-k>"
			end
		end, { expr = true, buffer = bufnr })
	end,
})
vim.lsp.enable('ty')

-- ruff: linting + formatting for Python. Runs alongside ty (ty owns types/navigation,
-- ruff owns lint diagnostics and <leader>f formatting).
-- Activates in any Python project; respects pyproject.toml / ruff.toml automatically.
vim.lsp.config('ruff', {
	cmd = { 'ruff', 'server' },
	filetypes = { 'python' },
	root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
	capabilities = capabilities,
	on_attach = function(client, bufnr)
		-- ruff doesn't provide hover; let ty handle it.
		client.server_capabilities.hoverProvider = false
		local opts = { noremap = true, silent = true, buffer = bufnr }
		-- Restore <leader>f for formatting via ruff.
		vim.keymap.set("n", "<leader>f", function()
			vim.lsp.buf.format({ async = true, name = "ruff" })
		end, opts)
	end,
})
vim.lsp.enable('ruff')

-- vtsls: TypeScript/JavaScript LSP. Replaces typescript-language-server.
-- Built directly on tsserver — better feature parity with VSCode and faster on monorepos.
-- For rippling-webapp scale, bumps tsserver memory to 8GB.
vim.lsp.config('vtsls', {
	cmd = { 'vtsls', '--stdio' },
	filetypes = { 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },
	-- Prefer tsconfig.json (project root) over package.json (subpackage).
	-- .git as final fallback for monorepo root.
	root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
	capabilities = capabilities,
	settings = {
		vtsls = {
			experimental = {
				completion = {
					enableServerSideFuzzyMatch = true,
				},
			},
		},
		typescript = {
			tsserver = {
				maxTsServerMemory = 16384,
			},
			-- Inlay hints disabled — they're noisy and add memory pressure on huge repos.
			inlayHints = {
				includeInlayParameterNameHints = "none",
				includeInlayFunctionParameterTypeHints = false,
				includeInlayVariableTypeHints = false,
				includeInlayPropertyDeclarationTypeHints = false,
				includeInlayFunctionLikeReturnTypeHints = false,
				includeInlayEnumMemberValueHints = false,
			},
			suggest = {
				includeCompletionsForModuleExports = true,
				includeCompletionsWithInsertText = true,
			},
			preferences = {
				includeCompletionsWithSnippetText = true,
				includeCompletionsForImportStatements = true,
				-- "off" prevents tsserver from indexing every package.json in the
				-- workspace for auto-imports — biggest memory hog in monorepos.
				-- Auto-imports from already-imported files still work.
				includePackageJsonAutoImports = "off",
			},
		},
		javascript = {
			inlayHints = {
				includeInlayParameterNameHints = "none",
				includeInlayFunctionParameterTypeHints = false,
				includeInlayVariableTypeHints = false,
				includeInlayPropertyDeclarationTypeHints = false,
				includeInlayFunctionLikeReturnTypeHints = false,
				includeInlayEnumMemberValueHints = false,
			},
			suggest = {
				includeCompletionsForModuleExports = true,
				includeCompletionsWithInsertText = true,
			},
			preferences = {
				includeCompletionsWithSnippetText = true,
				includeCompletionsForImportStatements = true,
				includePackageJsonAutoImports = "off",
			},
		},
	},
	on_attach = function(client, bufnr)
		require("lsp_signature").on_attach(signature_config, bufnr)

		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		-- Warm the workspace symbol index so the first search is fast.
		vim.lsp.buf_request(bufnr, 'workspace/symbol', { query = '' }, function() end)

		local opts = { noremap = true, silent = true, buffer = bufnr }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "<leader>gtd", go_to_definition_new_tab, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<leader>f", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
		vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts)

		-- vsnip mappings
		vim.keymap.set({ "i", "s" }, "<C-j>", function()
			if vim.fn["vsnip#available"](1) == 1 then
				return "<Plug>(vsnip-expand-or-jump)"
			else
				return "<C-j>"
			end
		end, { expr = true, buffer = bufnr })

		vim.keymap.set({ "i", "s" }, "<C-k>", function()
			if vim.fn["vsnip#jumpable"](-1) == 1 then
				return "<Plug>(vsnip-jump-prev)"
			else
				return "<C-k>"
			end
		end, { expr = true, buffer = bufnr })
	end,
})
vim.lsp.enable('vtsls')

-- Lua Language Server
vim.lsp.config('lua_ls', {
	capabilities = capabilities,
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			telemetry = { enable = false },
			completion = {
				callSnippet = "Both",
				keywordSnippet = "Both",
				postfix = ".",
			},
			hint = {
				enable = true,
				paramType = true,
				paramName = "All",
			},
			format = { enable = false },
		},
	},
	on_attach = function(client, bufnr)
		client.server_capabilities.documentFormattingProvider = false
		require("lsp_signature").on_attach(signature_config, bufnr)

		-- Neovim nightly inlay hints
		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		local opts = { noremap = true, silent = true, buffer = bufnr }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "<leader>gtd", go_to_definition_new_tab, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<leader>f", function()
			local file = vim.api.nvim_buf_get_name(0)
			if file ~= "" then
				vim.cmd("silent !stylua " .. file)
				vim.cmd("edit")
			end
		end, opts)
		vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts)

		-- vsnip mappings
		vim.keymap.set({ "i", "s" }, "<C-j>", function()
			if vim.fn["vsnip#available"](1) == 1 then
				return "<Plug>(vsnip-expand-or-jump)"
			else
				return "<C-j>"
			end
		end, { expr = true, buffer = bufnr })

		vim.keymap.set({ "i", "s" }, "<C-k>", function()
			if vim.fn["vsnip#jumpable"](-1) == 1 then
				return "<Plug>(vsnip-jump-prev)"
			else
				return "<C-k>"
			end
		end, { expr = true, buffer = bufnr })
	end,
})
vim.lsp.enable('lua_ls')

-- Additional servers setup
local servers = { "ccls" }
for _, lsp in ipairs(servers) do
	vim.lsp.config(lsp, {
		capabilities = capabilities,
		on_attach = function(client, bufnr)
			-- Setup lsp_signature for this buffer
			require("lsp_signature").on_attach(signature_config, bufnr)

			local opts = { noremap = true, silent = true, buffer = bufnr }
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
			vim.keymap.set("n", "<leader>gtd", go_to_definition_new_tab, opts)
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
			vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
			vim.keymap.set("n", "<leader>f", function()
				vim.lsp.buf.format({ async = true })
			end, opts)
		end,
		-- root_dir = lspconfig.util.root_pattern('.git');
	})
    vim.lsp.enable(lsp)
end

--
