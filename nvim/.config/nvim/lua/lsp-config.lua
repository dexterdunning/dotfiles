local nvim_lsp = require('lspconfig')

-- nvim-compe complete autopairs
require("nvim-autopairs.completion.compe").setup({
    map_cr = true, --  map <CR> on insert mode
    map_complete = true -- it will auto insert `(` after select function or method item
})

local on_attach = function(client, bufnr)
    -- Set autocommands conditional on server_capabilities
    -- if client.resolved_capabilities.document_highlight then
    --     vim.api.nvim_exec([[
    --     hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
    --     hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
    --     hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
    --     augroup lsp_document_highlight
    --     autocmd! * <buffer>
    --     autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
    --     autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
    --     augroup END
    --         ]], false)
    -- end
    require "lsp_signature".on_attach()  -- Note: add in lsp client on-attach

    -- client.resolved_capabilities.document_formatting = false
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

local servers
if vim.loop.os_uname().sysname == "Linux" then
    -- local servers = { "ccls", "omnisharp", "pyls", "vimls", "dartls" }
    servers = { "ccls", "omnisharp", "pyls", "vimls" }
else
    servers = { "ccls", "tsserver" }
end

for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup { 
        capabilities = capabilities;
        on_attach = on_attach;
        -- root_dir = nvim_lsp.util.root_pattern('.git');
    }
end

-- ------------------------------------
-- Python
--
-- https://github.com/python-lsp/python-lsp-server
-- ------------------------------------
local python_on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  -- vim.keymap.set('n', '<space>wl', function()
  --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  -- end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
end

nvim_lsp.pylsp.setup{
    on_attach = python_on_attach;
}


-- ------------------------------------
-- Typescript
-- ------------------------------------

local format_async = function(err, _, result, _, bufnr)
    if err ~= nil or result == nil then return end
    if not vim.api.nvim_buf_get_option(bufnr, "modified") then
        local view = vim.fn.winsaveview()
        vim.lsp.util.apply_text_edits(result, bufnr)
        vim.fn.winrestview(view)
        if bufnr == vim.api.nvim_get_current_buf() then
            vim.api.nvim_command("noautocmd :update")
        end
    end
end
vim.lsp.handlers["textDocument/formatting"] = format_async
_G.lsp_organize_imports = function()
    local params = {
        command = "_typescript.organizeImports",
        arguments = {vim.api.nvim_buf_get_name(0)},
        title = ""
    }
    vim.lsp.buf.execute_command(params)
end
local on_attach_ts = function(client, bufnr)
    local buf_map = vim.api.nvim_buf_set_keymap
    vim.cmd("command! LspDef lua vim.lsp.buf.definition()")
    vim.cmd("command! LspFormatting lua vim.lsp.buf.formatting()")
    vim.cmd("command! LspCodeAction lua vim.lsp.buf.code_action()")
    vim.cmd("command! LspHover lua vim.lsp.buf.hover()")
    vim.cmd("command! LspRename lua vim.lsp.buf.rename()")
    vim.cmd("command! LspOrganize lua lsp_organize_imports()")
    vim.cmd("command! LspRefs lua vim.lsp.buf.references()")
    vim.cmd("command! LspTypeDef lua vim.lsp.buf.type_definition()")
    vim.cmd("command! LspImplementation lua vim.lsp.buf.implementation()")
    vim.cmd("command! LspDiagPrev lua vim.lsp.diagnostic.goto_prev()")
    vim.cmd("command! LspDiagNext lua vim.lsp.diagnostic.goto_next()")
    vim.cmd(
        "command! LspDiagLine lua vim.lsp.diagnostic.show_line_diagnostics()")
    vim.cmd("command! LspSignatureHelp lua vim.lsp.buf.signature_help()")
    buf_map(bufnr, "n", "gd", ":LspDef<CR>", {silent = true})
    buf_map(bufnr, "n", "gr", ":LspRename<CR>", {silent = true})
    buf_map(bufnr, "n", "gR", ":LspRefs<CR>", {silent = true})
    buf_map(bufnr, "n", "gy", ":LspTypeDef<CR>", {silent = true})
    buf_map(bufnr, "n", "K", ":LspHover<CR>", {silent = true})
    buf_map(bufnr, "n", "gs", ":LspOrganize<CR>", {silent = true})
    buf_map(bufnr, "n", "[a", ":LspDiagPrev<CR>", {silent = true})
    buf_map(bufnr, "n", "]a", ":LspDiagNext<CR>", {silent = true})
    buf_map(bufnr, "n", "ga", ":LspCodeAction<CR>", {silent = true})
    buf_map(bufnr, "n", "<Leader>a", ":LspDiagLine<CR>", {silent = true})
    buf_map(bufnr, "i", "<C-x><C-x>", "<cmd> LspSignatureHelp<CR>",
              {silent = true})
-- if client.resolved_capabilities.document_formatting then
--         vim.api.nvim_exec([[
--          augroup LspAutocommands
--              autocmd! * <buffer>
--              autocmd BufWritePost <buffer> LspFormatting
--          augroup END
--          ]], true)
--     end
end
nvim_lsp.tsserver.setup {
    -- on_attach_ts = function(client)
    --     client.resolved_capabilities.document_formatting = false
    --     on_attach_ts(client)
    -- end
    on_attach_ts = on_attach_ts
}
local filetypes = {
    typescript = "eslint",
    typescriptreact = "eslint",
}
local linters = {
    eslint = {
        sourceName = "eslint",
        command = "eslint_d",
        rootPatterns = {".eslintrc.js", "package.json"},
        debounce = 100,
        args = {"--stdin", "--stdin-filename", "%filepath", "--format", "json"},
        parseJson = {
            errorsRoot = "[0].messages",
            line = "line",
            column = "column",
            endLine = "endLine",
            endColumn = "endColumn",
            message = "${message} [${ruleId}]",
            security = "severity"
        },
        securities = {[2] = "error", [1] = "warning"}
    }
}
local formatters = {
    prettier = {command = "prettier", args = {"--stdin-filepath", "%filepath"}}
}
local formatFiletypes = {
    typescript = "prettier",
    typescriptreact = "prettier"
}
nvim_lsp.diagnosticls.setup {
    on_attach = on_attach,
    filetypes = vim.tbl_keys(filetypes),
    init_options = {
        filetypes = filetypes,
        linters = linters,
        formatters = formatters,
        formatFiletypes = formatFiletypes
    }
}

-- ------------------------------------
--
-- ------------------------------------

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
