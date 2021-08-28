local vim = vim
local gl = require('galaxyline')
local utils = require('utils')

local gls = gl.section
gl.short_line_list = { 'defx', 'packager', 'vista' }

-- Colors
local colors = {
  bg = '#282a36',
  fg = '#f8f8f2',
  section_bg = '#38393f',
  yellow = '#f1fa8c',
  cyan = '#8be9fd',
  green = '#50fa7b',
  orange = '#ffb86c',
  magenta = '#ff79c6',
  blue = '#8be9fd',
  red = '#ff5555'
}

-- Local helper functions
local buffer_not_empty = function()
  return not utils.is_buffer_empty()
end

local in_git_repo = function ()
  local vcs = require('galaxyline.provider_vcs')
  local branch_name = vcs.get_git_branch()

  return branch_name ~= nil
end

local checkwidth = function()
  return utils.has_width_gt(40) and in_git_repo()
end

local mode_color = function()
  local mode_colors = {
    n = colors.cyan,
    i = colors.green,
    c = colors.orange,
    V = colors.magenta,
    [''] = colors.magenta,
    v = colors.magenta,
    R = colors.red,
  }

  local color = mode_colors[vim.fn.mode()]

  if color == nil then
    color = colors.red
  end

  return color
end

-- Left side
gls.left[1] = {
  FirstElement = {
    provider = function() return '▋' end,
    highlight = { colors.cyan, colors.section_bg }
  },
}
gls.left[2] = {
  ViMode = {
    provider = function()
      local alias = {
        n = 'NORMAL',
        i = 'INSERT',
        c = 'COMMAND',
        V = 'VISUAL',
        [''] = 'VISUAL',
        v = 'VISUAL',
        R = 'REPLACE',
      }
      vim.api.nvim_command('hi GalaxyViMode guifg='..mode_color())
      local alias_mode = alias[vim.fn.mode()]
      if alias_mode == nil then
        alias_mode = vim.fn.mode()
      end
      return alias_mode..' '
    end,
    highlight = { colors.bg, colors.bg },
    separator = "  ",
    separator_highlight = {colors.bg, colors.section_bg},
  },
}
gls.left[3] ={
  FileIcon = {
    provider = 'FileIcon',
    condition = buffer_not_empty,
    highlight = { require('galaxyline.provider_fileinfo').get_file_icon_color, colors.section_bg },
  },
}
gls.left[4] = {
  FileName = {
    provider = 'FileName',
    condition = buffer_not_empty,
    highlight = { colors.fg, colors.section_bg },
    separator = " ",
    separator_highlight = {colors.section_bg, colors.bg},
  }
}
gls.left[5] = {
  GitIcon = {
    provider = function() return '  ' end,
    condition = in_git_repo,
    highlight = {colors.red,colors.bg},
  }
}
gls.left[6] = {
  GitBranch = {
    provider = function()
      local vcs = require('galaxyline.provider_vcs')
      local branch_name = vcs.get_git_branch()
      if (string.len(branch_name) > 28) then
        return string.sub(branch_name, 1, 25).."..."
      end
      return branch_name .. " "
    end,
    condition = in_git_repo,
    highlight = {colors.fg,colors.bg},
  }
}
gls.left[7] = {
  DiffAdd = {
    provider = 'DiffAdd',
    condition = checkwidth,
    icon = ' ',
    highlight = { colors.green, colors.bg },
  }
}
gls.left[8] = {
  DiffModified = {
    provider = 'DiffModified',
    condition = checkwidth,
    icon = ' ',
    highlight = { colors.orange, colors.bg },
  }
}
gls.left[9] = {
  DiffRemove = {
    provider = 'DiffRemove',
    condition = checkwidth,
    icon = ' ',
    highlight = { colors.red,colors.bg },
  }
}
gls.left[10] = {
  LeftEnd = {
    provider = function() return ' ' end,
    condition = buffer_not_empty,
    highlight = {colors.section_bg,colors.bg}
  }
}
gls.left[11] = {
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = '  ',
    highlight = {colors.red,colors.section_bg}
  }
}
gls.left[12] = {
  Space = {
    provider = function () return ' ' end,
    highlight = {colors.section_bg,colors.section_bg},
  }
}
gls.left[13] = {
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = '  ',
    highlight = {colors.orange,colors.section_bg},
  }
}
gls.left[14] = {
  Space = {
    provider = function () return ' ' end,
    highlight = {colors.section_bg,colors.section_bg},
  }
}
gls.left[15] = {
  DiagnosticInfo = {
    provider = 'DiagnosticInfo',
    icon = '  ',
    highlight = {colors.blue,colors.section_bg},
    separator = ' ',
    separator_highlight = { colors.section_bg, colors.bg },
  }
}

