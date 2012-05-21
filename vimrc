" enable per-directory .vimrc files
set exrc			
set secure
" Pathogen Setup!
filetype off 
call pathogen#infect()
" theme
let g:solarized_termtrans=1
if has('gui_running')
    set background=dark
else
    set background=dark
endif
colorscheme solarized
set nu

syntax enable

" Font
set guifont=Inconsolata:h16
" indent Stuff
filetype on
filetype plugin indent on
" default stuff
set ts=2
set sts=2
set sw=2
set expandtab
" Syntastic (Errors and what not)
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_enable_signs=1
let g:syntastic_auto_loc_list=1
let g:syntastic_cpp_check_header = 1
let g:syntastic_mode_map = { 'mode' : 'active',
                           \ 'passive_filetypes' : ['coffee'] }
" Mappings and bindings
set pastetoggle=<F3>
map <F5> :NERDTreeToggle<CR>
map <C-F12> :!ctags -R --c++-kinds=+pl --fields=+iaS --extra=+q .<CR>

" clang stuff
let g:clang_hl_errors=0
let g:clang_snippets_engine="snipmate"
let g:clang_user_options="|| exit 0"

highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%121v.\+/

autocmd BufWritePost *.coffee silent CoffeeMake! -b | cwindow | redraw!
autocmd BufWritePost *.coffee silent CoffeeLint! | cwindow | redraw!
