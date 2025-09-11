local nvim_lsp = require("lspconfig")

-- from warp ai
local cmp = require("cmp")
local lspconfig = require("lspconfig")

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
			-- Custom formatting to make function signatures more prominent
			if vim_item.kind == "TypeParameter" and entry.completion_item.detail then
				vim_item.kind = "Function"
				vim_item.menu = "[LSP-Sig]"
			elseif entry.completion_item.detail then
				vim_item.menu = entry.completion_item.detail
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

-- Configure pylsp with refined settings to reduce duplicates
lspconfig.pylsp.setup({
	capabilities = capabilities,
	settings = {
		pylsp = {
			plugins = {
				pycodestyle = { enabled = true },
				pyflakes = { enabled = true },

				-- Disable some conflicting plugins
				flake8 = { enabled = false },
				pylint = { enabled = false },

				-- disable other formatters
				yapf = { enabled = false },
				autopep8 = { enabled = false },

				-- Optional: Enable black for formatting
				black = {
					enabled = true,
					line_length = 120,
				},

				-- Enable Jedi for completion with parameters
				jedi_completion = {
					enabled = true,
					include_params = true,
					include_class_objects = false, -- Reduce duplicates
					include_function_objects = true,
					fuzzy = true,
					eager = false,
					resolve_at_most = 15, -- Reduce to avoid too many options
					cache_for = { "pandas", "numpy", "tensorflow", "matplotlib" },
				},
				jedi_hover = { enabled = true },
				jedi_references = { enabled = true },
				jedi_signature_help = { enabled = true },
				jedi_symbols = {
					enabled = true,
					all_scopes = false, -- Reduce duplicates
					include_import_symbols = true,
				},

				-- Disable rope completion to avoid duplicates
				rope_completion = { enabled = false },
				rope_autoimport = { enabled = false },
			},
		},
	},
	on_attach = function(client, bufnr)
		-- Setup lsp_signature for this buffer
		require("lsp_signature").on_attach(signature_config, bufnr)

		if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
			vim.lsp.inlay_hint.enable(bufnr, true)
		end

		local opts = { noremap = true, silent = true, buffer = bufnr }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
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

-- TypScript/JavaScript Language Server
lspconfig.ts_ls.setup({
	capabilities = capabilities,
	init_options = {
		preferences = {
			includeCompletionsForModuleExports = true,
			includeCompletionsWithInsertText = true,
		},
	},
	settings = {
		typescript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = false, -- Reduce noise
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = false, -- Reduce noise
				includeInlayEnumMemberValueHints = true,
			},
			suggest = {
				includeCompletionsForModuleExports = true,
				includeCompletionsWithInsertText = true,
			},
			preferences = {
				includeCompletionsWithSnippetText = true, -- Key for parameter completion
				includeCompletionsForImportStatements = true,
			},
		},
		javascript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = false,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = false,
				includeInlayEnumMemberValueHints = true,
			},
			suggest = {
				includeCompletionsForModuleExports = true,
				includeCompletionsWithInsertText = true,
			},
			preferences = {
				includeCompletionsWithSnippetText = true,
				includeCompletionsForImportStatements = true,
			},
		},
	},
	on_attach = function(client, bufnr)
		require("lsp_signature").on_attach(signature_config, bufnr)

		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		local opts = { noremap = true, silent = true, buffer = bufnr }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
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

-- Lua Language Server
lspconfig.lua_ls.setup({
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

-- -- ------------------------------------
-- -- nvim-cmp setup
-- -- ------------------------------------
-- local cmp = require'cmp'
-- -- local luasnip = require'luasnip'

-- -- local has_words_before = function()
-- --   local cursor = vim.api.nvim_win_get_cursor(0)
-- --   return (vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], true)[1] or ''):sub(cursor[2], cursor[2]):match('%s')
-- -- end
-- local has_words_before = function()
--   local line, col = unpack(vim.api.nvim_win_get_cursor(0))
--   return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
-- end

-- local feedkey = function(key, mode)
--   vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
-- end