-- Right side
gls.right[1]= {
  FileFormat = {
    provider = function() return vim.bo.filetype end,
    highlight = { colors.fg,colors.section_bg },
    separator = ' ',
    separator_highlight = { colors.section_bg,colors.bg },
  }
}
gls.right[2] = {
  LineInfo = {
    provider = 'LineColumn',
    highlight = { colors.fg, colors.section_bg },
    separator = ' | ',
    separator_highlight = { colors.bg, colors.section_bg },
  },
}
-- gls.right[3] = {
--   Heart = {
--     provider = function() return ' ' end,
--     highlight = { colors.red, colors.section_bg },
--     separator = ' | ',
--     separator_highlight = { colors.bg, colors.section_bg },
--   }
-- }

-- Short status line
gls.short_line_left[1] = {
  BufferType = {
    provider = 'FileTypeName',
    highlight = { colors.fg, colors.section_bg },
    separator = ' ',
    separator_highlight = { colors.section_bg, colors.bg },
  }
}

gls.short_line_right[1] = {
  BufferIcon = {
    provider= 'BufferIcon',
    highlight = { colors.yellow, colors.section_bg },
    separator = ' ',
    separator_highlight = { colors.section_bg, colors.bg },
  }
}

-- Force manual load so that nvim boots with a status line
gl.load_galaxyline()

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

--local gl = require('galaxyline')
--local gls = gl.section
--local extension = require('galaxyline.provider_extensions')

--gl.short_line_list = {
--    'LuaTree',
--    'vista',
--    'dbui',
--    'startify',
--    'term',
--    'nerdtree',
--    'fugitive',
--    'fugitiveblame',
--    'plug'
--}

---- VistaPlugin = extension.vista_nearest

--local colors = {
--    bg = '#282c34',
--    line_bg = '#353644',
--    fg = '#8FBCBB',
--    fg_green = '#65a380',

--    yellow = '#fabd2f',
--    cyan = '#008080',
--    darkblue = '#081633',
--    green = '#afd700',
--    orange = '#FF8800',
--    purple = '#5d4d7a',
--    magenta = '#c678dd',
--    blue = '#51afef';
--    red = '#ec5f67'
--}

--local function lsp_status(status)
--    shorter_stat = ''
--    for match in string.gmatch(status, "[^%s]+")  do
--        err_warn = string.find(match, "^[WE]%d+", 0)
--        if not err_warn then
--            shorter_stat = shorter_stat .. ' ' .. match
--        end
--    end
--    return shorter_stat
--end


--local function get_coc_lsp()
--  local status = vim.fn['coc#status']()
--  if not status or status == '' then
--      return ''
--  end
--  return lsp_status(status)
--end

--function get_diagnostic_info()
--  if vim.fn.exists('*coc#rpc#start_server') == 1 then
--    return get_coc_lsp()
--    end
--  return ''
--end

--local function get_current_func()
--  local has_func, func_name = pcall(vim.fn.nvim_buf_get_var,0,'coc_current_function')
--  if not has_func then return end
--      return func_name
--  end

--function get_function_info()
--  if vim.fn.exists('*coc#rpc#start_server') == 1 then
--    return get_current_func()
--    end
--  return ''
--end

--local function trailing_whitespace()
--    local trail = vim.fn.search("\\s$", "nw")
--    if trail ~= 0 then
--        return ' '
--    else
--        return nil
--    end
--end

--CocStatus = get_diagnostic_info
--CocFunc = get_current_func
--TrailingWhiteSpace = trailing_whitespace

--function has_file_type()
--    local f_type = vim.bo.filetype
--    if not f_type or f_type == '' then
--        return false
--    end
--    return true
--end

--local buffer_not_empty = function()
--  if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
--    return true
--  end
--  return false
--end

