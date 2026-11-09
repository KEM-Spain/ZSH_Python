# LIB Dependencies
_DEPS+=(MSG.zsh TPUT.zsh VALIDATE.zsh UTILS.zsh)

# LIB Vars
_MOD="[${0:t}]"

# Internal Error Reporting Helper
_report_error () {
	local err_msg="${1}"
	print -u2 "\n$${_MOD} Error in ${functrace[2]:-${functrace[1]}} (${funcfiletrace[2]:-${funcfiletrace[1]}}): ${RED_FG}${err_msg}${RESET}"
}

# LIB Functions
get_relative_center () {
	local -A RGN_COORDS=(${(z)1}) # Coords of region to place object
	local HEIGHT="${2}" # Height of object
	local WIDTH="${3}" # Width of object
	local X_OFF="${4:=0}" # X offset
	local Y_OFF="${5:=0}" # Y offset
	local RX=${RGN_COORDS[X]}
	local RY=${RGN_COORDS[Y]}
	local RH=${RGN_COORDS[H]}
	local RW=${RGN_COORDS[W]}
	local -F3 RGN_CTR=0 # Region center
	local -F3 OBJ_CTR=0 # Object center
	local -F3 REM=0 # Remainder
	local -i X=0
	local -i Y=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	RGN_CTR=$(( (RH / 2) + RX ))
	REM=$(( RGN_CTR % 2 ))
	[[ ${REM} -ge .5 ]] && (( RGN_CTR++ ))

	OBJ_CTR=$(( (HEIGHT / 2) ))
	REM=$(( OBJ_CTR % 2 ))
	[[ ${REM} -ge .5 ]] && (( OBJ_CTR++ ))

	X=$(( RGN_CTR - OBJ_CTR - 1 ))

	RGN_CTR=$(( (RW / 2) + RY ))
	REM=$(( RGN_CTR % 2 ))
	[[ ${REM} -ge .5 ]] && (( RGN_CTR++ ))

	OBJ_CTR=$(( (WIDTH / 2) ))
	REM=$(( OBJ_CTR % 2 ))
	[[ ${REM} -ge .5 ]] && (( OBJ_CTR++ ))

	Y=$(( RGN_CTR - OBJ_CTR - 1 ))

	[[ ${X_OFF} -ne 0 ]] && X=$(( X + X_OFF ))
	[[ ${Y_OFF} -ne 0 ]] && Y=$(( Y + Y_OFF ))

	echo "X ${X} Y ${Y} H ${HEIGHT} W ${WIDTH}"
}

get_relative_x () {
	local -A RGN_COORDS=(${(z)1}) # Coords of region to place object
	local HEIGHT="${2}" # Height of object
	local X_OFF="${3:=0}" # X offset
	local Y_OFF="${4:=0}" # Y offset
	local RX=${RGN_COORDS[X]}
	local RY=${RGN_COORDS[Y]}
	local RH=${RGN_COORDS[H]}
	local RW=${RGN_COORDS[W]}
	local -F3 RGN_CTR=0 # Region center
	local -F3 OBJ_CTR=0 # Object center
	local -F3 REM=0 # Remainder
	local -i X=0
	local -i Y=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	RGN_CTR=$(( (RH / 2) + RX ))
	REM=$(( RGN_CTR % 2 ))
	[[ ${REM} -ge .5 ]] && (( RGN_CTR++ ))

	OBJ_CTR=$(( (HEIGHT / 2) ))
	REM=$(( OBJ_CTR % 2 ))
	[[ ${REM} -ge .5 ]] && (( OBJ_CTR++ ))

	X=$(( RGN_CTR - OBJ_CTR - 1 ))

	[[ ${X_OFF} -ne 0 ]] && X=$(( X + X_OFF ))

	echo ${X}
}

get_relative_y () {
	local -A RGN_COORDS=(${(z)1}) # Coords of region to place object
	local WIDTH="${2}" # Width of object
	local X_OFF="${3:=0}" # X offset
	local Y_OFF="${4:=0}" # Y offset
	local RX=${RGN_COORDS[X]}
	local RY=${RGN_COORDS[Y]}
	local RH=${RGN_COORDS[H]}
	local RW=${RGN_COORDS[W]}
	local -F3 RGN_CTR=0 # Region center
	local -F3 OBJ_CTR=0 # Object center
	local -F3 REM=0 # Remainder
	local -i X=0
	local -i Y=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	RGN_CTR=$(( (RW / 2) + RY ))
	REM=$(( RGN_CTR % 2 ))
	[[ ${REM} -ge .5 ]] && (( RGN_CTR++ ))

	OBJ_CTR=$(( (WIDTH / 2) ))
	REM=$(( OBJ_CTR % 2 ))
	[[ ${REM} -ge .5 ]] && (( OBJ_CTR++ ))

	Y=$(( RGN_CTR - OBJ_CTR - 1 ))

	[[ ${Y_OFF} -ne 0 ]] && Y=$(( Y + Y_OFF ))

	echo ${Y}
}

