"                          _                              __ _
"    _ __   ___  _____   _(_)_ __ ___     ___ ___  _ __  / _(_) __ _
"   | '_ \ / _ \/ _ \ \ / / | '_ ` _ \   / __/ _ \| '_ \| |_| |/ _` |
"   | | | |  __/ (_) \ V /| | | | | | | | (_| (_) | | | |  _| | (_| |
"   |_| |_|\___|\___/ \_/ |_|_| |_| |_|  \___\___/|_| |_|_| |_|\__, |
"         use z [o,c] to open and close folded text            |___/

" {{{ PLUGINS
call plug#begin('~/.config/nvim/plugged')
    Plug 'morhetz/gruvbox'                                          " theme
    Plug 'YorickPeterse/happy_hacking.vim'                          " theme
    Plug 'junegunn/seoul256.vim'                                    " theme
    Plug 'nightsense/vimspectr'                                     " theme
    Plug 'nightsense/simplifysimplify'                              " theme
"    Plug 'vim-airline/vim-airline'                                  " status line
    Plug 'airblade/vim-gitgutter'                                   " show git diffs
    Plug 'scrooloose/nerdtree'                                      " file browser
    Plug 'w0rp/ale'                                                 " linting
    Plug 'Yggdroot/indentLine'                                      " indentation guides
    Plug 'majutsushi/tagbar'                                        " code browser
    Plug 'tpope/vim-surround'                                       " quote manipulation
	Plug 'alvan/vim-closetag'
	Plug 'ElmCast/elm-vim'
"	Plug 'neoclide/vim-jsx-improve'
	Plug 'mxw/vim-jsx'
	Plug 'mattn/emmet-vim'
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }   " code completion
call plug#end()
" }}}

" {{{ PLUGIN SETTINGS
" indentLine
let g:indentLine_setColors = 0
let g:indentLine_char = '▏'
let g:indentLine_conceallevel = 0 " disable hiding symbols

"" airline
"let g:airline#extensions#ale#enabled = 1
"let g:airline#extensions#tabline#enabled = 1
"let g:airline_section=''
"let g:airline_detect_paste=1 " Show PASTE if in paste mode
"let g:airline_powerline_fonts = 1
"if !exists('g:airline_symbols')
"    let g:airline_symbols = {}
"endif
"
"" unicode symbols
"let g:airline_left_sep = '»'
"let g:airline_left_sep = '▶'
"let g:airline_right_sep = '«'
"let g:airline_right_sep = '◀'
"let g:airline_symbols.linenr = '␊'
"let g:airline_symbols.linenr = '␤'
"let g:airline_symbols.linenr = '¶'
""let g:airline_symbols.branch = '⎇'
"let g:airline_symbols.paste = 'ρ'
"let g:airline_symbols.paste = 'Þ'
"let g:airline_symbols.paste = '∥'
"let g:airline_symbols.whitespace = 'Ξ'
"" airline symbols
"let g:airline_left_sep = ''
"let g:airline_left_alt_sep = ''
"let g:airline_right_sep = ''
"let g:airline_right_alt_sep = ''
"let g:airline_symbols.branch = ''
"let g:airline_symbols.readonly = ''
"let g:airline_symbols.linenr = ''

" closetag
let g:closetag_filenames = '*.html,*.xhtml,*.phtml'
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx'
let g:closetag_filetypes = 'html,xhtml,phtml'
let g:closetag_xhtml_filetypes = 'xhtml,jsx'
let g:closetag_emptyTags_caseSensitive = 1
let g:closetag_shortcut = '>'
let g:closetag_close_shortcut = '<leader>>'

" Use deoplete
"let g:deoplete#enable_at_startup = 1

" Python interpreters
"let g:python_host_prog='/usr/bin/python'
"let g:python3_host_prog='/usr/bin/python3'
" }}}

