--- custom workspace symbol picker using telescope + custom ranking algorithm.
--- replaces fzf-lua lsp_live_workspace_symbols whose ranking was unreliable.
---
--- keymaps (registered via setup_keymaps, called from telescope-config):
---   <leader>sc  — search classes (Class, Enum, Interface, Struct)
---   <leader>sm  — search methods/functions (Function, Method, Constructor)
---   <leader>sv  — search variables (Variable, Field, Property, Constant)
---   <leader>sS  — search all symbols
---   <leader><leader> — search all symbols (quick access)
---   gW          — search all symbols (buffer-local, set on LspAttach)
---   :TyKill     — kill ty LSP

local ranking = require 'symbol-ranking'
local search_history = require 'search-history'

local M = {}

local pending_display = {}

local function history_namespace(title)
  return 'ws_' .. (title or 'symbols'):lower():gsub('[^%w]+', '_')
end

local function snake_to_camel(s)
  return (s:gsub('_(%a)', function(c) return c:upper() end))
end

local function camel_to_snake(s)
  local result = s:gsub('%l(%u)', function(pair)
    return pair:sub(1, 1) .. '_' .. pair:sub(2, 2):lower()
  end)
  return result:lower()
end

local function alternate_query(query)
  local has_underscore = query:find('_') ~= nil
  local has_upper_after_lower = query:find('%l%u') ~= nil

  if has_underscore then
    local alt = snake_to_camel(query)
    if alt ~= query then return alt end
  elseif has_upper_after_lower then
    local alt = camel_to_snake(query)
    if alt ~= query then return alt end
  end
  return nil
end

local function make_top_previewer(opts)
  opts = opts or {}
  local previewers = require 'telescope.previewers'
  local conf = require('telescope.config').values
  local api = vim.api
  local ns = api.nvim_create_namespace 'workspace_sym_preview'

  return previewers.new_buffer_previewer {
    title = 'Symbol Preview',

    dyn_title = function(_, entry)
      return vim.fn.fnamemodify(entry.filename or '', ':~:.')
    end,

    get_buffer_by_name = function(_, entry)
      return entry.filename or ''
    end,

    define_preview = function(self, entry)
      local p = entry.filename
      if not p or p == '' then return end

      conf.buffer_previewer_maker(p, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        preview = opts.preview,
        callback = function(bufnr)
          pcall(api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
          if entry.lnum and entry.lnum > 0 then
            pcall(
              api.nvim_buf_add_highlight,
              bufnr, ns, 'TelescopePreviewLine',
              entry.lnum - 1, 0, -1
            )
            pcall(api.nvim_win_set_cursor, self.state.winid, { entry.lnum, 0 })
            api.nvim_win_call(self.state.winid, function() vim.cmd 'norm! zt' end)
          end

          for rid, _ in pairs(pending_display) do
            vim.cmd('redraw')
            pending_display[rid] = nil
          end
        end,
      })
    end,
  }
end

local function kind_label(kind_num) return ranking.KIND_NAMES[kind_num] or 'symbol' end

local function make_kind_filter(kind_set)
  if not kind_set then
    return function(_) return true end
  end
  return function(sym) return kind_set[sym.kind] == true end
end

local function normalise_sym(sym)
  local uri = sym.location and sym.location.uri or ''
  local path = vim.uri_to_fname(uri)
  local range = sym.location and sym.location.range or {}
  local lnum = range.start and (range.start.line + 1) or 1
  local col = range.start and (range.start.character + 1) or 1
  return {
    name = sym.name or '',
    kind = sym.kind or 0,
    filename = path,
    lnum = lnum,
    col = col,
  }
end

local function make_sym_entry(sym)
  local kind = kind_label(sym.kind)
  local relpath = vim.fn.fnamemodify(sym.filename, ':~:.'):gsub('^app/', '')
  local display = string.format('%-40s %-12s %s:%d', sym.name, kind, relpath, sym.lnum)
  return {
    value = sym,
    ordinal = sym.name .. ' ' .. kind .. ' ' .. relpath,
    display = display,
    filename = sym.filename,
    lnum = sym.lnum,
    col = sym.col,
  }
end