--gls.left[1] = {
--  FirstElement = {
--    provider = function() return ' ' end,
--    highlight = {colors.blue,colors.line_bg}
--  },
--}
--gls.left[2] = {
--  ViMode = {
--    provider = function()
--      -- auto change color according the vim mode
--      local alias = {
--          n = 'NORMAL',
--          i = 'INSERT',
--          c= 'COMMAND',
--          V= 'VISUAL',
--          [''] = 'VISUAL',
--          v ='VISUAL',
--          c  = 'COMMAND-LINE',
--          ['r?'] = ':CONFIRM',
--          rm = '--MORE',
--          R  = 'REPLACE',
--          Rv = 'VIRTUAL',
--          s  = 'SELECT',
--          S  = 'SELECT',
--          ['r']  = 'HIT-ENTER',
--          [''] = 'SELECT',
--          t  = 'TERMINAL',
--          ['!']  = 'SHELL',
--      }
--      local mode_color = {
--          n = colors.green,
--          i = colors.blue,v=colors.magenta,[''] = colors.blue,V=colors.blue,
--          c = colors.red,no = colors.magenta,s = colors.orange,S=colors.orange,
--          [''] = colors.orange,ic = colors.yellow,R = colors.purple,Rv = colors.purple,
--          cv = colors.red,ce=colors.red, r = colors.cyan,rm = colors.cyan, ['r?'] = colors.cyan,
--          ['!']  = colors.green,t = colors.green,
--          c  = colors.purple,
--          ['r?'] = colors.red,
--          ['r']  = colors.red,
--          rm = colors.red,
--          R  = colors.yellow,
--          Rv = colors.magenta,
--      }
--      local vim_mode = vim.fn.mode()
--      vim.api.nvim_command('hi GalaxyViMode guifg='..mode_color[vim_mode])
--      return alias[vim_mode] .. '   '
--    end,
--    highlight = {colors.red,colors.line_bg,'bold'},
--  },
--}
--gls.left[3] ={
--  FileIcon = {
--    provider = 'FileIcon',
--    condition = buffer_not_empty,
--    highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.line_bg},
--  },
--}
--gls.left[4] = {
--  FileName = {
--    provider = {'FileName','FileSize'},
--    condition = buffer_not_empty,
--    highlight = {colors.fg,colors.line_bg,'bold'}
--  }
--}

--gls.left[5] = {
--  GitIcon = {
--    provider = function() return '  ' end,
--    condition = require('galaxyline.provider_vcs').check_git_workspace,
--    highlight = {colors.orange,colors.line_bg},
--  }
--}
--gls.left[6] = {
--  GitBranch = {
--    provider = 'GitBranch',
--    condition = require('galaxyline.provider_vcs').check_git_workspace,
--    highlight = {'#8FBCBB',colors.line_bg,'bold'},
--  }
--}

--local checkwidth = function()
--  local squeeze_width  = vim.fn.winwidth(0) / 2
--  if squeeze_width > 40 then
--    return true
--  end
--  return false
--end

--gls.left[7] = {
--  DiffAdd = {
--    provider = 'DiffAdd',
--    condition = checkwidth,
--    icon = ' ',
--    highlight = {colors.green,colors.line_bg},
--  }
--}
--gls.left[8] = {
--  DiffModified = {
--    provider = 'DiffModified',
--    condition = checkwidth,
--    icon = ' ',
--    highlight = {colors.orange,colors.line_bg},
--  }
--}
--gls.left[9] = {
--  DiffRemove = {
--    provider = 'DiffRemove',
--    condition = checkwidth,
--    icon = ' ',
--    highlight = {colors.red,colors.line_bg},
--  }
--}
--gls.left[10] = {
--  LeftEnd = {
--    provider = function() return '' end,
--    separator = '',
--    separator_highlight = {colors.bg,colors.line_bg},
--    highlight = {colors.line_bg,colors.line_bg}
--  }
--}

--gls.left[11] = {
--    TrailingWhiteSpace = {
--     provider = TrailingWhiteSpace,
--     icon = '  ',
--     highlight = {colors.yellow,colors.bg},
--    }
--}

--gls.left[12] = {
--  DiagnosticError = {
--    provider = 'DiagnosticError',
--    icon = '  ',
--    highlight = {colors.red,colors.bg}
--  }
--}
--gls.left[13] = {
--  Space = {
--    provider = function () return ' ' end
--  }
--}
--gls.left[14] = {
--  DiagnosticWarn = {
--    provider = 'DiagnosticWarn',
--    icon = '  ',
--    highlight = {colors.yellow,colors.bg},
--  }
--}


--gls.left[15] = {
--    CocStatus = {
--     provider = CocStatus,
--     highlight = {colors.green,colors.bg},
--     icon = '  🗱'
--    }
--}

--gls.left[16] = {
--  CocFunc = {
--    provider = CocFunc,
--    icon = '  λ ',
--    highlight = {colors.yellow,colors.bg},
--  }
--}