" {{{ BEHAVIOR
set nocompatible    " avoid legacy compatibility nonsense
set path=$PWD/**    " use path vim is opened in as base directory

" menu completion options
set wildmenu        " enhanced command line completion
set wildmode=list:longest,full " complete longest match, list others
set wildignore=.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.jpeg,*.png,*.xpm,*.gif

" search options
set hlsearch        " highlight search
set incsearch       " highlight search results as the search is typed
set magic           " set magic on, for regular expressions
set ignorecase      " searches are not case-sensitive
set smartcase       " case sensitive search if search contains capitals

set backspace=indent,eol,start " allow backspacing over more stuff
set display+=lastline   " always display the last line of the screen
set whichwrap+=<,>,h,l  " allow cursor to wrap lines
set wrap            " soft wrap all files
set confirm         " ask to confirm instead of failing
set linebreak       " keep words whole when wrapping
set scrolloff=2     " start scrolling a few lines from the border
set visualbell      " use colour blink instead of sound
set encoding=utf8   " use utf8 as internal encoding
set hidden          " allow opening new buffers without saving changes
set mouse=a         " allow mouse control in all modes
"set mouse=c         " allow paste from middle button

" undo and backup
set noswapfile      " plenty of RAM, do not need swap
set nobackup        " remembering to save often
set nowritebackup   " is the best kind of backup
set undolevels=100000 " undo history to keep

" panes
set splitbelow      " open new panes on the bottom
set splitright      " open new panes on the right
" }}}

" {{{ INTERFACE
syntax on                   " enable syntax highlighting
set showmatch               " highlight matching brackets
set title                   " set window title
set scrolljump=5           " scroll jump lines
set pumheight=20            " popup menu height
set diffopt+=context:3
set nostartofline           " sticky columns when moving cursor


" line numbers
set number                  " show line numbers
set numberwidth=3           " pad number column
set colorcolumn=101          " highlight 100th column
" uncomment to highlight all columns beyond the 80th
" execute "set colorcolumn=" . join(range(81,335), ',')

" status line
"set showcmd                 " show command in statusline
"set ruler                   " show line and cursor position
"set laststatus=2            " wider status line for airline
"set noshowmode              " hide the default mode text
"set nomodeline              " hide the default mode line
"set shortmess=atToOI        " avoid prompts caused by the file messages
"set updatetime=1500         " status line refresh time

" whitespace
set listchars=tab:>\ ,trail:·        " show tabs and trailing space
set list                            " enable the above settings
autocmd BufWritePre * :%s/\s\+$//e  " auto remove trailing whitespace

" colours
"set t_Co=256                " enable 256 colour themes
colorscheme gruvbox         " gruvbox colourscheme
"colorscheme seoul256
set background=dark         " use dark background

set cursorline              " highlight current line
set ttyfast                 " improves redrawing for newer computers
" }}}

" {{{ FORMATTING
set tabstop=4               " width of tab character
set softtabstop=4           " how many columns the tab key inserts
set shiftwidth=4            " width of indentation levels
set noexpandtab               " Use tabs
set smartindent             " smart autoindenting
filetype plugin indent on   " determine indentation rules by filetype

" folding
set foldenable
set foldmethod=marker
set foldlevel=0
set foldcolumn=0
" }}}

" {{{ KEYBINDINGS
let mapleader = ' '         " use spacebar as map leader
let g:mapleader = ' '       " same-same but different

" NERDTree
nnoremap <Leader>n  :NERDTreeToggle<CR>

" indentLine
nnoremap <Leader>i  :IndentLinesToggle<CR>

" tagbar
nnoremap <Leader>t  :TagbarToggle<CR>

" buffer management
nnoremap tg  :buffer<Space> " go to buffer x
nnoremap th  :bfirst<CR>    " go to first buffer
nnoremap tj  :bnext<CR>     " go to next buffer
nnoremap tk  :bprev<CR>     " go to previous buffer
nnoremap tl  :blast<CR>     " go to last buffer
nnoremap tt  :edit<Space>   " open file in current buffer
nnoremap tn  :enew<CR>      " open file in new buffer
nnoremap td  :bdelete<CR>   " close current buffer
nnoremap ts  :files<CR>     " list buffers

" space clears search highlights and any message displayed
nnoremap <silent> <Space> :silent noh<Bar>echo<CR>

" move lines up and down with alt + [j,k]
nnoremap <A-j> :m+<CR>==
nnoremap <A-k> :m-2<CR>==
vnoremap <A-j> :m'>+<CR>gv=gv
vnoremap <A-k> :m-2<CR>gv=gv

" indenting
nnoremap <Tab> >>_          " increase indent with >>
nnoremap <S-Tab> <<_        " decrease indent with <<
inoremap <S-Tab> <C-D>
vnoremap <Tab> >gv          " tab to increase indent
vnoremap <S-Tab> <gv        " shift tab to decrease indent

" save file as root
noremap <Leader>W :w !sudo tee % > /dev/null<CR>

" left and right arrow keys to move between buffers
"nnoremap <silent> <Right>   :bn<CR>
"nnoremap <silent> <Left>  :bp<CR>

"map <C-c> "+y<CR>           " ctrl c to copy selected text
"map <C-v> "+p<CR>           " ctrl v to paste text

" toggle paste mode
set pastetoggle=<F2>

" NerdTree
" silent! nmap <C-p> :NERDTreeToggle<CR>
silent! map <F3> :NERDTreeFind<CR>
let g:NERDTreeMapActivateNode="<F3>"
let g:NERDTreeMapPreview="<F4>"
" }}}
