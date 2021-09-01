au FocusGained,BufEnter * :checktime
function! Formatonsave()
    let fileName = fnameescape(expand('%:p'))
    execute ':!clang-format -i ' . fileName
    execute ':e!'
endfunction
" autocmd BufWritePre *.h,*.c,*.cpp,*.cs call Formatonsave()
autocmd Filetype c,h,cpp,cs nnoremap <leader>f :call Formatonsave()<cr>
