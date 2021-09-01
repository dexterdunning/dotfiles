"    ____      _ __        _
"   /  _/___  (_) /__   __(_)___ ___
"   / // __ \/ / __/ | / / / __ `__ \
" _/ // / / / / /__| |/ / / / / / / /
"/___/_/ /_/_/\__(_)___/_/_/ /_/ /_/

call plug#begin(stdpath('data') . '/plugged')

" tools
" Plug 'ThePrimeagen/vim-be-good', {'do': './install.sh'}
Plug 'machakann/vim-sandwich'
Plug 'lifepillar/vim-cheat40'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'drzel/vim-scroll-in-place'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'simplenote-vim/simplenote.vim'
Plug 'farmergreg/vim-lastplace'
Plug 'unblevable/quick-scope' 
Plug 'psliwka/vim-smoothie'

" Plug 'lukas-reineke/indent-blankline.nvim', {'branch': 'lua'}

" fuzzy finding 
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
" Plug 'windwp/nvim-spectre'

" icons
Plug 'kyazdani42/nvim-web-devicons'
Plug 'ryanoasis/vim-devicons'

" file navigation
Plug 'kyazdani42/nvim-tree.lua'

" language specific
Plug 'OmniSharp/omnisharp-vim'

" lsp / autocomplete
Plug 'neovim/nvim-lspconfig'
Plug 'anott03/nvim-lspinstall'
Plug 'alexaandru/nvim-lspupdate'
Plug 'hrsh7th/nvim-compe'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'honza/vim-snippets'
Plug 'ray-x/lsp_signature.nvim'
Plug 'jiangmiao/auto-pairs'
Plug 'windwp/nvim-autopairs'

" IntelliJ
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'beeender/Comrade'

" debugging
" Plug 'puremourning/vimspector'

" syntax highlight
Plug 'nvim-treesitter/nvim-treesitter', {'branch': 'master', 'do': ':TSUpdate'}  " We recommend updating the parsers on update
" Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'sakshamgupta05/vim-todo-highlight'

" status line
Plug 'glepnir/galaxyline.nvim'
" Plug 'romgrk/barbar.nvim'

" themes
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'kaicataldo/material.vim', { 'branch': 'main' }
Plug 'vim-airline/vim-airline-themes'
Plug 'junegunn/limelight.vim'

call plug#end()

let g:deoplete#enable_at_startup = 1

source $HOME/.config/nvim/vim-files/behavior.vim
source $HOME/.config/nvim/vim-files/remaps.vim
source $HOME/.config/nvim/vim-files/color.vim

source $HOME/.config/nvim/plug-config/fugitive.vim
source $HOME/.config/nvim/plug-config/cheat40.vim
source $HOME/.config/nvim/plug-config/python-syntax.vim
source $HOME/.config/nvim/plug-config/splitjoin.vim
source $HOME/.config/nvim/plug-config/format.vim
source $HOME/.config/nvim/plug-config/markdown.vim
source $HOME/.config/nvim/plug-config/simplenote.vim
source $HOME/.config/nvim/plug-config/omnisharp.vim
source $HOME/.config/nvim/plug-config/telescope.vim
source $HOME/.config/nvim/plug-config/commentary.vim
source $HOME/.config/nvim/plug-config/nvim-tree.vim

" lua require('quickscope')
lua require('lsp-config')
" lua require('omnisharp-lsp')
lua require('ts-config')
lua require('galaxyline-config')
" lua require('barbar-config')
source $HOME/.config/nvim/plug-config/lsp.vim

lua require'lsp_signature'.on_attach()

let g:vimspector_enable_mappings = 'HUMAN'


"nnoremap <leader>S :lua require('spectre').open()<CR>

""search current word
"vnoremap <leader>S :lua require('spectre').open_visual()<CR>
"nnoremap <leader>Sw viw:lua require('spectre').open_visual()<CR>
""  search in current file
"nnoremap <leader>sp viw:lua require('spectre').open_file_search()<cr>
