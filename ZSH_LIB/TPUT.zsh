# LIB Vars
_CURSOR=''
_TERM=xterm

# LIB Functions
cursor_home () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	tput -T ${_TERM} cup $(tput lines) 0
}

cursor_off () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	tput -T ${_TERM} civis >&2 # Hide cursor
	_CURSOR=off
}

cursor_on () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	tput -T ${_TERM} cnorm >&2 # Normal cursor
	_CURSOR=on
}

cursor_restore () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	tput -T ${_TERM} rc # Save cursor
}

cursor_row () {
	local ROW

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	echo -ne "\033[6n" > /dev/tty # Voodoo to grab row
	read -t1 -s -d'R' ROW < /dev/tty # Parse usable bit

	ROW=$(cut -d';' -f1 <<<${ROW} | tr -dc '0-9') # Split and strip non digits (escape seq etc.)
	((ROW--))

	echo ${ROW}
}

cursor_save () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	tput -T ${_TERM} sc # Save cursor
}

do_rmcup () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	if [[ ${_SMCUP} == 'true' ]];then
		tput -T ${_TERM} rmcup
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "Executed rmcup"
		_SMCUP=false
	fi
}

do_rmso () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	tput -T ${_TERM} rmso
}

do_smso () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"
	tput -T ${_TERM} smso
}

do_smcup () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	if [[ ${_SMCUP} == 'false' ]];then
		tput -T ${_TERM} smcup 
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "Executed smcup"
		_SMCUP=true
	fi
}

tcup () {
	local X=${1:=0}
	local Y=${2:=0}
	local CAUGHT_BAD_X=false
	local CAUGHT_BAD_Y=false

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	[[ ${X} -lt 0 ]] && X=1 && CAUGHT_BAD_X=true
	[[ ${Y} -lt 0 ]] && Y=1 && CAUGHT_BAD_Y=true

	if [[ ${_DEBUG} -ge ${_HIGH_DBG} ]];then
		[[ ${CAUGHT_BAD_X} == 'true' ]] && dbg "${functrace[1]} called ${0}: ARGC:${#@} ${RED_FG}CAUGHT BAD X COORD${RESET} Set to 1"
		[[ ${CAUGHT_BAD_Y} == 'true' ]] && dbg "${functrace[1]} called ${0}: ARGC:${#@} ${RED_FG}CAUGHT BAD Y COORD${RESET} Set to 1"
	fi

	tput -T ${_TERM} cup ${X} ${Y}
}

