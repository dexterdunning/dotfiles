local nvim_lsp = require('lspconfig')

nvim_lsp.omnisharp.setup {
    on_attach = require'completion'.on_attach,
}
