call plug#begin('~/.config/nvim/plugged')
	Plug 'morhetz/gruvbox'
	Plug 'sonph/onehalf', {'rtp': 'vim/'}
	Plug 'NLKNguyen/papercolor-theme'
	Plug 'altercation/vim-colors-solarized'
	Plug 'junegunn/seoul256.vim'

	Plug 'sjl/gundo.vim'
	Plug 'godlygeek/tabular'
	Plug 'tpope/vim-surround'
	Plug 'preservim/nerdtree'
	Plug 'mhinz/vim-startify'
	Plug 'itchyny/lightline.vim'
	Plug 'tpope/vim-unimpaired'
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }

	Plug 'majutsushi/tagbar'
	Plug 'ludovicchabant/vim-gutentags'
	Plug 'ternjs/tern_for_vim'

	Plug 'airblade/vim-gitgutter'
	Plug 'tpope/vim-fugitive'
	Plug 'tpope/vim-rhubarb'
	Plug 'shumphrey/fugitive-gitlab.vim'

	Plug 'tpope/vim-sleuth'
	Plug 'w0rp/ale'
	Plug 'prettier/vim-prettier', {'do': 'npm install'}
	Plug 'neovim/nvim-lspconfig'
	Plug 'nvim-lua/lsp-status.nvim'
	Plug 'Yggdroot/indentLine'
	Plug 'neoclide/coc.nvim', {'branch': 'release'}

	Plug 'sheerun/vim-polyglot'
	"Plug 'styled-components/vim-styled-components', {'branch': 'main'} "
	"vim styled component with polyglot breaks js indent
call plug#end()


set nocompatible
"set path=$PWD/**

set noswapfile undofile
set undodir=$HOME/.config/nvim/undodir
set wildignore+=*/node_modules/*,*/.git/*

syntax on
set background=light
colorscheme solarized

"set background=dark
"colorscheme seoul256
"colorscheme gruvbox

set colorcolumn=101
set scrolljump=5
set scrolloff=2
set ttyfast
set splitright splitbelow

set laststatus=2
set showcmd ruler
set nu rnu
set cursorline showmatch hlsearch incsearch magic
"set ignorecase
"set smartcase

set noexpandtab autoindent
set shiftwidth=4
set tabstop=4

set list! listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·

set mouse=a

" XML folding
let g:xml_syntax_folding=1
au FileType xml setlocal foldmethod=syntax


execute "source" "$HOME/.config/nvim/modules/keybindings.vim"
execute "source" "$HOME/.config/nvim/modules/languages.vim"

execute "source" "$HOME/.config/nvim/modules/lightline.vim"
execute "source" "$HOME/.config/nvim/modules/gutentags.vim"
execute "source" "$HOME/.config/nvim/modules/coc.vim"
"execute "source" "$HOME/.config/nvim/modules/nvim-lsp.vim"

filetype plugin indent on
packloadall
