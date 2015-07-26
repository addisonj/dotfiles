" enable per-directory .vimrc files
set exrc
set secure
set backspace=indent,eol,start

" stuff for vundle
set nocompatible
filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" vundles
Bundle 'gmarik/vundle'
Bundle 'Shougo/neocomplete.vim'

Bundle 'bling/vim-airline'
Bundle 'altercation/vim-colors-solarized'
Bundle 'scrooloose/nerdtree'
Bundle 'kien/ctrlp.vim'
Bundle 'tpope/vim-fugitive'
Bundle 'mattn/gist-vim'
Bundle 'godlygeek/tabular'
Bundle 'tpope/vim-surround'
Bundle 'nathanaelkane/vim-indent-guides'

" lang specific
Bundle 'kchmck/vim-coffee-script'
Bundle "pangloss/vim-javascript"
Bundle 'digitaltoad/vim-jade'
Bundle 'groenewege/vim-less'
Bundle 'tpope/vim-markdown'
Bundle 'fatih/vim-go'
Bundle 'elzr/vim-json'
Bundle 'slim-template/vim-slim.git'
" latex
Bundle 'git://git.code.sf.net/p/vim-latex/vim-latex'
" more latex stuff
let g:Tex_ViewRule_ps = 'open -a Preview'
let g:Tex_ViewRule_pdf = 'open -a Preview'

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


" kill trailing whitespace
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
let g:go_fmt_command = "goimports"
" airline
let g:airline#extensions#tabline#enabled = 1
set laststatus=2
" neo autocompelte
"Note: This option must set it in .vimrc(_vimrc).  NOT IN .gvimrc(_gvimrc)!
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplete#close_popup()
inoremap <expr><C-e>  neocomplete#cancel_popup()

if !exists('g:neocomplcache_omni_patterns')
  let g:neocomplcache_omni_patterns = {}
endif
let g:neocomplcache_omni_patterns.go = '\h\w*'

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

let g:echodoc_enable_at_startup = 1
