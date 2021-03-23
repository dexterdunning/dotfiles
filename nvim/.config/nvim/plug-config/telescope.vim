lua require("telescope-config")

" telescope remaps
nnoremap <leader>tt <cmd>Telescope<cr>
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fe <cmd>lua require('telescope.builtin').file_browser()<cr>
" nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
nnoremap <leader>fc <cmd>lua require('telescope.builtin').commands()<cr>

" git
nnoremap <leader>fg <cmd>lua require('telescope.builtin').git_files()<cr>
nnoremap <leader>gb <cmd>lua require('telescope.builtin').git_branches()<cr>

" telescope custom
nnoremap <leader>cfg <cmd>lua require('telescope-config').search_dotfiles()<cr>
