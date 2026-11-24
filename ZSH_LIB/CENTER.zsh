# LIB Dependencies
_DEPS+=(MSG.zsh TPUT.zsh VALIDATE.zsh UTILS.zsh)

# LIB Vars
_MOD="[${0:t}]"

# Internal Error Reporting Helper
_report_error () {
	local err_msg="${1}"
	print -u2 "\n${_MOD} Error in ${functrace[2]:-${functrace[1]}} (${funcfiletrace[2]:-${funcfiletrace[1]}}): ${RED_FG}${err_msg}${RESET}"
}

# LIB Functions
get_relative_center () {
  local -A RGN_COORDS=()
  local -i HEIGHT=0
  local -i WIDTH=0
  local -i X_OFF=0
  local -i Y_OFF=0
  local -i RX=0
  local -i RY=0
  local -i RH=0
  local -i RW=0
  local -F3 EXACT_X=0
  local -F3 EXACT_Y=0
  local -i X=0
  local -i Y=0

  RGN_COORDS=(${(z)1})
  HEIGHT="${2}"
  WIDTH="${3}"
  X_OFF="${4:-0}"
  Y_OFF="${5:-0}"
  RX=${RGN_COORDS[X]}
  RY=${RGN_COORDS[Y]}
  RH=${RGN_COORDS[H]}
  RW=${RGN_COORDS[W]}

  [[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

  EXACT_X=$(( ${RX} + ((${RH} - ${HEIGHT}) / 2.0) + ${X_OFF} ))
  X=$(( ${EXACT_X} >= 0 ? ${EXACT_X} + 0.5 : ${EXACT_X} - 0.5 ))

  EXACT_Y=$(( ${RY} + ((${RW} - ${WIDTH}) / 2.0) + ${Y_OFF} ))
  Y=$(( ${EXACT_Y} >= 0 ? ${EXACT_Y} + 0.5 : ${EXACT_Y} - 0.5 ))

  echo "X ${X} Y ${Y} H ${HEIGHT} W ${WIDTH}"
}

get_relative_x () {
  local -A RGN_COORDS=()
  local HEIGHT=""
  local -i X_OFF=0
  local -i RX=0
  local -i RY=0
  local -i RH=0
  local -i RW=0
  local -F3 EXACT_X=0
  local -i X=0

  RGN_COORDS=(${(z)1})
  HEIGHT="${2}"
  X_OFF="${3:-0}"
  RX=${RGN_COORDS[X]}
  RY=${RGN_COORDS[Y]}
  RH=${RGN_COORDS[H]}
  RW=${RGN_COORDS[W]}

  [[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

  EXACT_X=$(( ${RX} + ((${RH} - ${HEIGHT}) / 2.0) + ${X_OFF} ))
  X=$(( ${EXACT_X} >= 0 ? ${EXACT_X} + 0.5 : ${EXACT_X} - 0.5 ))

  echo ${X}
}

get_relative_y () {
  local -A RGN_COORDS=()
  local WIDTH=""
  local -i Y_OFF=0
  local -i RX=0
  local -i RY=0
  local -i RH=0
  local -i RW=0
  local -F3 EXACT_Y=0
  local -i Y=0

  RGN_COORDS=(${(z)1})
  WIDTH="${2}"
  Y_OFF="${3:-0}"
  RX=${RGN_COORDS[X]}
  RY=${RGN_COORDS[Y]}
  RH=${RGN_COORDS[H]}
  RW=${RGN_COORDS[W]}

  [[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

  EXACT_Y=$(( ${RY} + ((${RW} - ${WIDTH}) / 2.0) + ${Y_OFF} ))
  Y=$(( ${EXACT_Y} >= 0 ? ${EXACT_Y} + 0.5 : ${EXACT_Y} - 0.5 ))

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
  local -i HEIGHT=0
  local -i X_OFF=0
  local -i RGN=0
  local -F3 EXACT_X=0
  local -i X=0

  HEIGHT="${1}"
  X_OFF="${2:-0}"
  RGN=$(tput lines)

  [[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

  EXACT_X=$(( ((${RGN} - ${HEIGHT}) / 2.0) + ${X_OFF} ))
  X=$(( ${EXACT_X} >= 0 ? ${EXACT_X} + 0.5 : ${EXACT_X} - 0.5 ))

  echo ${X}
}

get_horz_center () {
  local -i WIDTH=0
  local -i Y_OFF=0
  local -i RGN=0
  local -F3 EXACT_Y=0
  local -i Y=0

  WIDTH="${1}"
  Y_OFF="${2:-0}"
  RGN=$(tput cols)

  [[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

  EXACT_Y=$(( ((${RGN} - ${WIDTH}) / 2.0) + ${Y_OFF} ))
  Y=$(( ${EXACT_Y} >= 0 ? ${EXACT_Y} + 0.5 : ${EXACT_Y} - 0.5 ))

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
				else
					[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: COORDS are balanced"
				fi;;
			h) if ! validate_is_number "${HEIGHT}";then
					_report_error "${functrace[1]} HEIGHT is not numeric" >&2 && return 1
				elif [[ "${HEIGHT}" -gt $(tput lines) ]];then
					_report_error "${functrace[1]} HEIGHT exceeds maximum $(tput lines)" >&2 && return 1
				elif [[ "${HEIGHT}" -lt 1 ]];then
					_report_error "${functrace[1]} HEIGHT must be a positive integer > 0" >&2 && return 1
				else
					[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: HEIGHT:${HEIGHT}"
				fi;;
			w) if ! validate_is_number "${WIDTH}";then
					_report_error "${functrace[1]} WIDTH is not numeric" >&2 && return 1
				elif [[ "${WIDTH}" -gt $(tput cols) ]];then
					_report_error "${functrace[1]} WIDTH exceeds maximum $(tput cols)" >&2 && return 1
				elif [[ "${WIDTH}" -lt 1 ]];then
					_report_error "${functrace[1]} WIDTH must be a positive integer > 0" >&2 && return 1
				else
					[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: WIDTH:${WIDTH}"
				fi;;
			x) if ! validate_is_number "${X_OFF}";then
					_report_error "${functrace[1]} X_OFF is not numeric" >&2 && return 1
				else
					[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: X OFFSET:${X_OFF}"
				fi;;
			y) if ! validate_is_number "${Y_OFF}";then
					_report_error "${functrace[1]} Y_OFF is not numeric" >&2 && return 1
				else
					[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Y OFFSET:${Y_OFF}"
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
				X) print -u2 "${0:t}: REL_X option -X requires: -c <COORD_ARGS> -h <N> [-x <N>]";;
				Y) print -u2 "${0:t}: REL_Y option -Y requires: -c <COORD_ARGS> -w <N> [-y <N>]";;
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
		REL_X) get_relative_x "${COORD_ARGS}" "${_HEIGHT}" "${_X_OFF}";;
		REL_Y) get_relative_y "${COORD_ARGS}" "${_WIDTH}" "${_Y_OFF}";;
	esac
}
