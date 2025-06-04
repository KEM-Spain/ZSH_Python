# LIB Dependencies
_DEPS_+="DBG.zsh"

# LIB Vars
_CURSOR=''
_SMCUP=''
_TERM=xterm

# LIB Functions
cursor_home () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	tput -T ${_TERM} cup $(tput lines) 0
}

cursor_off () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	tput -T ${_TERM} civis >&2 # Hide cursor
	_CURSOR=off
}

cursor_on () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	tput -T ${_TERM} cnorm >&2 # Normal cursor
	_CURSOR=on
}

cursor_restore () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	tput -T ${_TERM} rc # Save cursor
}

cursor_row () {
	local LINE

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo -ne "\033[6n" > /dev/tty
	read -t 1 -s -d 'R' LINE < /dev/tty
	LINE="${LINE##*\[}"
	LINE="${LINE%;*}"
	echo $((LINE - 2))
}

cursor_save () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	tput -T ${_TERM} sc # Save cursor
}

do_rmcup () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${_SMCUP} == 'false' ]] && return
	tput -T ${_TERM} rmcup
	_SMCUP=false
}

do_rmso () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	tput -T ${_TERM} rmso
}

do_smso () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	tput -T ${_TERM} smso
}

do_smcup () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${_SMCUP} == 'true' ]] && return
	tput -T ${_TERM} smcup
	_SMCUP=true
}

tcup () {
	local X=${1:=0}
	local Y=${2:=0}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${X} -lt 0 ]] && X=1 && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ${RED_FG}CAUGHT BAD X COORD${RESET} Set to 1"
	[[ ${Y} -lt 0 ]] && Y=1 && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ${RED_FG}CAUGHT BAD Y COORD${RESET} Set to 1"

	tput -T ${_TERM} cup ${X} ${Y}
}

