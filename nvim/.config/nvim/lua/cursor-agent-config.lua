-- cursor-agent configuration with custom split window instead of floating
local cursor_agent = require('cursor-agent')
local config = require('cursor-agent.config')
local context = require('cursor-agent.context')
local util = require('cursor-agent.util')

-- Basic configuration for cursor-agent
cursor_agent.setup({
    -- Command to run cursor-agent CLI
    cmd = 'cursor-agent', -- Make sure cursor-agent CLI is installed
    args = {}, -- Additional arguments to pass to cursor-agent
    
    -- You can also configure the cursor-agent CLI via environment variables
    -- CURSOR_API_KEY, CURSOR_MODEL, etc.
})

-- State for a single persistent terminal in a split
local _split_term_state = {
  win = nil,
  bufnr = nil,
  job_id = nil,
}

-- Custom function to open terminal in a right split instead of floating
local function open_split_term(opts)
  opts = opts or {}
  
  -- Create a vertical split to the right
  vim.cmd('rightbelow vertical split')
  local win = vim.api.nvim_get_current_win()
  
  -- Set window width (adjust as needed)
  vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * 0.4))
  
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, bufnr)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
  
  -- Window options
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  
  local argv = opts.argv
  
  -- Validate cwd
  local function resolve_cwd(cwd)
    if type(cwd) ~= 'string' or cwd == '' then return vim.fn.getcwd() end
    local uv = vim.uv or vim.loop
    local stat = uv.fs_stat(cwd)
    if stat and stat.type == 'directory' then return cwd end
    return vim.fn.getcwd()
  end
  
  local job_id = vim.fn.termopen(argv, {
    cwd = resolve_cwd(opts.cwd),
    on_exit = function(_, code)
      if type(opts.on_exit) == "function" then
        pcall(opts.on_exit, code)
      end
    end,
  })
  
  -- Add keymap to close with 'q'
  pcall(vim.keymap.set, 'n', 'q', function()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = bufnr, nowait = true, silent = true })
  
  -- Jump to bottom and enter terminal-mode
  local ok_lines, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
  if ok_lines then pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 }) end
  vim.schedule(function()
    pcall(vim.cmd, 'startinsert')
  end)
  
  return bufnr, win, job_id
end

-- Override the toggle_terminal function to use our split instead
function cursor_agent.toggle_split_terminal()
  local st = _split_term_state
  
  -- If window is open, close it (toggle off)
  if st.win and vim.api.nvim_win_is_valid(st.win) then
    vim.api.nvim_win_close(st.win, true)
    st.win = nil
    return
  end
  
  -- Helper: check if the terminal job is still alive
  local function job_is_alive(job_id)
    if not job_id or job_id == 0 then return false end
    local ok, res = pcall(vim.fn.jobwait, { job_id }, 0)
    if not ok or type(res) ~= 'table' then return false end
    return res[1] == -1
  end
  
  -- If we have a valid buffer with a live job, reopen it in a split
  if st.bufnr and vim.api.nvim_buf_is_valid(st.bufnr) and job_is_alive(st.job_id) then
    vim.cmd('rightbelow vertical split')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * 0.4))
    vim.api.nvim_win_set_buf(win, st.bufnr)
    st.win = win
    
    -- Jump to bottom and enter terminal-mode
    local ok_lines, line_count = pcall(vim.api.nvim_buf_line_count, st.bufnr)
    if ok_lines then pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 }) end
    vim.schedule(function()
      pcall(vim.cmd, 'startinsert')
    end)
    return st.bufnr, st.win
  end
  
  -- Otherwise spawn a fresh terminal in a split
  local cfg = config.get()
  local argv = util.concat_argv(util.to_argv(cfg.cmd), cfg.args)
  local root = util.get_project_root()
  local bufnr, win, job_id = open_split_term({
    argv = argv,
    cwd = root,
    on_exit = function(code)
      if _split_term_state then _split_term_state.job_id = nil end
      if code ~= 0 then
        util.notify(('cursor-agent exited with code %d'):format(code), vim.log.levels.WARN)
      end
    end,
  })
  st.bufnr, st.win, st.job_id = bufnr, win, job_id
  return bufnr, win
end

-- Key mappings for cursor-agent functionality
-- Updated to use our custom split terminal instead of floating

-- Toggle cursor-agent terminal in a right split (main function)
vim.keymap.set('n', '<leader>cq', function()
    cursor_agent.toggle_split_terminal()
end, { desc = 'Toggle Cursor Agent Split Terminal' })

-- Send current visual selection to cursor-agent
vim.keymap.set('v', '<leader>ce', function()
    vim.cmd('CursorAgentSelection')
end, { desc = 'Send Selection to Cursor Agent' })

-- Send current buffer to cursor-agent
vim.keymap.set('n', '<leader>cr', function()
    vim.cmd('CursorAgentBuffer')
end, { desc = 'Send Buffer to Cursor Agent' })

-- Ask cursor-agent a question (still uses the original floating window for one-off questions)
vim.keymap.set('n', '<leader>cg', function()
    cursor_agent.ask({ prompt = '' }) -- Empty prompt will let you type in terminal
end, { desc = 'Ask Cursor Agent Question' })

-- Alternative mapping for the original floating terminal if you want both options
vim.keymap.set('n', '<leader>cf', function()
    cursor_agent.toggle_terminal()
end, { desc = 'Toggle Cursor Agent Floating Terminal' })
