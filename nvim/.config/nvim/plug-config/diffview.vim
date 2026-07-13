" diffview.nvim (lazy-loaded on Diffview* commands)

augroup plug_diffview
  autocmd!
  autocmd User plug#loading#diffview.nvim lua require('diffview-config')
augroup END

" dvl — unstaged + untracked (index → working tree, like `git diff`)
nnoremap <silent><leader>dvl <Cmd>lua require('diffview-review').open_unstaged()<CR>
" dvw — all uncommitted on tracked files (HEAD → working tree, like `git diff HEAD`)
nnoremap <silent><leader>dvw <Cmd>lua require('diffview-review').open_wip()<CR>
" dvb — full branch vs PR base / upstream
nnoremap <silent><leader>dvb <Cmd>lua require('diffview-review').open_branch()<CR>
" dvt — toggle unstaged ↔ branch
nnoremap <silent><leader>dvt <Cmd>lua require('diffview-review').toggle()<CR>
" dvq — close
nnoremap <silent><leader>dvq <Cmd>lua require('diffview-review').close()<CR>
" dvh — file history
nnoremap <silent><leader>dvh <Cmd>DiffviewFileHistory<CR>
