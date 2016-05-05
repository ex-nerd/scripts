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
filetype indent on

set background=dark
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

" Switch syntax highlighting on when the terminal has colors.
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
    syntax on
    set hlsearch
endif

