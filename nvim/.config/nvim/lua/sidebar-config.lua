require("sidebar-nvim").setup({
    disable_default_keybindings = 0,
    bindings = { ["q"] = function() require("sidebar-nvim").close() end },
    open = false,
    side = "left",
    initial_width = 35,
    update_interval = 5000, -- Increased from 1000ms to 5000ms for large projects
    sections = { "diagnostics" }, -- Removed "git", "todos" which are expensive in large repos
    section_separator = "-----"
})
