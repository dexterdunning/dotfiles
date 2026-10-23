nmap <silent><leader>gs :G<CR>
nmap <leader>gc :Git commit<CR>
nmap <leader>gh :Git checkout<CR>
nmap <leader>gp :Git push<CR>
nmap <leader>gf :diffget //2<CR>
nmap <leader>gj :diffget //3<CR>
" Open current line / visual selection on GitHub with the branch name in the
" URL. A ranged :GBrowse deliberately permalinks to a commit SHA (so anchors
" stay valid), so build the branch URL ourselves and append the #L anchor.
function! s:GBrowseBranch(line1, line2) abort
  " A no-range :GBrowse on a working-tree file uses the branch name in the URL.
  let l:saved = getreg('+')
  silent GBrowse!
  let l:url = getreg('+')
  call setreg('+', l:saved)
  if l:url !~# '://'
    echoerr 'fugitive: could not build GitHub URL'
    return
  endif
  let l:url .= '#L' . a:line1 . (a:line2 > a:line1 ? '-L' . a:line2 : '')
  call luaeval('vim.ui.open(_A)', l:url)
endfunction
nnoremap <silent> <leader>go :<C-U>call <SID>GBrowseBranch(line('.'), line('.'))<CR>
vnoremap <silent> <leader>go :<C-U>call <SID>GBrowseBranch(line("'<"), line("'>"))<CR>

