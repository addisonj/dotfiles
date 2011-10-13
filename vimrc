" Pathogen Setup!
filetype off 
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()
" theme
let g:solarized_termtrans=1
if has('gui_running')
    set background=light
else
    set background=dark
endif
colorscheme solarized
set nu
" indent Stuff
set autoindent
filetype on
filetype indent on
" Syntastic (Errors and what not)
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_enable_signs=1
let g:syntastic_auto_loc_list=1
let g:syntastic_cpp_check_header = 1
" Mappings and bindings
set pastetoggle=<F3>
map <F3> :NERDTreeToggle<CR>
map <C-F12> :!ctags -R --c++-kinds=+pl --fields=+iaS --extra=+q .<CR>
" File Type defs
autocmd FileType javascript set tabstop=2|set shiftwidth=2|set softtabstop=2|set expandtab|set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType css set tabstop=2|set shiftwidth=2|set softtabstop=2|set expandtab
autocmd FileType cpp set tabstop=2|set shiftwidth=2|set softtabstop=2|set expandtab
" clang stuff
let g:clang_hl_errors=0
let g:clang_snippets_engine="snipmate"
let g:clang_user_options="|| exit 0"
" Stuff for latex-suite
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/
