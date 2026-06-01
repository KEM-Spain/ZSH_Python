# LIB Dependencies
_DEPS+=(MSG.zsh UTILS.zsh)

# LIB Declarations
typeset -a _EXIT_CALLBACKS=()
typeset -a _PIDS=()

# LIB Vars
_PRE_EXIT_RAN=false
_EXIT_MSGS=''

# LIB Functions
exit_leave () {
	local OPT=''
	local RET=''

	if [[ -n ${1} ]];then
		RET=$( echo "${1}" | sed 's/^[-+]*[0-9]*//g' )
		[[ -z ${RET} ]] && set_exit_value ${1} && shift
	fi

	_EXIT_MSGS=(${@})

	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if [[ ${_DEBUG} -ge ${_LOW_DBG} ]];then
		dbg "${RED_FG}${0}${RESET}: CALLER:${functrace[1]}"
		dbg "${RED_FG}${0}${RESET}: #_MSGS:${#_MSGS}"
		dbg "${RED_FG}${0}${RESET}: RET_9:${RET_9}"
		dbg_msg | mypager -n wait
	fi

	[[ ${functrace[1]} =~ 'usage' && -z ${MSGS} ]] && set_exit_value 1

	exit_pre_exit

	[[ ${_SMCUP} == 'true' ]] && do_rmcup # Restore if needed

	if [[ -n ${_EXIT_MSGS} ]];then
		echo "\n${_EXIT_MSGS}" >&2 # Display any exit messages
	fi

	exit ${_EXIT_VALUE}
}

exit_pre_exit () {
	local -a SCRUB=()
	local -a USER_PIDS=()
	local C F P

	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${_PRE_EXIT_RAN} == 'true' ]] && return
	
	_PRE_EXIT_RAN=true

	if [[ -n ${_EXIT_CALLBACKS} ]];then
		[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && echo "${RED_FG}${0}${RESET}: EXECUTING CALLBACKS:${_EXIT_CALLBACKS}"
		for C in ${_EXIT_CALLBACKS};do
			${C}
		done
	fi

	if [[ ${_EXIT_SCRUB} == 'true' ]];then
		_PIDS=("${(f)$(get_user_pids)}")
		scrub_tmp
	fi

	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && echo "${RED_FG}${0}${RESET}: CALLER:${functrace[1]}, #_EXIT_MSGS:${#_EXIT_MSGS}"

	if [[ ${XDG_SESSION_TYPE:l} == 'x11' ]];then
		xset r on # Reset key repeat
		eval "xset ${_XSET_DEFAULT_RATE}" # Reset key rate
		[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && echo "${0}: reset key rate:${_XSET_DEFAULT_RATE}"
	fi

	kbd_activate
	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && echo "${0}: activated keyboard"

	[[ ${$(tabs -d | grep --color=never -o "tabs 8")} != 'tabs 8' ]] && tabs 8
	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && echo "${0}: reset tabstops"

	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && echo "${0}: _EXIT_VALUE:${_EXIT_VALUE}"
}

exit_request () {
	local MSG="Quit application (y/n)"
	local X=${1}
	local Y=${2}
	local W=${3}
	local H=3
	local -A COORDS
	local FRAME_WIDTH=6
	local TAG=EXR_BOX

	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if [[ ${#} -eq 0 ]];then
		msg_box -T ${TAG} -jc -O ${RED_FG} -p ${MSG}
	else
		COORDS=(X ${X:=null} Y ${Y:=null} W ${W:=null} H ${H})
		[[ ${COORDS[W]} == 'null' ]] && COORDS[W]=$(( ${#MSG} + ${FRAME_WIDTH} )) && COORDS[Y]=$(( COORDS[Y] - ${#MSG} / 2 ))
		box_coords_set ${TAG} X $(( COORDS[X] - 1 )) Y $(( COORDS[Y] - FRAME_WIDTH / 2 )) W $(( COORDS[W] + FRAME_WIDTH / 2 )) H ${COORDS[H]} # Compensate for frame dimensions
		msg_box -T ${TAG} -jc -O ${RED_FG} -p -x ${COORDS[X]} -y ${COORDS[Y]} -w ${COORDS[W]} -h ${COORDS[H]} ${MSG}
	fi

	if [[ ${_MSG_KEY} == 'y' ]];then
		if [[ ${_FUNC_TRAP} == 'true' ]];then
			exit_pre_exit
			exit 0
		else
			exit_leave
		fi
	else
		msg_box_clear ${TAG} 
	fi
}

exit_sigexit () {
	local SIG=${1}
	local SIGNAME=$(kill -l ${SIG})
	local -A SIGNAMES=(\
		1 "Terminal vanished" 2 "Control-C" 3 "Core Dump" 4 "Illegal Instruction" 5 "Conditional Exit (DEBUG)" 6 "Emergency Abort"\
		7 "Memory Error" 8 "FLoating Point Exception" 9 "Termination Called from kill"
	)

	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	# Traps arrive here
	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && echo "\n${RED_FG}${0}${RESET}: Exited via interrupt: ${SIG} (${SIGNAME}) ${SIGNAMES[${SIG}]}" # Announce the interrupt
	exit_pre_exit # Pre-exit housekeeping

	exit ${SIG} # Leave the app
}

get_exit_value () {
	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo ${_EXIT_VALUE}
}

set_exit_callback () {
	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_EXIT_CALLBACKS+=${1}

	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "\n${RED_FG}${0}${RESET}: REGISTERED CALLBACK:${1}"
}

set_exit_value () {
	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_EXIT_VALUE=${1}
}

get_user_pids () {
	local PS=("${(f)$(ps --headers -aux | grep --color=never -i ${USER} | grep -v ${0:t} | grep -v grep | tr -s '[:space:]')}")
	local F2
	local P

	for P in ${PS};do
		F2=$(cut -d' ' -f2 <<<${P})
		echo ${F2}
	done
}

is_active_pid () {
	local FN=${1}
	local P

	for P in ${_PIDS};do
		[[ ${FN} =~ ${P} ]] && return 0
	done
	return 1
}

scrub_tmp () {
	local -a MARKERS=(debug state tag)
	local -a FLIST=()
	local M F

	FLIST=("${(f)$(
	for M in ${MARKERS};do
		ls /tmp/*${M}*
	done 2>/dev/null
	)}")

	for F in ${FLIST};do
		if ! is_active_pid ${F};then
			/bin/rm -f ${F}
		fi
	done
}

