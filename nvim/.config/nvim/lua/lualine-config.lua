-- Ultra-minimal lualine configuration to prevent hanging in large projects
require('lualine').setup({
    options = {
        icons_enabled = false,
        theme = 'auto',
        component_separators = '',
        section_separators = '',
        disabled_filetypes = {},
        globalstatus = true,
        refresh = {
            statusline = 10000, -- Very infrequent refresh (10 seconds)
            tabline = 10000,
            winbar = 10000,
        },
    },
    sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'}, -- Only show filename to minimize refresh triggers
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
    },
    extensions = {}
})
