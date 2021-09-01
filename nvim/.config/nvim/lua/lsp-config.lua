local nvim_lsp = require('lspconfig')

-- nvim-compe complete autopairs
require("nvim-autopairs.completion.compe").setup({
    map_cr = true, --  map <CR> on insert mode
    map_complete = true -- it will auto insert `(` after select function or method item
})

local on_attach = function(client, bufnr)
    -- Set autocommands conditional on server_capabilities
    if client.resolved_capabilities.document_highlight then
        vim.api.nvim_exec([[
        hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
        hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
        hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
        augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
            ]], false)
    end
    require "lsp_signature".on_attach()  -- Note: add in lsp client on-attach
end

require'compe'.setup {
    enabled = true;
    autocomplete = true;
    debug = true;
    min_length = 1;
    preselect = 'enable';
    throttle_time = 80;
    source_timeout = 200;
    incomplete_delay = 400;
    max_abbr_width = 100;
    max_kind_width = 100;
    max_menu_width = 100;
    documentation = true;

    source = {
        path = true;
        buffer = true;
        calc = true;
        vsnip = true;
        nvim_lsp = true;
        nvim_lua = true;
        spell = true;
        tags = true;
        snippets_nvim = true;
        treesitter = true;
    };
}

vim.o.completeopt = "menuone,noselect"
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

-- local servers = { "ccls", "omnisharp", "pyls", "vimls", "dartls" }
-- local servers = { "ccls", "omnisharp", "pyls", "vimls" }
-- for _, lsp in ipairs(servers) do
--     nvim_lsp[lsp].setup { 
--         capabilities = capabilities;
--         on_attach = on_attach;
--         -- root_dir = nvim_lsp.util.root_pattern('.git');
--     }
-- end

-- flutter/dart lsp setup
require("flutter-tools").setup {
    experimental = { -- map of feature flags
        lsp_derive_paths = false, -- experimental: Attempt to find the user's flutter SDK
    },
    debugger = { -- experimental: integrate with nvim dap
        enabled = false,
    },
    widget_guides = {
        enabled = false,
    },
    closing_tags = {
        highlight = "ErrorMsg", -- highlight for the closing tag
        prefix = ">" -- character to use for close tag e.g. > Widget
    },
    dev_log = {
        open_cmd = "tabedit", -- command to use to open the log buffer
    },
    outline = {
        open_cmd = "30vnew", -- command to use to open the outline buffer
    },
    lsp = {
        on_attach = on_attach,
        capabilities = capabilities, -- e.g. lsp_status capabilities
        settings = {
            showTodos = true,
            completeFunctionCalls = true -- NOTE: this is WIP and doesn't work currently
        }
    }
}
-- ------------------------------------
-- nvim compe tab complete
-- ------------------------------------
local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return t "<C-n>"
    elseif vim.fn.call("vsnip#available", {1}) == 1 then
        return t "<Plug>(vsnip-expand-or-jump)"
    elseif check_back_space() then
        return t "<Tab>"
    else
        return vim.fn['compe#complete']()
    end
end
_G.s_tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return t "<C-p>"
    elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
        return t "<Plug>(vsnip-jump-prev)"
    else
        return t "<S-Tab>"
    end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})

require("trouble").setup {
}

-- local opts = {
--     -- whether to highlight the currently hovered symbol
--     -- disable if your cpu usage is higher than you want it
--     -- or you just hate the highlight
--     -- default: true
--     highlight_hovered_item = true,

--     -- whether to show outline guides 
--     -- default: true
--     show_guides = true,
-- }

-- require('symbols-outline').setup(opts)