--gls.right[1]= {
--  FileFormat = {
--    provider = 'FileFormat',
--    separator = ' ',
--    separator_highlight = {colors.bg,colors.line_bg},
--    highlight = {colors.fg,colors.line_bg,'bold'},
--  }
--}
--gls.right[4] = {
--  LineInfo = {
--    provider = 'LineColumn',
--    separator = ' | ',
--    separator_highlight = {colors.blue,colors.line_bg},
--    highlight = {colors.fg,colors.line_bg},
--  },
--}
--gls.right[5] = {
--  PerCent = {
--    provider = 'LinePercent',
--    separator = ' ',
--    separator_highlight = {colors.line_bg,colors.line_bg},
--    highlight = {colors.cyan,colors.darkblue,'bold'},
--  }
--}

---- gls.right[4] = {
----   ScrollBar = {
----     provider = 'ScrollBar',
----     highlight = {colors.blue,colors.purple},
----   }
---- }
----
---- gls.right[3] = {
----   Vista = {
----     provider = VistaPlugin,
----     separator = ' ',
----     separator_highlight = {colors.bg,colors.line_bg},
----     highlight = {colors.fg,colors.line_bg,'bold'},
----   }
---- }

--gls.short_line_left[1] = {
--  BufferType = {
--    provider = 'FileTypeName',
--    separator = '',
--    condition = has_file_type,
--    separator_highlight = {colors.purple,colors.bg},
--    highlight = {colors.fg,colors.purple}
--  }
--}


--gls.short_line_right[1] = {
--  BufferIcon = {
--    provider= 'BufferIcon',
--    separator = '',
--    condition = has_file_type,
--    separator_highlight = {colors.purple,colors.bg},
--    highlight = {colors.fg,colors.purple}
--  }
--}

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------


-- local gl = require('galaxyline')
-- local gls = gl.section
-- gl.short_line_list = {'LuaTree','vista','dbui'}

-- local colors = {
--   bg = '#282c34',
--   yellow = '#fabd2f',
--   cyan = '#008080',
--   darkblue = '#081633',
--   green = '#608B4E',
--   orange = '#FF8800',
--   purple = '#5d4d7a',
--   magenta = '#d16d9e',
--   grey = '#c0c0c0',
--   blue = '#569CD6',
--   red = '#D16969'
-- }

-- local buffer_not_empty = function()
--   if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
--     return true
--   end
--   return false
-- end

-- gls.left[2] = {
--   ViMode = {
--     provider = function()
--       -- auto change color according the vim mode
--       local mode_color = {n = colors.purple, 
--                           i = colors.green,
--                           v = colors.blue,
--                           [''] = colors.blue,
--                           V = colors.blue,
--                           c = colors.purple,
--                           no = colors.magenta,
--                           s = colors.orange,
--                           S = colors.orange,
--                           [''] = colors.orange,
--                           ic = colors.yellow,
--                           R = colors.red,
--                           Rv = colors.red,
--                           cv = colors.red,
--                           ce=colors.red, 
--                           r = colors.cyan,
--                           rm = colors.cyan, 
--                           ['r?'] = colors.cyan,
--                           ['!']  = colors.red,
--                           t = colors.red}
--       vim.api.nvim_command('hi GalaxyViMode guibg='..mode_color[vim.fn.mode()])
--       return '  NVIM '
--     end,
--     separator = ' ',
--     separator_highlight = {colors.yellow,function()
--       if not buffer_not_empty() then
--         return colors.bg
--       end
--       return colors.bg
--     end},
--     highlight = {colors.grey,colors.bg,'bold'},
--   },
-- }

-- -- gls.left[3] ={
-- --   FileIcon = {
-- --     separator = ' ',
-- --     provider = 'FileIcon',
-- --     condition = buffer_not_empty,
-- --     highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.bg},
-- --   },
-- -- }
-- -- gls.left[4] = {
-- --   FileName = {
-- --     provider = {'FileSize'},
-- --     condition = buffer_not_empty,
-- --     separator = ' ',
-- --     separator_highlight = {colors.purple,colors.bg},
-- --     highlight = {colors.magenta,colors.bg}
-- --   }
-- -- }

-- gls.left[3] ={
--   FileIcon = {
--     provider = 'FileIcon',
--     condition = buffer_not_empty,
--     highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.line_bg},
--   },
-- }
-- gls.left[4] = {
--   FileName = {
--     provider = {'FileName','FileSize'},
--     condition = buffer_not_empty,
--     highlight = {colors.fg,colors.line_bg,'bold'}
--   }
-- }