get_box_center () {
	local HEIGHT=${1}
	local WIDTH=${2}
	local X_OFF=${3:=0}
	local Y_OFF=${4:=0}
	local -i X=0
	local -i Y=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	X=$(get_vert_center ${HEIGHT})
	Y=$(get_horz_center ${WIDTH})
	
	[[ ${X_OFF} -ne 0 ]] && X=$(( X + X_OFF ))
	[[ ${Y_OFF} -ne 0 ]] && Y=$(( Y + Y_OFF ))

	echo "X ${X} Y ${Y} H ${HEIGHT} W ${WIDTH}"
}

get_vert_center () {
	local HEIGHT=${1}
	local RGN=$(tput lines)
	local -F3 HEIGHT_CENTER=$(( HEIGHT / 2 ))
	local -F3 RGN_CENTER=$(( RGN / 2 ))
	local -F3 REM=0
	local -i X=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	REM=$(( HEIGHT_CENTER % 2 ))
	[[ ${REM} -ge .5 ]] && (( HEIGHT_CENTER++ ))

	REM=$(( RGN_CENTER % 2 ))
	[[ ${REM} -ge .5 ]] && (( RGN_CENTER++ ))

	if [[ ${RGN_CENTER} -eq ${HEIGHT_CENTER} ]];then
		X=${HEIGHT_CENTER}
	else
		X=$(( RGN_CENTER - HEIGHT_CENTER - 1 ))
	fi

	echo ${X}
}

get_horz_center () {
	local WIDTH=${1}
	local RGN=$(tput cols)
	local -F3 WIDTH_CENTER=$(( WIDTH / 2 ))
	local -F3 RGN_CENTER=$(( RGN / 2 ))
	local -F3 REM=0
	local -i Y=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	REM=$(( WIDTH_CENTER % 2 ))
	[[ ${REM} -ge .5 ]] && (( WIDTH_CENTER++ ))

	REM=$(( RGN_CENTER % 2 ))
	[[ ${REM} -ge .5 ]] && (( RGN_CENTER++ ))

	if [[ ${RGN_CENTER} -eq ${WIDTH_CENTER} ]];then
		Y=${WIDTH_CENTER}
	else
		Y=$(( RGN_CENTER - WIDTH_CENTER - 1 ))
	fi

	echo ${Y}
}

