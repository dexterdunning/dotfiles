local M = {}

local MODE_UNSTAGED = "unstaged"
local MODE_WIP = "wip"
local MODE_BRANCH = "branch"

local current_mode = nil

local function ensure_diffview()
	vim.cmd("silent! packadd diffview.nvim")
	if vim.fn.exists("*plug#load") == 1 then
		pcall(vim.fn["plug#load"], "diffview.nvim")
	end
	require("diffview-config")
end

local function diffview_open()
	local ok, lib = pcall(require, "diffview.lib")
	return ok and lib.get_current_view() ~= nil
end

local function git_ok(cmd)
	local out = vim.fn.systemlist(cmd)
	return vim.v.shell_error == 0, out
end

---PR base branch when on a PR, else upstream, else origin/HEAD, else origin/master.
function M.resolve_base_remote()
	local ok, out = git_ok({ "gh", "pr", "view", "--json", "baseRefName", "-q", ".baseRefName" })
	if ok and out[1] and out[1] ~= "" then
		return "origin/" .. out[1], "pr:" .. out[1]
	end

	ok, out = git_ok({ "git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}" })
	if ok and out[1] and out[1] ~= "" then
		return out[1], "upstream:" .. out[1]
	end

	ok, out = git_ok({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })
	if ok and out[1] and out[1] ~= "" then
		return out[1], out[1]
	end

	return "origin/master", "origin/master"
end

function M.branch_rev_arg()
	local base = M.resolve_base_remote()
	return base .. "...HEAD"
end

local function notify(msg)
	vim.notify(msg, vim.log.levels.INFO, { title = "diffview" })
end

---@param rev_arg string|nil nil = index vs working tree (unstaged + untracked)
---@param opts table|nil
---@param label string
local function open_or_set_revs(rev_arg, opts, label)
	ensure_diffview()
	opts = opts or {}

	if diffview_open() then
		require("diffview.api").set_revs(rev_arg, opts)
	else
		local cmd = "DiffviewOpen"
		if rev_arg and rev_arg ~= "" then
			cmd = cmd .. " " .. rev_arg
		end
		if opts.imply_local then
			cmd = cmd .. " --imply-local"
		end
		vim.cmd(cmd)
	end

	notify(label)
	vim.schedule(function()
		pcall(require("local-review").refresh_signs)
	end)
end

---Unstaged changes (and untracked files): index vs working tree. Same as `git diff`.
function M.open_unstaged()
	current_mode = MODE_UNSTAGED
	open_or_set_revs(nil, {}, "unstaged: index → working tree")
end

---All uncommitted changes on tracked files: HEAD vs working tree. Same as `git diff HEAD`.
function M.open_wip()
	current_mode = MODE_WIP
	open_or_set_revs("HEAD", {}, "wip: HEAD → working tree (staged + unstaged)")
end

---All branch commits vs merge-base, plus working-tree edits on the right.
function M.open_branch()
	current_mode = MODE_BRANCH
	local _, label = M.resolve_base_remote()
	open_or_set_revs(M.branch_rev_arg(), { imply_local = true }, "branch: " .. label .. "...HEAD")
end

-- Back-compat alias used by earlier keymaps/docs.
M.open_local = M.open_unstaged

function M.toggle()
	if current_mode == MODE_BRANCH then
		M.open_unstaged()
	else
		M.open_branch()
	end
end

function M.close()
	if diffview_open() then
		vim.cmd("DiffviewClose")
	end
	current_mode = nil
end

return M
