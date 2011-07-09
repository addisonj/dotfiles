" Pathogen Setup!
filetype off 
call pathogen#helptags()
call pathogen#runtime_append_all_bundles()
" indent Stuff
set autoindent
filetype on
filetype indent on
" Syntastic (Errors and what not)
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
" Mappings and bindings
set pastetoggle=<F2>
map <F3> :NERDTreeToggle<CR>
map <C-F12> :!ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .<CR>
" File Type defs
autocmd FileType javascript set tabstop=2|set shiftwidth=2|set softtabstop=2|set expandtab|set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType css set tabstop=2|set shiftwidth=2|set softtabstop=2|set expandtab
autocmd FileType cpp set tabstop=2|set shiftwidth=2|set softtabstop=2|set expandtab