validate_args () {
	local JOB="${1}"
	local HEIGHT="${2}"
	local WIDTH="${3}"
	local X_OFF="${4}"
	local Y_OFF="${5}"
	local COORD_ARGS="${6}"

	case ${JOB} in
		BOX)	[[ -z "${HEIGHT}" ]] && { _report_error "${JOB}: HEIGHT parameter is missing" >&2 && return 1 }
					[[ -z "${WIDTH}" ]] && { _report_error "${JOB}: WIDTH parameter is missing" >&2 && return 1 }
					[[ "${HEIGHT}" -lt 1 ]] && { _report_error "${JOB}: HEIGHT must be > 0" >&2 && return 1 }
					[[ "${WIDTH}" -lt 1 ]] && { _report_error "${JOB}: WIDTH must be > 0" >&2 && return 1 }
					validate_opts "w h x y" "${HEIGHT}" "${WIDTH}" "${X_OFF}" "${Y_OFF}" "${COORD_ARGS}"
					return ${?}
					;;
		VERT) [[ -z "${HEIGHT}" ]] && { _report_error "${JOB}: HEIGHT parameter is missing" >&2 && return 1 }
					[[ "${HEIGHT}" -lt 1 ]] && { _report_error "${JOB}: HEIGHT must be > 0" >&2 && return 1 }
					validate_opts "h" "${HEIGHT}" "${WIDTH}" "${X_OFF}" "${Y_OFF}" "${COORD_ARGS}"
					return ${?}
					;;
		HORZ) [[ -z "${WIDTH}" ]] && { _report_error "${JOB}: WIDTH parameter is missing" >&2 && return 1 }
					[[ "${WIDTH}" -lt 1 ]] && { _report_error "${JOB}: WIDTH must be > 0" >&2 && return 1 }
					validate_opts "w" "${HEIGHT}" "${WIDTH}" "${X_OFF}" "${Y_OFF}" "${COORD_ARGS}"
					return ${?}
					;;
		REL_C)	[[ -z ${COORD_ARGS} ]] && { _report_error "${JOB}: COORD_ARGS are not populated" >&2 && return 1 }
						[[ -z "${HEIGHT}" ]] && { _report_error "${JOB}: HEIGHT parameter is missing" >&2 && return 1 }
						[[ -z "${WIDTH}" ]] && { _report_error "${JOB}: WIDTH parameter is missing" >&2 && return 1 }
						[[ "${HEIGHT}" -lt 1 ]] && { _report_error "${JOB}: HEIGHT must be > 0" >&2 && return 1 }
						[[ "${WIDTH}" -lt 1 ]] && { _report_error "${JOB}: WIDTH must be > 0" >&2 && return 1 }
						validate_opts "c h w x y" "${HEIGHT}" "${WIDTH}" "${X_OFF}" "${Y_OFF}" "${COORD_ARGS}"
						return ${?}
						;;
		REL_X)	[[ -z ${COORD_ARGS} ]] && { _report_error "${JOB}: COORD_ARGS are not populated" >&2 && return 1 }
						[[ -z "${HEIGHT}" ]] && { _report_error "${JOB}: HEIGHT parameter is missing" >&2 && return 1 }
						[[ "${HEIGHT}" -lt 1 ]] && { _report_error "${JOB}: HEIGHT must be > 0" >&2 && return 1 }
						validate_opts "c h x" "${HEIGHT}" "${WIDTH}" "${X_OFF}" "${Y_OFF}" "${COORD_ARGS}"
						return ${?}
						;;
		REL_Y) [[ -z ${COORD_ARGS} ]] && { _report_error "${JOB}: COORD_ARGS are not populated" >&2 && return 1 }
						[[ -z "${WIDTH}" ]] && { _report_error "${JOB}: WIDTH parameter is missing" >&2 && return 1 }
						[[ "${WIDTH}" -lt 1 ]] && { _report_error "${JOB}: WIDTH must be > 0" >&2 && return 1 }
						validate_opts "c w y" "${HEIGHT}" "${WIDTH}" "${X_OFF}" "${Y_OFF}" "${COORD_ARGS}"
						return ${?}
						;;
	esac
	return 0
}

validate_opts () {
	local OPTS=(${(z)1})
	local HEIGHT="${2}"
	local WIDTH="${3}"
	local X_OFF="${4}"
	local Y_OFF="${5}"
	local COORD_ARGS="${6}"
	local O

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	for O in ${OPTS};do
		case ${O} in
			c) if [[ $(( ${#${(z)COORD_ARGS}} % 2 )) -ne 0 ]];then
					_report_error "${functrace[1]} COORD_ARGS:${COORD_ARGS} are unbalanced" >&2 && return 1
				fi;;
			h) if ! validate_is_number "${HEIGHT}";then
					_report_error "${functrace[1]} HEIGHT is not numeric" >&2 && return 1
				elif [[ "${HEIGHT}" -gt $(tput lines) ]];then
					_report_error "${functrace[1]} HEIGHT exceeds maximum $(tput lines)" >&2 && return 1
				elif [[ "${HEIGHT}" -lt 1 ]];then
					_report_error "${functrace[1]} HEIGHT must be a positive integer > 0" >&2 && return 1
				fi;;
			w) if ! validate_is_number "${WIDTH}";then
					_report_error "${functrace[1]} WIDTH is not numeric" >&2 && return 1
				elif [[ "${WIDTH}" -gt $(tput cols) ]];then
					_report_error "${functrace[1]} WIDTH exceeds maximum $(tput cols)" >&2 && return 1
				elif [[ "${WIDTH}" -lt 1 ]];then
					_report_error "${functrace[1]} WIDTH must be a positive integer > 0" >&2 && return 1
				fi;;
			x) if ! validate_is_number "${X_OFF}";then
					_report_error "${functrace[1]} X_OFF is not numeric" >&2 && return 1
				fi;;
			y) if ! validate_is_number "${Y_OFF}";then
					_report_error "${functrace[1]} Y_OFF is not numeric" >&2 && return 1
				fi;;
		esac
	done

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: OPTS are valid"
	return 0
}

