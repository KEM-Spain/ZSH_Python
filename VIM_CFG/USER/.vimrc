if !has("gui_running")
	" rainbow brackets settings
	let g:rainbow_active = 1
	let g:rainbow_guifgs = ['RoyalBlue3', 'DarkOrange3', 'DarkOrchid3', 'FireBrick']
	let g:rainbow_ctermfgs = ['lightblue', 'lightgreen', 'yellow', 'red', 'magenta']

	"Begin (Keyword Detection) related
	function! InsertTabWrapper(direction)
		let col=col('.') - 1
		if !col || getline('.')[col - 1] !~ '\k'
			return "\<tab>"
		elseif "backward" == a:direction
			return "\<c-p>"
		else
			return "\<c-n>"
		endif
	endfunction
	inoremap <Tab> <C-R>=InsertTabWrapper("backward")<CR>
	inoremap <S-Tab> <C-R>=InsertTabWrapper("forward")<CR>
	"End (Keyword Detection) related

	"Sort by text width
	function! SortLines() range
		 execute a:firstline . "," . a:lastline . 's/^\(.*\)$/\=strdisplaywidth( submatch(0) ) . " " . submatch(0)/'
		 execute a:firstline . "," . a:lastline . 'sort n'
		 execute a:firstline . "," . a:lastline . 's/^\d\+\s//'
	endfunction

	filetype plugin on "detect filetype
	filetype indent on "indent based on type

	retab "Change all the existing tab characters to match the current tab settings

	"Abbreviations
	iabbrev ZA LIST=("${(f)$(command)}")<ESC>
	iabbrev ZF for ((X=0;X<LIMIT;X++));do<CR>done<ESC>
	iabbrev ZT [[ ${VAR} IS COND ]] && DO_THIS \|\| DO_THAT <ESC>
	iabbrev ZI if [[ ${VAR} IS COND ]];then<CR>else<CR>fi<CR><ESC>
	iabbrev ZC case ${VAR} in<CR>pattern) action;;<CR>esac<CR><ESC>
	iabbrev ZD set -xv<CR>set +xv;read<ESC>
	iabbrev ZV for L in ${LIST};do<CR>printf "%s\n" ${L}<CR>done<ESC>
	iabbrev ZKV for K in ${(k)X};do<CR>printf "KEY:%s VAL:%s\n" ${K} ${X[${K}]}<CR>done<ESC>
	iabbrev ZDB [[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"<ESC>
	iabbrev MW $(msg_warn <ESC>
	iabbrev ME $(msg_err <ESC>

	"function key mappings
	nnoremap <F1> :set number!<CR>
	nnoremap <F2> :set invpaste paste?<CR>
	nnoremap <F3> :echom 'Current file:' expand('%:p')<CR>
	nnoremap <F7> gg=G<C-o><C-o>

	nm <silent> <F4> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
    \ . '> trans<' . synIDattr(synID(line("."),col("."),0),"name")
    \ . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
    \ . ">"<CR>

	"example of mapping with input - could be used to prompt before executing a mapping
	nnoremap <expr> <c-t> "oHello, " . input("Please give your name: ") . ". You have a very nice name.\<ESC>"

	"activate Ansi plugin
	nnoremap <c-a> :AnsiEsc<CR>:echom "ANSI mode"<CR>

	"enclose bare vars with braces in zsh
	nnoremap <c-b> :1,$s/\$\@<=[~A-Z_0-9:a-z@#?]\+/{&}/g:echom "Wrapped vars in braces"<CR>

	"delimit all words
	nnoremap <silent> <c-d> <Esc>0A<Esc>0y$$<Esc>0:1,$s/ /\|/g<CR>:echom "Delimited all words"<CR>

	"add app shebangs
	nnoremap <c-e> ggi#!/usr/bin/zsh<CR> <ESC>:echom "zsh app"<CR>
	nnoremap <c-p> ggi#!/usr/bin/env python3<CR> <ESC>:echom "python app"<CR>
	nnoremap <c-l> ggi#!/usr/bin/env perl<CR> <ESC>:echom "perl app"<CR>

	"find left anchored
	nnoremap <c-f> :/^

	"marked delete/yank
	nnoremap <c-x> :'a,'bd <CR>:echom "Deleted between a,b markers"<CR>
	nnoremap <c-c> :'a,'by <CR>:echom "Yanked between a,b markers"<CR>

	"marked copy/move - TODO: interfering with line number goto
	"nnoremap <c-m> :'a,'b mo . <CR>
	"nnoremap <c-n> :'a,'b co . <CR>

	"marked enter cmd
	nnoremap <c-l> :'a,'b

	"indent/outdent
	nnoremap <c-i> :'a,'b> <CR>:echom "Indent"<CR>
	nnoremap <c-o> :'a,'b< <CR>:echom "Outdent"<CR>

	"marked sort
	nnoremap <c-s> :'a,'bsort <CR>:echom "Sorted between a,b markers"<CR>

	"marked comment/uncomment
	nnoremap <c-u> :'a,'bs/^/#/g <CR>:echom "Commented"<CR>
	nnoremap <c-y> :'a,'bs/^#//g <CR>:echom "Unommented"<CR>

	"wrap long lines
	nnoremap <c-w> <esc>gggqG:echom "Wrapped long lines"<CR>
	
	set autoindent "automatic code indent
	set backspace=2 "backspace del all
	set cindent "C indenting function
	set encoding=utf-8
	set fileencodings^=utf-8
	set history=500
	set incsearch "show search in real time as it is typed
	set laststatus=2 "always show status line
	set lazyredraw "no updates to screen during script processing
	set lcs=tab:>.,eol:$ "show non printing chars
	set modeline "process embedded modelines
	set nocompatible "We're running Vim, not Vi!
	set noexpandtab "use real tabs
	set nowrap "do not wrap lines
	set nu "show numbers
	set shiftwidth=3 "When auto-indenting, indent by this much.
	set showcmd "show typed commands
	set showmode
	set showtabline=2 "when tab-page labels are shown
	set smarttab "tries to guess correct tabbing strategy
	set softtabstop=3 "soft tabs
	set statusline=%<%f\ (%{&encoding})\ %h%m%r%=%-14.(%l,%c%V%)\ %P
	set syntax=on
	set t_Co=256 "color numbers
	set tabstop=3 "Force tabs to be displayed/expanded to 3 spaces (instead of default 8).
	set tags=~/.vim/mytags/framework
	set textwidth=120 "text width
	set undodir=~/.vim/undo
	set undofile 
	set viminfo='500,f1,<500,:100,/100 
	set whichwrap+=<,>,[,] "where to wrap long lines
	set wmh=0 "minimum window height
	set background=dark
	set laststatus=2
	set t_Co=256
	colorscheme gruvbox
	if !has('nvim')
		set termencoding=utf-8
		"colorscheme pencil
		let g:pencil_terminal_italics = 1
		let g:pencil_neutral_code_bg = 1
	endif
endif
