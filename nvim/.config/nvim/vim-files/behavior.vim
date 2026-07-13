set tabstop=4
set softtabstop=4
set expandtab
set shiftwidth=4
set autoindent
set cindent
set number
set relativenumber
set smartcase
set splitright
set splitbelow
set nowrap
set ignorecase
set clipboard=unnamedplus
set autoread

" Octo review comments use <localleader> by default; gcc/gcs override in octo-config.
let maplocalleader = ','

syn keyword   cTodo   contained    TODO FIXME XXX

" Treesitter folding: configured per-buffer in lua/ts-config.lua (FileType).
set foldlevelstart=99
set foldenable
