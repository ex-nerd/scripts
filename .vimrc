execute pathogen#infect()

" Turn off compatibility mode
set nocompatible

" Case-insensitive searches
set ignorecase

" Show line/column numbers
set ruler
set nu

" Flash matching brackets
set showmatch

" Disable mouse support.
set mouse=

" Indent engines
filetype plugin indent on

set backspace=indent,eol,start    " allow backspace over anything in insert mode

"
"  AutoCommmand options
"
if has("autocmd")

    " Remove all (previous) autocommands for the current group.
    " autocmd!

    " TXT file type isn't always getting detected so handle it explicitly
    autocmd BufNewFile,BufRead *.txt set filetype=txt

    "
    "  Modify options for files I might be editing often:
    "
    "   Set tab stops to 4, and enable soft tabs
    "   Enable smart auto-indent
    "
    autocmd FileType c,html,perl,php,python,sh,txt
        \ set tabstop=4         |
        \ set softtabstop=4     |
        \ set expandtab         |
        \ set autoindent        |
        \ set smarttab          |
        \ set shiftwidth=4

    autocmd FileType c,html,perl,php,python,sh,txt
        \ autocmd BufWritePre <buffer> :%s/\s\+$//e

endif

" Also switch on highlighting the last used search pattern.
set hlsearch

" Enable syntax lighlighting and the solarized theme
syntax enable
set background=dark
" let g:solarized_termcolors=256
colorscheme solarized