-- -- gls.left[3] = {
-- --   GitIcon = {
-- --     provider = function() return ' ' end,
-- --     condition = buffer_not_empty,
-- --     highlight = {colors.orange,colors.bg},
-- --   }
-- -- }
-- -- gls.left[4] = {
-- --   GitBranch = {
-- --     provider = 'GitBranch',
-- --     separator = ' ',
-- --     separator_highlight = {colors.purple,colors.bg},
-- --     condition = buffer_not_empty,
-- --     highlight = {colors.grey,colors.bg},
-- --   }
-- -- }

-- local checkwidth = function()
--   local squeeze_width  = vim.fn.winwidth(0) / 2
--   if squeeze_width > 40 then
--     return true
--   end
--   return false
-- end

-- gls.left[5] = {
--   DiffAdd = {
--     provider = 'DiffAdd',
--     condition = checkwidth,
--     -- separator = ' ',
--     -- separator_highlight = {colors.purple,colors.bg},
--     icon = '  ',
--     highlight = {colors.green,colors.bg},
--   }
-- }
-- gls.left[6] = {
--   DiffModified = {
--     provider = 'DiffModified',
--     condition = checkwidth,
--     -- separator = ' ',
--     -- separator_highlight = {colors.purple,colors.bg},
--     icon = '  ',
--     highlight = {colors.blue,colors.bg},
--   }
-- }
-- gls.left[7] = {
--   DiffRemove = {
--     provider = 'DiffRemove',
--     condition = checkwidth,
--     -- separator = ' ',
--     -- separator_highlight = {colors.purple,colors.bg},
--     icon = '  ',
--     highlight = {colors.red,colors.bg},
--   }
-- }
-- gls.left[8] = {
--   LeftEnd = {
--     provider = function() return ' ' end,
--     separator = ' ',
--     separator_highlight = {colors.purple,colors.bg},
--     highlight = {colors.purple,colors.bg}
--   }
-- }
-- gls.left[9] = {
--   DiagnosticError = {
--     provider = 'DiagnosticError',
--     icon = '  ',
--     highlight = {colors.red,colors.bg}
--   }
-- }
-- gls.left[10] = {
--   Space = {
--     provider = function () return '' end
--   }
-- }
-- gls.left[11] = {
--   DiagnosticWarn = {
--     provider = 'DiagnosticWarn',
--     icon = '  ',
--     highlight = {colors.yellow,colors.bg},
--   }
-- }
-- gls.left[12] = {
--   DiagnosticHint = {
--     provider = 'DiagnosticHint',
--     icon = '   ',
--     highlight = {colors.blue,colors.bg},
--   }
-- }
-- gls.left[13] = {
--   DiagnosticInfo = {
--     provider = 'DiagnosticInfo',
--     icon = '   ',
--     highlight = {colors.orange,colors.bg},
--   }
-- }
-- gls.right[1]= {
--   FileFormat = {
--     provider = 'FileFormat',
--     separator = ' ',
--     separator_highlight = {colors.bg,colors.bg},
--     highlight = {colors.grey,colors.bg},
--   }
-- }
-- gls.right[2] = {
--   LineInfo = {
--     provider = 'LineColumn',
--     separator = ' | ',
--     separator_highlight = {colors.darkblue,colors.bg},
--     highlight = {colors.grey,colors.bg},
--   },
-- }
-- gls.right[3] = {
--   PerCent = {
--     provider = 'LinePercent',
--     separator = ' |',
--     separator_highlight = {colors.darkblue,colors.bg},
--     highlight = {colors.grey,colors.bg},
--   }
-- }
-- gls.right[4] = {
--   ScrollBar = {
--     provider = 'ScrollBar',
--     highlight = {colors.yellow,colors.purple},
--   }
-- }

-- -- gls.short_line_left[1] = {
-- --   BufferType = {
-- --     provider = 'FileTypeName',
-- --     separator = ' ',
-- --     separator_highlight = {colors.purple,colors.bg},
-- --     highlight = {colors.grey,colors.purple}
-- --   }
-- -- }

-- gls.short_line_left[1] = {
--   LeftEnd = {
--     provider = function() return ' ' end,
--     separator = ' ',
--     separator_highlight = {colors.purple,colors.bg},
--     highlight = {colors.purple,colors.bg}
--   }
-- }
