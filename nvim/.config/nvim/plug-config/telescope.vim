lua require("telescope-config")

" telescope remaps
nnoremap <leader>tt <cmd>Telescope<cr>
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fe <cmd>lua require('telescope.builtin').file_browser()<cr>
nnoremap <leader>ft <cmd>lua require('telescope.builtin').treesitter()<cr>
nnoremap <leader>lg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>rg <cmd>lua require('telescope.builtin').grep_string()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
nnoremap <leader>fc <cmd>lua require('telescope.builtin').commands()<cr>

" git
nnoremap <leader>fg <cmd>lua require('telescope.builtin').git_files()<cr>
nnoremap <leader>gb <cmd>lua require('telescope.builtin').git_branches()<cr>

" telescope custom
nnoremap <leader>cfg <cmd>lua require('telescope-config').search_dotfiles()<cr>

" Rippling-specific optimized commands
nnoremap <leader>fa <cmd>lua require('telescope-config').find_app_files()<cr>
nnoremap <leader>fp <cmd>lua require('telescope-config').find_python_files()<cr>
nnoremap <leader>fj <cmd>lua require('telescope-config').find_js_files()<cr>
nnoremap <leader>sa <cmd>lua require('telescope-config').search_in_app()<cr>
nnoremap <leader>fc <cmd>lua require('telescope-config').search_configs()<cr>
nnoremap <leader>ft <cmd>lua require('telescope-config').search_tests()<cr>
nnoremap <leader>fr <cmd>lua require('telescope-config').search_recent_files()<cr>

" Enhanced live grep with args
nnoremap <leader>la <cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>

" show diagnostics
nnoremap <leader>xx <cmd>Telescope diagnostics<cr>
nnoremap <leader>xw <cmd>Telescope diagnostics bufnr=0<cr>
nnoremap <leader>xl <cmd>Telescope lsp_document_diagnostics<cr>
