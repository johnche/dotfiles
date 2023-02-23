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

set noswapfile
set undofile
set undodir=$HOME/.config/nvim/undodir
set wildignore+=*/node_modules/*,*/.git/*

syntax on
"set t_Co=256
set background=light
colorscheme solarized
"set background=dark
"colorscheme seoul256
"colorscheme gruvbox
"colorscheme onehalflight
set colorcolumn=101
set scrolljump=5
set scrolloff=2
set ttyfast
set splitright
set splitbelow

set laststatus=2
set showcmd ruler
set nu rnu
set cursorline showmatch hlsearch incsearch magic
"set ignorecase
"set smartcase

set noexpandtab
set shiftwidth=4
set tabstop=4
set autoindent

set list!
set list listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·

set mouse=a
set pastetoggle=<F2>
noremap <Up> :bnext<LF>
noremap <Down> :bprev<LF>
noremap <Left> :tabprev<LF>
noremap <Right> :tabnext<LF>

nnoremap <C-p> :Files<LF>
nnoremap <C-j> :Buffers<LF>
nnoremap <C-h> :GFiles<LF>
nnoremap <C-n> :Rg<LF>

nmap <silent> <A-Up> :wincmd k<LF>
nmap <silent> <A-Down> :wincmd j<LF>
nmap <silent> <A-Left> :wincmd h<CR>
nmap <silent> <A-Right> :wincmd l<LF>

noremap <C-b> :Git blame<LF>
noremap <F7> :NERDTreeToggle<LF>
noremap <F8> :TagbarToggle<LF>
noremap <F5> :GundoToggle<LF>
noremap <F1> :ccl<LF>

noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>

" XML folding
let g:xml_syntax_folding=1
au FileType xml setlocal foldmethod=syntax

"source $HOME/.config/nvim/timestamp.vim
"noremap <F4> :TimeStampToggle<LF>
"noremap <F3> !!date<LF>

"tags
"set statusline+=%{gutentags#statusline()}
set tags=~/.cache/tags/.tags;,.tags
let g:gutentags_project_root = ['.root', '.svn', '.git', '.hg', '.project']
let g:gutentags_ctags_tagfile = '.tags'
let g:gutentags_modules = ['ctags']
let g:gutentags_cache_dir = expand('~/.config/nvim/tags')
let g:gutentags_ctags_extra_args = ['--fields=+niazS', '--extra=+q']
let g:gutentags_ctags_extra_args += ['--c++-kinds=+px']
let g:gutentags_ctags_extra_args += ['--c-kinds=+px']
let g:gutentags_ctags_extra_args += ['--output-format=e-ctags']
let g:tagbar_ctags_bin = 'ctags'
let g:tagbar_type_typescript = {
  \ 'ctagsbin' : 'tstags',
  \ 'ctagsargs' : '-f-',
  \ 'kinds': [
    \ 'e:enums:0:1',
    \ 'f:function:0:1',
    \ 't:typealias:0:1',
    \ 'M:Module:0:1',
    \ 'I:import:0:1',
    \ 'i:interface:0:1',
    \ 'C:class:0:1',
    \ 'm:method:0:1',
    \ 'p:property:0:1',
    \ 'v:variable:0:1',
    \ 'c:const:0:1',
  \ ],
  \ 'sort' : 0
\ }


" Accept extra key after <c-z>
"let g:ctrlp_arg_map = 1
"let g:ctrlp_working_path_mode = 'ca'
"let g:ale_fixers['javascript'] = ['eslint']
"let g:ale_fixers['typescript'] = ['eslint']
let g:python_recommended_style=0
let g:prettier#autoformat_config_files = ['prettier.config.cjs']
let g:prettier#autoformat_config_present = 1
let g:prettier#config#config_precedence = 'prefer-file'
filetype plugin indent on
"au BufRead,BufNewFile *.tsx set filetype=typescript
au BufRead,BufNewFile *.tsx set filetype=typescriptreact
au BufRead,BufNewFile *.jsx set filetype=javascriptreact
packloadall

execute "source" "$HOME/.config/nvim/modules/coc.vim"
"execute "source" "$HOME/.config/nvim/modules/nvim-lsp.vim"
