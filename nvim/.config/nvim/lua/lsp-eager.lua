--- Eagerly start LSPs on VimEnter for known project types.
---
--- For TypeScript monorepos, pre-warms multiple subprojects (each tsconfig.json
--- = its own tsserver instance). Three sources, in priority order:
---   1. Pinned paths (from vim.g.nvim_lsp_warmup_pinned_paths) — always warmed
---   2. Recently-used cache — warmed by recency, persisted across sessions
---   3. Ripgrep fill — first-found tsconfigs to hit the cap
---
--- Cache file: stdpath('data') .. '/nvim-lsp-eager-cache.json'
---
--- Configurables (set in init.vim before this file's setup runs):
---   vim.g.nvim_lsp_warmup_max_ts_projects = 5     -- total cap (default 5; 0 disables subproject warming)
---   vim.g.nvim_lsp_warmup_pinned_paths = { 'timeTracking' }
---     -- list of substrings; any tsconfig.json whose path contains one
---     -- of these strings is always warmed (counts toward the cap).
---
--- Commands:
---   :LspEagerCacheShow   — list cached recent projects for current cwd
---   :LspEagerCacheClear  — clear cache for current cwd

local M = {}

local DEFAULT_MAX_TS_PROJECTS = 5
local CACHE_PATH = vim.fn.stdpath('data') .. '/nvim-lsp-eager-cache.json'

-- ============================================================================
-- Cache layer
-- ============================================================================

local cache = nil

local function cache_load()
	if cache then return cache end
	cache = {}
	local fd = vim.uv.fs_open(CACHE_PATH, 'r', 438)
	if not fd then return cache end
	local stat = vim.uv.fs_fstat(fd)
	if stat and stat.size > 0 then
		local data = vim.uv.fs_read(fd, stat.size, 0)
		if data then
			local ok, decoded = pcall(vim.fn.json_decode, data)
			if ok and type(decoded) == 'table' then cache = decoded end
		end
	end
	vim.uv.fs_close(fd)
	return cache
end

local save_scheduled = false
local function cache_save_debounced()
	if save_scheduled then return end
	save_scheduled = true
	vim.defer_fn(function()
		save_scheduled = false
		local encoded = vim.fn.json_encode(cache or {})
		local fd = vim.uv.fs_open(CACHE_PATH, 'w', 438)
		if not fd then return end
		vim.uv.fs_write(fd, encoded)
		vim.uv.fs_close(fd)
	end, 1000)
end

local function cache_record(cwd, project_dir)
	cache_load()
	cache[cwd] = cache[cwd] or {}
	cache[cwd][project_dir] = os.time()
	cache_save_debounced()
end

--- Return cached project dirs under cwd, sorted by recency (most recent first).
local function cache_recent_sorted(cwd)
	cache_load()
	local entries = cache[cwd] or {}
	local list = {}
	for dir, ts in pairs(entries) do
		if vim.fn.isdirectory(dir) == 1 then
			list[#list + 1] = { dir = dir, ts = ts }
		end
	end
	table.sort(list, function(a, b) return a.ts > b.ts end)
	local out = {}
	for _, e in ipairs(list) do out[#out + 1] = e.dir end
	return out
end

-- ============================================================================
-- Project detection
-- ============================================================================

local function project_has(file)
	local cwd = vim.fn.getcwd()
	return vim.fn.filereadable(cwd .. '/' .. file) == 1
		or vim.fn.isdirectory(cwd .. '/' .. file) == 1
end

local function eager_attach_at(dir, ft, ext)
	local fake = dir .. '/.nvim-lsp-warmup' .. ext
	local buf = vim.fn.bufadd(fake)
	vim.bo[buf].buflisted = false
	vim.bo[buf].bufhidden = 'hide'
	vim.bo[buf].filetype = ft
end

local function detect_primary_lang()
	if project_has('tsconfig.json') or project_has('jsconfig.json') then
		return 'ts'
	end
	if project_has('pyproject.toml') or project_has('setup.py') then
		return 'python'
	end
	return nil
end

local function find_enclosing_tsconfig(path, cwd)
	local found = vim.fs.find('tsconfig.json', {
		upward = true,
		path = path,
		stop = vim.fn.fnamemodify(cwd, ':h'),
		limit = 1,
	})
	if #found == 0 then return nil end
	return vim.fn.fnamemodify(found[1], ':h')
end

--- Async ripgrep for tsconfig.json files in cwd subtree.
--- Returns a list of directories (deduped, no order guarantee beyond rg's).
local function find_all_ts_subprojects_async(cwd, callback)
	if vim.fn.executable('rg') ~= 1 then
		callback({})
		return
	end
	local cmd = {
		'rg', '--files', '--hidden',
		'--glob', 'tsconfig.json',
		'--glob', '!node_modules/**',
		'--glob', '!.git/**',
		'--glob', '!dist/**',
		'--glob', '!build/**',
		'--glob', '!.next/**',
		'--glob', '!coverage/**',
		'--max-depth', '5',
		cwd,
	}
	vim.system(cmd, { text = true }, vim.schedule_wrap(function(out)
		if out.code ~= 0 or not out.stdout then
			callback({})
			return
		end
		local dirs = {}
		local seen = {}
		for line in out.stdout:gmatch('[^\n]+') do
			local dir = vim.fn.fnamemodify(line, ':h')
			if dir ~= cwd and not seen[dir] then
				seen[dir] = true
				dirs[#dirs + 1] = dir
			end
		end
		callback(dirs)
	end))
end

local function path_matches_any(path, patterns)
	for _, pat in ipairs(patterns) do
		if path:find(pat, 1, true) then return true end
	end
	return false
end

-- ============================================================================
-- Public setup
-- ============================================================================

function M.setup()
	local group = vim.api.nvim_create_augroup('lsp-eager', { clear = true })

	vim.api.nvim_create_autocmd('VimEnter', {
		group = group,
		callback = function()
			vim.defer_fn(function()
				local lang = detect_primary_lang()
				local cwd = vim.fn.getcwd()

				if lang == 'ts' then
					eager_attach_at(cwd, 'typescriptreact', '.tsx')

					local max = vim.g.nvim_lsp_warmup_max_ts_projects or DEFAULT_MAX_TS_PROJECTS
					if max <= 0 then return end

					local pinned = vim.g.nvim_lsp_warmup_pinned_paths or {}
					-- Allow vim.g passing as comma-string for shell-friendliness.
					if type(pinned) == 'string' then
						local parts = {}
						for p in pinned:gmatch('[^,]+') do parts[#parts + 1] = p end
						pinned = parts
					end

					-- Find all subprojects up front (single rg call).
					find_all_ts_subprojects_async(cwd, function(all_dirs)
						local warmed = {}
						local pinned_dirs = {}
						local cached_dirs = {}
						local fill_dirs = {}

						-- Bucket 1: pinned matches (subset of all_dirs)
						if #pinned > 0 then
							for _, dir in ipairs(all_dirs) do
								if path_matches_any(dir, pinned) then
									pinned_dirs[#pinned_dirs + 1] = dir
								end
							end
						end

						-- Bucket 2: cached recent (intersected with all_dirs to filter stale)
						local all_dirs_set = {}
						for _, dir in ipairs(all_dirs) do all_dirs_set[dir] = true end
						for _, dir in ipairs(cache_recent_sorted(cwd)) do
							if all_dirs_set[dir] then
								cached_dirs[#cached_dirs + 1] = dir
							end
						end

						-- Bucket 3: everything else from rg, in rg order
						for _, dir in ipairs(all_dirs) do
							fill_dirs[#fill_dirs + 1] = dir
						end

						-- Warm in priority order: pinned → cached → fill, up to cap.
						local function try_warm(dir)
							if warmed[dir] then return false end
							if #vim.tbl_keys(warmed) >= max then return false end
							eager_attach_at(dir, 'typescriptreact', '.tsx')
							warmed[dir] = true
							return true
						end

						local n_pinned, n_cached, n_fill = 0, 0, 0
						for _, dir in ipairs(pinned_dirs) do
							if try_warm(dir) then n_pinned = n_pinned + 1 end
						end
						for _, dir in ipairs(cached_dirs) do
							if try_warm(dir) then n_cached = n_cached + 1 end
						end
						for _, dir in ipairs(fill_dirs) do
							if try_warm(dir) then n_fill = n_fill + 1 end
						end

						local total = n_pinned + n_cached + n_fill
						if total > 0 then
							vim.notify(
								string.format(
									'lsp-eager: warmed %d TS subproject(s) (%d pinned, %d cached, %d new)',
									total, n_pinned, n_cached, n_fill
								),
								vim.log.levels.INFO
							)
						end
					end)
				elseif lang == 'python' then
					eager_attach_at(cwd, 'python', '.py')
				end
			end, 100)
		end,
	})

	-- Track real file opens so the cache reflects what the user actually uses.
	vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
		group = group,
		pattern = { '*.ts', '*.tsx', '*.js', '*.jsx' },
		callback = function(args)
			local path = vim.api.nvim_buf_get_name(args.buf)
			if path == '' then return end
			if path:match('%.nvim%-lsp%-warmup') then return end
			local cwd = vim.fn.getcwd()
			if not path:find(cwd, 1, true) then return end
			local project_dir = find_enclosing_tsconfig(path, cwd)
			if project_dir and project_dir ~= cwd then
				cache_record(cwd, project_dir)
			end
		end,
	})

	vim.api.nvim_create_user_command('LspEagerCacheShow', function() M.show_cache() end, {})
	vim.api.nvim_create_user_command('LspEagerCacheClear', function() M.clear_cache() end, {})
end

function M.show_cache()
	cache_load()
	local cwd = vim.fn.getcwd()
	local entries = cache[cwd] or {}
	local lines = { 'lsp-eager cache for ' .. cwd .. ':' }
	local list = {}
	for dir, ts in pairs(entries) do
		list[#list + 1] = { dir = dir, ts = ts }
	end
	table.sort(list, function(a, b) return a.ts > b.ts end)
	for _, e in ipairs(list) do
		lines[#lines + 1] = string.format('  %s  (%s)', e.dir, os.date('%Y-%m-%d %H:%M', e.ts))
	end
	if #list == 0 then lines[#lines + 1] = '  (empty)' end
	vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
end

function M.clear_cache()
	cache_load()
	cache[vim.fn.getcwd()] = nil
	cache_save_debounced()
	vim.notify('lsp-eager: cache cleared for ' .. vim.fn.getcwd(), vim.log.levels.INFO)
end

return M
