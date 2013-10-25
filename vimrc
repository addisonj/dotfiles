" enable per-directory .vimrc files
set exrc
set secure

" stuff for vundle
set nocompatible
filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" vundles
Bundle 'gmarik/vundle'

Bundle 'altercation/vim-colors-solarized'
Bundle 'scrooloose/nerdtree'
Bundle 'kien/ctrlp.vim'
Bundle 'tpope/vim-fugitive'
Bundle 'mattn/gist-vim'
Bundle 'godlygeek/tabular'
Bundle 'tpope/vim-surround'
Bundle 'nathanaelkane/vim-indent-guides'
Bundle 'ervandew/supertab'

" lang specific
Bundle 'kchmck/vim-coffee-script'
Bundle 'digitaltoad/vim-jade'
Bundle 'groenewege/vim-less'
Bundle 'tpope/vim-markdown'
"Bundle 'jnwhiteh/vim-golang'
Bundle 'Blackrush/vim-gocode'

" theme
let g:solarized_termtrans=1
if has('gui_running')
    set background=dark
    set guioptions=egmrt
    set guioptions-=r
else
    set background=light
endif
colorscheme solarized
" general
set hlsearch
set incsearch
set ignorecase
set smartcase
set nu
set smartindent

" indent Stuff
set runtimepath+=$GOROOT/misc/vim
filetype plugin indent on


" kill training whitespace
set listchars=tab:\ \ ,trail:·,extends:>,precedes:\<

" language stuff
autocmd BufNewFile,BufRead *.template set filetype=json
autocmd BufNewFile,BufRead *.coffin set filetype=coffee
autocmd BufWritePre * :%s/\s\+$//e
autocmd BufWritePre *.go :Fmt

" default stuff
syntax enable
set ts=2
set sts=2
set sw=2
set expandtab
" Font
set guifont=Inconsolata:h16

" Mappings and bindings
let mapleader=","
set pastetoggle=<F3>
" clear search buffer
nmap <silent> <leader>cl :let @/=""<CR>

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

" highlight long lines
"highlight OverLength ctermbg=red ctermfg=white guibg=#592929
"match OverLength /\%121v.\+/


" plugin specific
" ctrlp
set wildignore+=*/tmp/*,*.so,*.swp,*.zip
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
map <leader>p :CtrlP<CR>
let g:ctrlp_max_files = 10000
" NerdTree
map <F5> :NERDTreeToggle<CR>
" vim-coffee-script
let coffee_lint_options = '-f ~/.coffee-lint.json'
" golang stuff
map <silent> <leader>f :Fmt<CR>
" supertab
let g:SuperTabDefaultCompletionType = "<C-X><C-O>"
let g:SuperTabClosePreviewOnPopupClose = 1
