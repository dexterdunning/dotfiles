"    ____      _ __        _
"   /  _/___  (_) /__   __(_)___ ___
"   / // __ \/ / __/ | / / / __ `__ \
" _/ // / / / / /__| |/ / / / / / / /
"/___/_/ /_/_/\__(_)___/_/_/ /_/ /_/
"

let g:python3_host_prog = '/usr/local/bin/python3.10'

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
Plug 'lukas-reineke/indent-blankline.nvim'
" Plug 'sindrets/diffview.nvim'
" Plug 'chrisbra/csv.vim'
" Plug 'GustavoKatel/todo-comments.nvim'

" fuzzy finding 
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
Plug 'windwp/nvim-spectre'

" icons
Plug 'kyazdani42/nvim-web-devicons'
Plug 'ryanoasis/vim-devicons'

" file navigation
Plug 'kyazdani42/nvim-tree.lua'
Plug 'GustavoKatel/sidebar.nvim'

" language specific
Plug 'OmniSharp/omnisharp-vim'

" lsp / autocomplete
Plug 'neovim/nvim-lspconfig'
Plug 'anott03/nvim-lspinstall'
Plug 'alexaandru/nvim-lspupdate'

Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'L3MON4D3/LuaSnip' " added this for TAB complete to work https://github.com/hrsh7th/nvim-cmp/issues/181

Plug 'ray-x/lsp_signature.nvim'

Plug 'windwp/nvim-autopairs'
Plug 'folke/lsp-trouble.nvim'

Plug 'akinsho/flutter-tools.nvim'
Plug 'mfussenegger/nvim-jdtls'
Plug 'jose-elias-alvarez/null-ls.nvim'

Plug 'MunifTanjim/prettier.nvim'
" Plug 'simrat39/symbols-outline.nvim'

" IntelliJ
" Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" Plug 'beeender/Comrade'

" debugging
" Plug 'puremourning/vimspector'

" syntax highlight
Plug 'sakshamgupta05/vim-todo-highlight'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
" Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
"
" status line
Plug 'hoob3rt/lualine.nvim'
" Plug 'glepnir/galaxyline.nvim'
" Plug 'romgrk/barbar.nvim'

" themes
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'kaicataldo/material.vim', { 'branch': 'main' }
Plug 'folke/tokyonight.nvim'
Plug 'vim-airline/vim-airline-themes'
Plug 'junegunn/limelight.vim'

" firenvim
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

call plug#end()

" deoplete for intellij autocomplete
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
source $HOME/.config/nvim/plug-config/telescope.vim
source $HOME/.config/nvim/plug-config/commentary.vim

lua require('lsp-config')
lua require('ts-config')
lua require('lualine-config')
lua require('sidebar-config')
" lua require('todo-config')
" lua require('diffview-config')
lua require('nvim-tree-config')
lua require('null-ls-config')
lua require('prettier-config')
" lua require('indent-blankline-config')


" lua require('quickscope')
" lua require('barbar-config')
source $HOME/.config/nvim/plug-config/lsp.vim

nnoremap <leader>S :lua require('spectre').open()<CR>

"search current word
vnoremap <leader>S :lua require('spectre').open_visual()<CR>
nnoremap <leader>Sw viw:lua require('spectre').open_visual()<CR>
"  search in current file
nnoremap <leader>sp viw:lua require('spectre').open_file_search()<cr>

" ================ jdtls =================
lua << EOF

jdtls_setup = function()
    local root_dir = require('jdtls.setup').find_root({'packageInfo'}, 'Config')
    local home = os.getenv('HOME')
    local eclipse_workspace = home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(root_dir, ':p:h:t')

    local ws_folders_lsp = {}
    local ws_folders_jdtls = {}
    if root_dir then
        local file = io.open(root_dir .. "/.bemol/ws_root_folders", "r");
        if file then
            for line in file:lines() do
                table.insert(ws_folders_lsp, line);
                table.insert(ws_folders_jdtls, string.format("file://%s", line))
            end
            file:close()
        end
    end

    local config = {
        on_attach = on_attach,
        cmd = {'java-lsp.sh', eclipse_workspace},
        root_dir = root_dir,
        init_options = {
            workspaceFolders = ws_folders_jdtls,
        },
    }

    require('jdtls').start_or_attach(config)

    for _,line in ipairs(ws_folders_lsp) do
        vim.lsp.buf.add_workspace_folder(line)
    end
end
EOF

augroup lsp
    autocmd!
    autocmd FileType java luado jdtls_setup()
augroup end
