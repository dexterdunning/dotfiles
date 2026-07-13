-- nvim-treesitter rewrite (2025+): parsers install via :TSInstall (needs tree-sitter CLI).

local M = {}

M._pending = {}

local function warn_missing_cli()
	if vim.g.dexter_ts_cli_warned then
		return
	end
	vim.g.dexter_ts_cli_warned = true
	vim.notify(
		"tree-sitter CLI not found. Run: brew install tree-sitter\nThen: :TSInstall python",
		vim.log.levels.WARN,
		{ title = "nvim-treesitter" }
	)
end

function M.ensure_parser(lang)
	if not lang then
		return false
	end

	local installed = require("nvim-treesitter").get_installed("parsers")
	if vim.list_contains(installed, lang) then
		return true
	end

	if vim.fn.executable("tree-sitter") ~= 1 then
		warn_missing_cli()
		return false
	end

	if M._pending[lang] then
		return false
	end
	M._pending[lang] = true

	vim.notify("Installing treesitter parser: " .. lang, vim.log.levels.INFO, { title = "nvim-treesitter" })
	require("nvim-treesitter").install({ lang })
	return false
end

function M.setup_buffer()
	if vim.b.dexter_ts_configured then
		return
	end

	local ft = vim.bo.filetype
	if ft == "" or vim.wo.diff or vim.api.nvim_buf_get_name(0):match("^diffview://") then
		return
	end

	local lang = vim.treesitter.language.get_lang(ft)
	if not lang or not M.ensure_parser(lang) then
		return
	end

	vim.treesitter.start(0, lang)

	vim.wo[0][0].foldmethod = "expr"
	vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
	vim.wo[0][0].foldlevel = 99
	vim.wo[0][0].foldenable = true
	vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

	vim.b.dexter_ts_configured = true
	vim.cmd("normal! zx")
end

require("nvim-treesitter").setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})

local group = vim.api.nvim_create_augroup("dexter_treesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	callback = function()
		vim.schedule(M.setup_buffer)
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	group = group,
	callback = function()
		vim.schedule(M.setup_buffer)
	end,
})

return M
