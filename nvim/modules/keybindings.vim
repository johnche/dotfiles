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

set pastetoggle=<F2>

noremap <F1> :ccl<LF>
noremap <F5> :GundoToggle<LF>
noremap <F7> :NERDTreeToggle<LF>
noremap <F8> :TagbarToggle<LF>
noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>
