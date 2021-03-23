set completeopt=menuone,noinsert,noselect
let g:completion_matching_strategy_list = [ 'exact', 'substring', 'fuzzy' ]

" nvim lsp remaps
nnoremap <silent><leader>gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent><leader>gtd <cmd>tab split<cr><cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent><leader>gD <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent><leader>gr <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent><leader>gi <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent><leader>k <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent><leader><C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent><leader><C-p> <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent><leader><C-n> <cmd>lua vim.lsp.diagnostic.goto_next()<CR>

" nvim compe remaps
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })

highlight link CompeDocumentation NormalFloat