-- cmp.setup({
--     snippet = {
--       expand = function(args)
--         vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
--         -- luasnip.lsp_expand(args.body) -- For `luasnip` users.
--       end,
--     },
--     window = {
--       completion = cmp.config.window.bordered(),
--       documentation = cmp.config.window.bordered(),lspcon
--     },
--     mapping = cmp.mapping.preset.insert({
--       ['<C-b>'] = cmp.mapping.scroll_docs(-4),
--       ['<C-f>'] = cmp.mapping.scroll_docs(4),
--       ['<Tab>'] = cmp.mapping.complete(),
--       ['<C-e>'] = cmp.mapping.abort(),
--       ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.

--     ["<Tab>"] = cmp.mapping(function(fallback)
--       if cmp.visible() then
--         cmp.select_next_item()
--       elseif vim.fn["vsnip#available"](1) == 1 then
--         feedkey("<Plug>(vsnip-expand-or-jump)", "")
--       elseif has_words_before() then
--         cmp.complete()
--       else
--         fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
--       end
--     end, { "i", "s" }),
--     ["<S-Tab>"] = cmp.mapping(function()
--       if cmp.visible() then
--         cmp.select_prev_item()
--       elseif vim.fn["vsnip#jumpable"](-1) == 1 then
--         feedkey("<Plug>(vsnip-jump-prev)", "")
--       end
--     end, { "i", "s" }),

--       -- ["<Tab>"] = cmp.mapping(function(fallback)
--       --     if cmp.visible() then
--       --       cmp.select_next_item()
--       --     elseif has_words_before() and luasnip.expand_or_jumpable() then
--       --       cmp.complete()
--       --     else
--       --       fallback()
--       --     end
--       -- end, { "i", "s" })
--     }),
--     sources = cmp.config.sources({
--       { name = 'nvim_lsp' },
--       -- { name = 'luasnip' },
--       { name = 'vsnip' },
--     }, {
--       { name = 'buffer' },
--     })
-- })

