--- persistent per-picker search history.
--- stores history as a JSON file on disk, keyed by picker namespace.

local M = {}

local MAX_ENTRIES = 50
local HISTORY_PATH = vim.fn.stdpath('data') .. '/nvim-search-history.json'

local history = {}
local loaded = false

local function ensure_loaded()
  if loaded then return end
  loaded = true
  local fd = vim.uv.fs_open(HISTORY_PATH, 'r', 438)
  if not fd then return end
  local stat = vim.uv.fs_fstat(fd)
  if not stat or stat.size == 0 then
    vim.uv.fs_close(fd)
    return
  end
  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  if data then
    local ok, decoded = pcall(vim.fn.json_decode, data)
    if ok and type(decoded) == 'table' then
      history = decoded
    end
  end
end

local function save()
  local encoded = vim.fn.json_encode(history)
  local fd = vim.uv.fs_open(HISTORY_PATH, 'w', 438)
  if not fd then return end
  vim.uv.fs_write(fd, encoded)
  vim.uv.fs_close(fd)
end

function M.add(namespace, query)
  if not query or query == '' then return end
  ensure_loaded()
  local list = history[namespace] or {}
  for i = #list, 1, -1 do
    if list[i] == query then
      table.remove(list, i)
    end
  end
  table.insert(list, 1, query)
  while #list > MAX_ENTRIES do
    table.remove(list)
  end
  history[namespace] = list
  vim.schedule(save)
end

function M.get(namespace)
  ensure_loaded()
  return history[namespace] or {}
end

function M.search(namespace, pattern)
  ensure_loaded()
  local list = history[namespace] or {}
  if not pattern or pattern == '' then return list end
  local pat = pattern:lower()
  local results = {}
  for _, q in ipairs(list) do
    if q:lower():find(pat, 1, true) then
      results[#results + 1] = q
    end
  end
  return results
end

function M.show_history_completions(namespace, prompt_bufnr, force)
  ensure_loaded()
  local list = history[namespace] or {}
  if #list == 0 then return end

  local action_state = require 'telescope.actions.state'
  local picker = action_state.get_current_picker(prompt_bufnr)
  local prompt = picker:_get_prompt()

  local matches
  if force or prompt == '' then
    matches = list
  else
    matches = M.search(namespace, prompt)
  end

  if #matches == 0 then return end

  if #matches == 1 and matches[1] == prompt then return end

  local line = vim.api.nvim_get_current_line()
  local start_col = #line - #prompt + 1

  vim.o.completeopt = 'menuone,noinsert,noselect'

  vim.fn.complete(start_col, matches)
end

function M.attach_history_mappings(namespace, prompt_bufnr, map)
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local hist_index = 0
  local hist_list = M.get(namespace)

  map('i', '<Down>', function()
    if vim.fn.pumvisible() == 1 then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Down>', true, false, true), 'n', false)
      return
    end
    local picker = action_state.get_current_picker(prompt_bufnr)
    local prompt = picker:_get_prompt()
    if prompt ~= '' and hist_index == 0 then
      actions.move_selection_next(prompt_bufnr)
      return
    end
    hist_list = M.get(namespace)
    if #hist_list == 0 then
      actions.move_selection_next(prompt_bufnr)
      return
    end
    hist_index = hist_index + 1
    if hist_index > #hist_list then hist_index = 1 end
    picker:set_prompt(hist_list[hist_index])
  end)

  map('i', '<Up>', function()
    if vim.fn.pumvisible() == 1 then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Up>', true, false, true), 'n', false)
      return
    end
    if hist_index == 0 then
      actions.move_selection_previous(prompt_bufnr)
      return
    end
    hist_list = M.get(namespace)
    if #hist_list == 0 then
      actions.move_selection_previous(prompt_bufnr)
      return
    end
    hist_index = hist_index - 1
    if hist_index < 1 then hist_index = #hist_list end
    local picker = action_state.get_current_picker(prompt_bufnr)
    picker:set_prompt(hist_list[hist_index])
  end)

  map('i', '<C-r>', function()
    M.show_history_completions(namespace, prompt_bufnr, true)
  end)

  local suggest_suppressed = false
  vim.api.nvim_create_autocmd('TextChangedI', {
    buffer = prompt_bufnr,
    callback = function()
      if hist_index > 0 then
        local picker = action_state.get_current_picker(prompt_bufnr)
        local current = picker:_get_prompt()
        if hist_list[hist_index] ~= current then
          hist_index = 0
        end
      end

      if suggest_suppressed then
        suggest_suppressed = false
        return
      end

      local picker = action_state.get_current_picker(prompt_bufnr)
      local prompt = picker:_get_prompt()
      if #prompt >= 1 then
        M.show_history_completions(namespace, prompt_bufnr, false)
      end
    end,
  })

  vim.api.nvim_create_autocmd('CompleteDone', {
    buffer = prompt_bufnr,
    callback = function()
      suggest_suppressed = true
    end,
  })
end

function M.wrap_builtin(namespace, builtin_fn)
  return function(opts)
    opts = opts or {}
    local original_attach = opts.attach_mappings

    opts.attach_mappings = function(prompt_bufnr, map)
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      M.attach_history_mappings(namespace, prompt_bufnr, map)

      map('i', '<CR>', function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        M.add(namespace, picker:_get_prompt())
        actions.select_default(prompt_bufnr)
      end)
      map('n', '<CR>', function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        M.add(namespace, picker:_get_prompt())
        actions.select_default(prompt_bufnr)
      end)

      if original_attach then
        return original_attach(prompt_bufnr, map)
      end
      return true
    end

    builtin_fn(opts)
  end
end

return M