local function make_sym_requester(bufnr, kind_set)
  local channel = require('plenary.async.control').channel
  local filter = make_kind_filter(kind_set)

  local state = {
    cancel = function() end,
    debounce_timer = nil,
    progress_handle = nil,
  }

  local req_id = 0

  local function cleanup()
    state.cancel()
    state.cancel = function() end
    if state.debounce_timer then
      state.debounce_timer:stop()
      state.debounce_timer:close()
      state.debounce_timer = nil
    end
    if state.progress_handle then
      state.progress_handle:finish()
      state.progress_handle = nil
    end
  end

  local function requester(prompt)
    req_id = req_id + 1
    local rid = req_id

    if not prompt or prompt == '' then return {} end

    if #prompt < 3 then return {} end

    state.cancel()

    if state.debounce_timer then
      state.debounce_timer:stop()
      if not state.debounce_timer:is_closing() then
        state.debounce_timer:close()
      end
      state.debounce_timer = nil
    end
    local dtx, drx = channel.oneshot()
    local timer = vim.uv.new_timer()
    state.debounce_timer = timer
    timer:start(ranking.DEBOUNCE_MS, 0, vim.schedule_wrap(function()
      if not timer:is_closing() then
        timer:close()
      end
      if state.debounce_timer == timer then
        state.debounce_timer = nil
      end
      dtx()
    end))
    drx()

    -- read the actual current prompt; if user kept typing, abandon this request
    local ptx, prx = channel.oneshot()
    vim.schedule(function()
      local action_state_ok, action_state = pcall(require, 'telescope.actions.state')
      if action_state_ok then
        local picker = action_state.get_current_picker(vim.api.nvim_get_current_buf())
        if picker then
          local current = picker:_get_prompt()
          ptx(current)
          return
        end
      end
      ptx(prompt)
    end)
    local current_prompt = prx()

    if current_prompt ~= prompt then return {} end

    vim.schedule(function()
      local ok, progress = pcall(require, 'fidget.progress')
      if ok then
        -- Show the actual client name(s) being queried, not a hardcoded label.
        local clients = vim.lsp.get_clients({ bufnr = bufnr, method = 'workspace/symbol' })
        local names = {}
        for _, c in ipairs(clients) do names[#names + 1] = c.name end
        local label = #names > 0 and table.concat(names, '+') or 'lsp'
        state.progress_handle = progress.handle.create {
          title = 'Workspace Symbols',
          message = 'searching...',
          lsp_client = { name = label },
        }
      end
    end)

    -- build list of queries: original + alternate case form (if any)
    local queries = { prompt }
    local alt = alternate_query(prompt)
    if alt then queries[#queries + 1] = alt end

    -- fire all queries in parallel
    local all_responses = {}
    local cancels = {}
    local channels = {}
    for _, q in ipairs(queries) do
      local tx, rx = channel.oneshot()
      channels[#channels + 1] = rx
      cancels[#cancels + 1] = vim.lsp.buf_request_all(bufnr, 'workspace/symbol', { query = q }, tx)
    end
    state.cancel = function()
      for _, c in ipairs(cancels) do c() end
    end
    for _, rx in ipairs(channels) do
      local resp = rx()
      for _, r in pairs(resp) do
        all_responses[#all_responses + 1] = r
      end
    end

    vim.schedule(function()
      if state.progress_handle then
        state.progress_handle:finish()
        state.progress_handle = nil
      end
    end)

    -- dedupe by (name, uri, lnum)
    local raw = {}
    local seen = {}
    for _, resp in ipairs(all_responses) do
      if resp.result then
        for _, sym in ipairs(resp.result) do
          if filter(sym) then
            local uri = sym.location and sym.location.uri or ''
            local lnum = sym.location and sym.location.range and sym.location.range.start and sym.location.range.start.line or 0
            local dedup_key = sym.name .. '\0' .. uri .. '\0' .. tostring(lnum)
            if not seen[dedup_key] then
              seen[dedup_key] = true
              raw[#raw + 1] = sym
            end
          end
        end
      end
    end

    local ranked = ranking.rank_and_limit(raw, prompt)

    local entries = {}
    for _, sym in ipairs(ranked) do
      entries[#entries + 1] = make_sym_entry(normalise_sym(sym))
    end

    pending_display[rid] = true

    return entries
  end

  return requester, cleanup
end

--- Find a buffer that has at least one client supporting workspace/symbol.
--- Falls back to current buffer. This makes the picker work even when launched
--- from [No Name] / a non-LSP buffer (e.g. fresh nvim with no file opened),
--- as long as some buffer in the session has an attached LSP client —
--- typically the hidden warm-up buffer created by lsp-eager.
local function find_lsp_buf()
  local current = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = current, method = 'workspace/symbol' }) > 0 then
    return current
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      if #vim.lsp.get_clients({ bufnr = buf, method = 'workspace/symbol' }) > 0 then
        return buf
      end
    end
  end
  return current
end

function M.workspace_symbols(opts)
  opts = opts or {}

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local sorters = require 'telescope.sorters'
  local actions = require 'telescope.actions'
  local astate = require 'telescope.actions.state'

  local bufnr = find_lsp_buf()
  local kind_set = opts.kind_set
  local title = opts.title or 'Workspace Symbols'

  local requester, cleanup = make_sym_requester(bufnr, kind_set)

  pickers
    .new(opts, {
      prompt_title = title,
      sorting_strategy = 'ascending',
      layout_config = { prompt_position = 'top' },

      finder = (function()
        local f = finders.new_dynamic {
          fn = requester,
          entry_maker = function(entry) return entry end,
        }
        f.close = cleanup
        return f
      end)(),

      sorter = sorters.highlighter_only(opts),

      previewer = not opts.no_preview and make_top_previewer(opts) or false,

      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          search_history.add(history_namespace(title), astate.get_current_picker(prompt_bufnr):_get_prompt())
          local selection = astate.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection then return end
          local sym = selection.value
          if sym and sym.filename then
            vim.cmd('edit ' .. vim.fn.fnameescape(sym.filename))
            vim.api.nvim_win_set_cursor(0, { sym.lnum, (sym.col or 1) - 1 })
            vim.cmd 'normal! zt3k'
            vim.api.nvim_win_set_cursor(0, { sym.lnum, (sym.col or 1) - 1 })
          end
        end)

        -- <c-space> / n-mode `/`: switch to fuzzy-over-results mode
        map('i', '<c-space>', actions.to_fuzzy_refine)
        map('n', '/', actions.to_fuzzy_refine)

        search_history.attach_history_mappings(history_namespace(title), prompt_bufnr, map)

        return true
      end,
    })
    :find()
end

function M.setup_keymaps()
  local SK = ranking.KIND_SETS

  vim.api.nvim_create_user_command('TyKill', function()
    local clients = vim.lsp.get_clients({ name = 'ty' })
    if #clients == 0 then
      vim.notify('ty: no active clients', vim.log.levels.WARN)
      return
    end
    vim.lsp.stop_client(clients)
    vim.notify('ty killed (' .. #clients .. ' client(s))', vim.log.levels.INFO)
  end, { desc = 'Restart ty LSP (kill stuck processes)' })

  vim.keymap.set('n', '<leader>sc', function()
    M.workspace_symbols { title = 'Workspace Classes', kind_set = SK.class }
  end, { desc = '[S]earch workspace [C]lasses' })

  vim.keymap.set('n', '<leader>sm', function()
    M.workspace_symbols { title = 'Workspace Methods/Functions', kind_set = SK.func }
  end, { desc = '[S]earch workspace [M]ethods' })

  vim.keymap.set('n', '<leader>sv', function()
    M.workspace_symbols { title = 'Workspace Variables', kind_set = SK.variable }
  end, { desc = '[S]earch workspace [V]ariables' })

  vim.keymap.set('n', '<leader>sS', function()
    M.workspace_symbols { title = 'Workspace Symbols' }
  end, { desc = '[S]earch workspace [S]ymbols' })

  vim.keymap.set('n', '<leader><leader>', function()
    M.workspace_symbols { title = 'Workspace Symbols' }
  end, { desc = 'Workspace Symbols' })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('custom-sym-lsp-attach', { clear = true }),
    callback = function(event)
      vim.keymap.set('n', 'gW', function() M.workspace_symbols { title = 'Workspace Symbols' } end, {
        buffer = event.buf,
        desc = 'Open Workspace Symbols',
      })
    end,
  })
end

return M
