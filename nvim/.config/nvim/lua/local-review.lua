local M = {}

local NS = vim.api.nvim_create_namespace("local_review")

local function git_root()
	local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
	if vim.v.shell_error ~= 0 or not out[1] then
		return nil
	end
	return out[1]
end

function M.review_file()
	local root = git_root()
	if not root then
		return nil
	end
	return root .. "/.review.local.jsonl"
end

---@param bufnr integer
---@return string|nil rel_path
function M.buf_rel_path(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return nil
	end

	local root = git_root()
	if not root then
		return nil
	end

	local ok, lib = pcall(require, "diffview.lib")
	if ok and lib.views then
		for _, view in ipairs(lib.views) do
			if view.cur_entry and view.cur_entry.layout and view.cur_entry.layout.files then
				for _, file in ipairs(view.cur_entry.layout:files()) do
					if file.bufnr == bufnr and file.path then
						return file.path
					end
				end
			end
		end
	end

	if vim.startswith(name, "diffview://") then
		local prefix = "diffview://" .. root .. "/"
		if vim.startswith(name, prefix) then
			local rest = name:sub(#prefix + 1)
			local rel = rest:match("^[^/]+/(.+)$")
			if rel then
				return rel
			end
		end
	end

	local abs = vim.fn.fnamemodify(name, ":p")
	if vim.startswith(abs, root .. "/") or abs == root then
		return vim.fn.fnamemodify(abs, ":~:.")
	end

	return nil
end

function M.resolve_location(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local rel = M.buf_rel_path(bufnr)
	if not rel then
		return nil
	end
	local source = vim.api.nvim_buf_get_name(bufnr):match("^diffview://") and "diffview" or "buffer"
	return rel, line, source
end

local function read_body_from_comment_buf(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local body = {}
	for _, line in ipairs(lines) do
		if not line:match("^%s*#") then
			table.insert(body, line)
		end
	end
	while #body > 0 and body[#body]:match("^%s*$") do
		table.remove(body, #body)
	end
	while #body > 0 and body[1]:match("^%s*$") do
		table.remove(body, 1)
	end
	return table.concat(body, "\n")
end

function M.append_comment(entry)
	local path = M.review_file()
	if not path then
		vim.notify("local-review: not inside a git repo", vim.log.levels.ERROR)
		return false
	end

	local f = io.open(path, "a")
	if not f then
		vim.notify("local-review: cannot write " .. path, vim.log.levels.ERROR)
		return false
	end

	entry.ts = os.date("!%Y-%m-%dT%H:%M:%SZ")
	local branch = vim.fn.systemlist({ "git", "rev-parse", "--abbrev-ref", "HEAD" })
	if vim.v.shell_error == 0 and branch[1] then
		entry.branch = branch[1]
	end

	f:write(vim.json.encode(entry) .. "\n")
	f:close()
	M.refresh_signs()
	vim.notify(string.format("local-review: %s:%d", entry.path, entry.line), vim.log.levels.INFO)
	return true
end

function M.submit_buffer(bufnr, path, line, source)
	local text = read_body_from_comment_buf(bufnr)
	if text == "" then
		vim.notify("local-review: empty comment, not saved", vim.log.levels.WARN)
		return false
	end
	return M.append_comment({
		path = path,
		line = line,
		source = source,
		text = text,
	})
end

local function close_comment_window(bufnr, parent_win, force)
	local win = vim.fn.bufwinid(bufnr)
	if win > 0 then
		vim.api.nvim_win_close(win, force == true)
	end
	vim.schedule(function()
		if vim.api.nvim_buf_is_valid(bufnr) then
			pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
		end
	end)
	if parent_win and vim.api.nvim_win_is_valid(parent_win) then
		vim.api.nvim_set_current_win(parent_win)
	end
end

function M.start()
	local path, line, source = M.resolve_location()
	if not path then
		vim.notify("local-review: no file/line for this buffer", vim.log.levels.ERROR)
		return
	end

	local parent_win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		string.format("# %s:%d", path, line),
		"# :wq save and close this split  |  :q! cancel",
		"",
	})
	vim.bo[buf].buftype = "acwrite"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "markdown"
	vim.api.nvim_buf_set_name(buf, string.format("review-comment://%s:%d", path, line))

	vim.cmd("belowright 12split")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	-- startinsert! appends to the current line; land on the blank body line first.
	vim.api.nvim_win_set_cursor(win, { 3, 0 })
	vim.cmd("startinsert")

	vim.api.nvim_buf_create_user_command(buf, "ReviewCommentCancel", function()
		close_comment_window(buf, parent_win, true)
	end, { bang = true })

	vim.api.nvim_buf_set_keymap(buf, "n", "<C-c>", ":ReviewCommentCancel!<CR>", { noremap = true, silent = true })

	-- Only append on write; let :wq close the split (do not bdelete here — that killed diffview).
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			if M.submit_buffer(buf, path, line, source) then
				vim.bo[buf].modified = false
			end
		end,
	})
end

function M.comments_for_buf(bufnr)
	local rel = M.buf_rel_path(bufnr)
	if not rel then
		return {}
	end
	return M.comments_for_path(rel)
end

function M.comments_for_path(rel_path)
	local file = M.review_file()
	if not file or vim.fn.filereadable(file) ~= 1 then
		return {}
	end
	local out = {}
	for line in io.lines(file) do
		if line ~= "" then
			local ok, item = pcall(vim.json.decode, line)
			if ok and item.path == rel_path then
				table.insert(out, item)
			end
		end
	end
	return out
end

function M.load_all_comments()
	local file = M.review_file()
	if not file or vim.fn.filereadable(file) ~= 1 then
		return {}
	end

	local comments_by_path = {}
	for line in io.lines(file) do
		if line ~= "" then
			local ok, item = pcall(vim.json.decode, line)
			if ok and item.path and item.line then
				comments_by_path[item.path] = comments_by_path[item.path] or {}
				table.insert(comments_by_path[item.path], item)
			end
		end
	end
	return comments_by_path
end

function M.decorate_buf(bufnr, comments)
	vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
	if not comments then
		return
	end

	for _, c in ipairs(comments) do
		local lnum = c.line
		if lnum < 1 or lnum > vim.api.nvim_buf_line_count(bufnr) then
			goto continue_comment
		end
		local preview = c.text:gsub("\n", " "):sub(1, 48)
		if #c.text > 48 then
			preview = preview .. "…"
		end
		vim.api.nvim_buf_set_extmark(bufnr, NS, lnum - 1, 0, {
			sign_text = "󰁨",
			sign_hl_group = "LocalReviewSign",
			line_hl_group = "LocalReviewLine",
			virt_text = { { "  " .. preview, "LocalReviewVirt" } },
			virt_text_pos = "eol",
			priority = 120,
		})
		::continue_comment::
	end
end

function M.refresh_signs()
	local comments_by_path = M.load_all_comments()

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if not vim.api.nvim_buf_is_loaded(buf) then
			goto continue_buf
		end
		local rel = M.buf_rel_path(buf)
		if rel and comments_by_path[rel] then
			M.decorate_buf(buf, comments_by_path[rel])
		else
			vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
		end
		::continue_buf::
	end
end

function M.open_review_file()
	local path = M.review_file()
	if not path then
		return
	end
	if vim.fn.filereadable(path) ~= 1 then
		vim.fn.writefile({}, path)
	end
	vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.quickfix()
	local file = M.review_file()
	if not file or vim.fn.filereadable(file) ~= 1 then
		vim.notify("local-review: no comments yet", vim.log.levels.INFO)
		return
	end

	local qf = {}
	for line in io.lines(file) do
		if line ~= "" then
			local ok, item = pcall(vim.json.decode, line)
			if ok then
				local root = git_root() or ""
				table.insert(qf, {
					filename = root .. "/" .. item.path,
					lnum = item.line,
					text = item.text:gsub("\n", " "),
				})
			end
		end
	end

	vim.fn.setqflist(qf, "r")
	vim.cmd("copen")
end

function M.setup()
	vim.api.nvim_set_hl(0, "LocalReviewSign", { link = "TodoSignWARN", default = true })
	vim.api.nvim_set_hl(0, "LocalReviewLine", { bg = "#3b2f14", default = true })
	vim.api.nvim_set_hl(0, "LocalReviewVirt", { fg = "#e0af68", italic = true, default = true })

	vim.api.nvim_create_user_command("ReviewComment", function()
		M.start()
	end, { desc = "Add local review comment at cursor" })

	vim.api.nvim_create_user_command("ReviewComments", function()
		M.quickfix()
	end, { desc = "Open local review comments in quickfix" })

	vim.api.nvim_create_user_command("ReviewFile", function()
		M.open_review_file()
	end, { desc = "Edit .review.local.jsonl" })

	vim.api.nvim_create_user_command("ReviewRefresh", function()
		M.refresh_signs()
	end, { desc = "Refresh local review marks" })

	vim.api.nvim_create_user_command("ReviewExport", function()
		local root = git_root()
		if not root then
			vim.notify("local-review: not inside a git repo", vim.log.levels.ERROR)
			return
		end
		local out = root .. "/.review.local.md"
		local ok = vim.fn.executable("review-comments-export") == 1
		if not ok then
			vim.notify("local-review: review-comments-export not on PATH", vim.log.levels.ERROR)
			return
		end
		local md = vim.fn.systemlist({ "review-comments-export" })
		if vim.v.shell_error ~= 0 then
			vim.notify("local-review: export failed", vim.log.levels.ERROR)
			return
		end
		vim.fn.writefile(md, out)
		vim.notify("local-review: wrote " .. out, vim.log.levels.INFO)
	end, { desc = "Export comments to .review.local.md for agents" })

	vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged", "BufWinEnter" }, {
		callback = function(args)
			local buf = args.buf or vim.api.nvim_get_current_buf()
			vim.schedule(function()
				local rel = M.buf_rel_path(buf)
				if not rel then
					return
				end
				M.decorate_buf(buf, M.load_all_comments()[rel])
			end)
		end,
	})

	vim.keymap.set("n", "gcc", function()
		M.start()
	end, { desc = "Local review comment" })
end

return M