-- -- Set configuration for specific filetype.
-- cmp.setup.filetype('gitcommit', {
--     sources = cmp.config.sources({
--       { name = 'git' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
--     }, {
--       { name = 'buffer' },
--     })
-- })

-- -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
-- cmp.setup.cmdline({ '/', '?' }, {
--     mapping = cmp.mapping.preset.cmdline(),
--     sources = {
--       { name = 'buffer' }
--     }
-- })

-- -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
-- cmp.setup.cmdline(':', {
--     mapping = cmp.mapping.preset.cmdline(),
--     sources = cmp.config.sources(
--         {{ name = 'path' }},
--         {{ name = 'cmdline' }}
--     )
-- })

-- local cmp_capabilities = require('cmp_nvim_lsp').default_capabilities()

-- -- ------------------------------------
-- -- Python
-- --
-- -- https://github.com/python-lsp/python-lsp-server
-- -- ------------------------------------
-- local python_on_attach = function(client, bufnr)
--   -- Enable completion triggered by <c-x><c-o>
--   vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

--   -- Mappings.
--   -- See `:help vim.lsp.*` for documentation on any of the below functions
--   local bufopts = { noremap=true, silent=true, buffer=bufnr }
--   vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
--   vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
--   vim.keymap.set('n', 'K', vim.lsp.buf.hover)
--   vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
--   vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
--   vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
--   vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
--   -- vim.keymap.set('n', '<space>wl', function()
--   --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
--   -- end, bufopts)
--   vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
--   vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
--   vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
--   vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
--   vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
-- end

-- -- nvim_lsp.pylsp.setup{
-- --     on_attach = python_on_attach,
-- --     capabilities = cmp_capabilities,
-- -- }

-- local pyright_opts = {
--   single_file_support = true,
--   settings = {
--     pyright = {
--       disableLanguageServices = false,
--       disableOrganizeImports = false
--     },
--     python = {
--       analysis = {
--         autoImportCompletions = true,
--         autoSearchPaths = true,
--         diagnosticMode = "workspace", -- openFilesOnly, workspace
--         typeCheckingMode = "basic", -- off, basic, strict
--         useLibraryCodeForTypes = true
--       }
--     }
--   },
-- }

-- nvim_lsp.pyright.setup{
--     on_attach = python_on_attach,
--     capabilities = cmp_capabilities,
--   single_file_support = true,
--   settings = {
--     pyright = {
--       disableLanguageServices = false,
--       disableOrganizeImports = false
--     },
--     python = {
--       analysis = {
--         autoImportCompletions = true,
--         autoSearchPaths = true,
--         diagnosticMode = "workspace", -- openFilesOnly, workspace
--         typeCheckingMode = "basic", -- off, basic, strict
--         useLibraryCodeForTypes = true
--       }
--     }
--   },
-- }

-- ------------------------------------
-- Typescript
-- ------------------------------------

-- local format_async = function(err, _, result, _, bufnr)
--     if err ~= nil or result == nil then return end
--     if not vim.api.nvim_buf_get_option(bufnr, "modified") then
--         local view = vim.fn.winsaveview()
--         vim.lsp.util.apply_text_edits(result, bufnr)
--         vim.fn.winrestview(view)
--         if bufnr == vim.api.nvim_get_current_buf() then
--             vim.api.nvim_command("noautocmd :update")
--         end
--     end
-- end
-- vim.lsp.handlers["textDocument/formatting"] = format_async
-- _G.lsp_organize_imports = function()
--     local params = {
--         command = "_typescript.organizeImports",
--         arguments = {vim.api.nvim_buf_get_name(0)},
--         title = ""
--     }
--     vim.lsp.buf.execute_command(params)
-- end
-- local on_attach_ts = function(client, bufnr)
--     local buf_map = vim.api.nvim_buf_set_keymap
--     vim.cmd("command! LspDef lua vim.lsp.buf.definition()")
--     vim.cmd("command! LspFormatting lua vim.lsp.buf.formatting()")
--     vim.cmd("command! LspCodeAction lua vim.lsp.buf.code_action()")
--     vim.cmd("command! LspHover lua vim.lsp.buf.hover()")
--     vim.cmd("command! LspRename lua vim.lsp.buf.rename()")
--     vim.cmd("command! LspOrganize lua lsp_organize_imports()")
--     vim.cmd("command! LspRefs lua vim.lsp.buf.references()")
--     vim.cmd("command! LspTypeDef lua vim.lsp.buf.type_definition()")
--     vim.cmd("command! LspImplementation lua vim.lsp.buf.implementation()")
--     vim.cmd("command! LspDiagPrev lua vim.lsp.diagnostic.goto_prev()")
--     vim.cmd("command! LspDiagNext lua vim.lsp.diagnostic.goto_next()")
--     vim.cmd(
--         "command! LspDiagLine lua vim.lsp.diagnostic.show_line_diagnostics()")
--     vim.cmd("command! LspSignatureHelp lua vim.lsp.buf.signature_help()")
--     buf_map(bufnr, "n", "gd", ":LspDef<CR>", {silent = true})
--     buf_map(bufnr, "n", "gr", ":LspRename<CR>", {silent = true})
--     buf_map(bufnr, "n", "gR", ":LspRefs<CR>", {silent = true})
--     buf_map(bufnr, "n", "gy", ":LspTypeDef<CR>", {silent = true})
--     buf_map(bufnr, "n", "K", ":LspHover<CR>", {silent = true})
--     buf_map(bufnr, "n", "gs", ":LspOrganize<CR>", {silent = true})
--     buf_map(bufnr, "n", "[a", ":LspDiagPrev<CR>", {silent = true})
--     buf_map(bufnr, "n", "]a", ":LspDiagNext<CR>", {silent = true})
--     buf_map(bufnr, "n", "ga", ":LspCodeAction<CR>", {silent = true})
--     buf_map(bufnr, "n", "<Leader>a", ":LspDiagLine<CR>", {silent = true})
--     buf_map(bufnr, "i", "<C-x><C-x>", "<cmd> LspSignatureHelp<CR>",
--               {silent = true})
-- end
-- nvim_lsp.ts_ls.setup {
--     on_attach_ts = on_attach_ts,
--     capabilities = cmp_capabilities,
-- }
-- local filetypes = {
--     typescript = "eslint",
--     typescriptreact = "eslint",
-- }
-- local linters = {
--     eslint = {
--         sourceName = "eslint",
--         command = "eslint_d",
--         rootPatterns = {".eslintrc.js", "package.json"},
--         debounce = 100,
--         args = {"--stdin", "--stdin-filename", "%filepath", "--format", "json"},
--         parseJson = {
--             errorsRoot = "[0].messages",
--             line = "line",
--             column = "column",
--             endLine = "endLine",
--             endColumn = "endColumn",
--             message = "${message} [${ruleId}]",
--             security = "severity"
--         },
--         securities = {[2] = "error", [1] = "warning"}
--     }
-- }
-- local formatters = {
--     prettier = {command = "prettier", args = {"--stdin-filepath", "%filepath"}}
-- }
-- local formatFiletypes = {
--     typescript = "prettier",
--     typescriptreact = "prettier"
-- }
-- nvim_lsp.diagnosticls.setup {
--     on_attach = on_attach,
--     filetypes = vim.tbl_keys(filetypes),
--     init_options = {
--         filetypes = filetypes,
--         linters = linters,
--         formatters = formatters,
--         formatFiletypes = formatFiletypes
--     }
-- }

-- ------------------------------------
-- nvim-lsp setup
-- ------------------------------------

-- local on_attach = function(client, bufnr)
--     require "lsp_signature".on_attach()  -- Note: add in lsp client on-attach
-- end

-- vim.o.completeopt = "menuone,noselect"
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities.textDocument.completion.completionItem.snippetSupport = true

-- OS dependent stuff
-- local servers
-- if vim.loop.os_uname().sysname == "Linux" then
--     -- local servers = { "ccls", "omnisharp", "pyls", "vimls", "dartls" }
--     servers = { "ccls", "omnisharp", "pyls", "vimls" }
-- end

servers = { "ccls" }
for _, lsp in ipairs(servers) do
	nvim_lsp[lsp].setup({
		capabilities = capabilities,
		on_attach = on_attach,
		-- root_dir = nvim_lsp.util.root_pattern('.git');
	})
end

--
