vim.g.firenvim_config = {
    localSettings = {
        ["https://quip-amazon*"] = {
            takeover = "never"
        },
        ["*google*"] = {
            takeover = "never"
        },
        ["*twitter.com*"] = {
            takeover = "never"
        },
        ["*x.com*"] = {
            takeover = "never"
        }
    }
}

-- run commands when entering Firenvim
vim.api.nvim_create_autocmd({'UIEnter'}, {
    callback = function(event)
        local client = vim.api.nvim_get_chan_info(vim.v.event.chan).client
        if client ~= nil and client.name == "Firenvim" then
            vim.opt.wrap = true -- :set wrap
        end
    end
})