center () {
	#--Begin GetOpts--
	local -a OPTIONS
	local OPTION
	local OPTSTR=":DBHRVXYc:h:w:s:x:y:"
	local OPTIND=0

	local COORD_ARGS='' # COORDS array content
	local _HEIGHT=0     # HEIGHT of object to display
	local _WIDTH=0      # WIDTH of object to display, width of text to center, or the text itself
	local _X_OFF=0      # Optional Vertical offset from center
	local _Y_OFF=0      # Optional Horizontal offset from center
	local JOB=''
	local O

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	while getopts ${OPTSTR} OPTION;do
		case $OPTION in
		  D) dbg_set_level;;
		  B) JOB='BOX';;
		  H) JOB='HORZ';;
		  R) JOB='REL_C';;
		  V) JOB='VERT';;
		  X) JOB='REL_X';;
		  Y) JOB='REL_Y';;
		  c) COORD_ARGS=${OPTARG};;
		  h) _HEIGHT=${OPTARG};;
		  w) _WIDTH=${OPTARG};;
		  x) _X_OFF=${OPTARG};;
		  y) _Y_OFF=${OPTARG};;
		  :) print -u2 "\n${RED_FG}${_MOD} ${WHITE_FG}${functrace[1]}${RESET}: option: -${OPTARG} requires an argument"; exit_leave;;
		 \?) print -u2 "\n${RED_FG}${_MOD} ${WHITE_FG}${functrace[1]}${RESET}: unknown option -${OPTARG}"; exit_leave;;
		esac
		[[ ${OPTION} != 'D' ]] && OPTIONS+=${OPTION}
	done
	shift $((OPTIND -1))
	#--End GetOpts--
	
	# Hybrid Positional Fallback: If no JOB was specified via flags, check positional arguments
	if [[ -z "${JOB}" ]]; then
		if [[ ${#} -ge 2 ]]; then
			JOB='BOX'
			_HEIGHT="${1}"
			_WIDTH="${2}"
			[[ -n "${3}" ]] && _X_OFF="${3}"
			[[ -n "${4}" ]] && _Y_OFF="${4}"
			OPTIONS+=(h w)
		elif [[ ${#} -eq 1 ]]; then
			JOB='VERT'
			_HEIGHT="${1}"
			OPTIONS+=(h)
		fi
	fi

	[[ ${#OPTIONS} -eq 0 ]] && print -u2 "\n${RED_FG}${_MOD} Error in ${functrace[1]} (${funcfiletrace[1]}): Missing options${RESET}" >&2

	if ! validate_is_number ${_WIDTH};then # If WIDTH is a string of text; use its length
		_WIDTH=${#_WIDTH}
	fi

	if ! validate_args "${JOB}" "${_HEIGHT}" "${_WIDTH}" "${_X_OFF}" "${_Y_OFF}" "${COORD_ARGS}";then
		print -u2 "\n${RED_FG}${_MOD} Error in ${functrace[1]} (${funcfiletrace[1]}): Arguments for ${JOB} failed validation${RESET}" >&2
		for O in ${OPTIONS};do
			case ${O} in
				B) print -u2 "${0:t}: BOX option -B requires: -h <N> -w <N> [-x <N>] [-y <N>]";;
				H) print -u2 "${0:t}: HORZ option -H requires: -w <N>";;
				R) print -u2 "${0:t}: REL_C option -R requires: -c COORD_ARGS -h <N> -w <N> [-x <N>] [-y <N>]";;
				V) print -u2 "${0:t}: VERT option -V requires: -h <N>";;
				X) print -u2 "${0:t}: REL_X option -X requires: -c <COORD_ARGS> -h <N> [-x <N>] [-y <N>]";;
				Y) print -u2 "${0:t}: REL_Y option -Y requires: -c <COORD_ARGS> -w <N> [-x <N>] [-y <N>]";;
				c) print -u2 "${0:t}: COORD_ARGS option -c requires: -c <COORD ARRAY ARGS>: X <N> Y <N> H <N> W <N>";;
				h) print -u2 "${0:t}: HEIGHT option -h requires: -h <N>";;
				w) print -u2 "${0:t}: WIDTH option -w requires: -w <N>";;
				x) print -u2 "${0:t}: X_OFF option -x requires: -x <N>";;
				y) print -u2 "${0:t}: Y_OFF option -y requires: -y <N>";;
				*) print -u2 "${0:t}: Unknown option:${O}";;
			esac
		done
		return 1
	fi

	case ${JOB} in
		BOX) get_box_center "${_HEIGHT}" "${_WIDTH}" "${_X_OFF}" "${_Y_OFF}";;
		VERT) get_vert_center "${_HEIGHT}";;
		HORZ) get_horz_center "${_WIDTH}";;
		REL_C) get_relative_center "${COORD_ARGS}" "${_HEIGHT}" "${_WIDTH}" "${_X_OFF}" "${_Y_OFF}";;
		REL_X) get_relative_x "${COORD_ARGS}" "${_HEIGHT}" "${_X_OFF}" "${_Y_OFF}";;
		REL_Y) get_relative_y "${COORD_ARGS}" "${_WIDTH}" "${_X_OFF}" "${_Y_OFF}";;
	esac
}
