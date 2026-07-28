# LIB Dependencies
_DEPS+=(MSG.zsh TPUT.zsh VALIDATE.zsh UTILS.zsh)

# LIB Vars
_MOD="[${0:t}]"

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

	Y=$(( RGN_CTR - OBJ_CTR + 1 ))

	[[ ${X_OFF} -ne 0 ]] && X=$(( X + X_OFF ))
	[[ ${Y_OFF} -ne 0 ]] && Y=$(( Y + Y_OFF ))

	echo "X ${X} Y ${Y} H ${HEIGHT} W ${WIDTH}"
}

get_relative_x () {
	local -A RGN_COORDS=(${=1}) # Coords of region to place object
	local HEIGHT=${2} # Height of object
	local X_OFF=${3:=0}
	local RX=${RGN_COORDS[X]}
	local RY=${RGN_COORDS[Y]}
	local RH=${RGN_COORDS[H]}
	local RW=${RGN_COORDS[W]}
	local -F3 RGN_CTR=0
	local -F3 OBJ_CTR=0
	local -F3 REM=0
	local -i X=0

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
	local -A RGN_COORDS=(${=1}) # Coords of region to place object
	local WIDTH=${2} # Width of object
	local Y_OFF=${3:=0}
	local RX=${RGN_COORDS[X]}
	local RY=${RGN_COORDS[Y]}
	local RH=${RGN_COORDS[H]}
	local RW=${RGN_COORDS[W]}
	local -F3 RGN_CTR=0
	local -F3 OBJ_CTR=0
	local -F3 REM=0
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
	local HEIGHT=${1:=$(tput lines)}
	local RGN=$(tput lines)
	local -F3 HEIGHT_CENTER=$(( HEIGHT / 2 ))
	local -F3 RGN_CENTER=$(( RGN / 2 ))
	local -F3 REM=0
	local -i X=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	REM=$(( _HEIGHT_CENTER % 2 ))
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
	local WIDTH=${1:=$(tput cols)}
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
		Y=$(( RGN_CENTER - WIDTH_CENTER + 1 ))
	fi

	echo ${Y}
}

validate_args () {
	local JOB=${1}

	case ${JOB} in
		BOX)	[[ ! ${OPTIONS[(i)h]} -le ${#OPTIONS} ]] && { echo "\n${JOB}: _HEIGHT option is missing" >&2 && return 1 }
					[[ ! ${OPTIONS[(i)w]} -le ${#OPTIONS} ]] && { echo "\n${JOB}: _WIDTH option is missing" >&2 && return 1 }
					[[ ${_HEIGHT} -lt 1 ]] && { echo "\n${JOB}: _HEIGHT must be > 0" >&2 && return 1 }
					[[ ${_WIDTH} -lt 1 ]] && { echo "\n${JOB}: _WIDTH must be > 0" >&2 && return 1 }
					validate_opts w h x y
					return ${?}
					;;
		VERT) [[ ${OPTIONS[(i)h]} -le ${#OPTIONS} ]] && { validate_opts h && return ${?} };;
		HORZ) [[ ${OPTIONS[(i)w]} -le ${#OPTIONS} ]] && { validate_opts w && return ${?} };;
		REL_C)	[[ -z ${COORD_ARGS} ]] && { echo "${JOB}: COORD_ARGS are not populated" >&2 && return 1 }
						[[ ! ${OPTIONS[(i)h]} -le ${#OPTIONS} ]] && { echo "\n${JOB}: _HEIGHT option is missing" >&2 && return 1 }
						[[ ! ${OPTIONS[(i)w]} -le ${#OPTIONS} ]] && { echo "\n${JOB}: _WIDTH option is missing" >&2 && return 1 }
						[[ ${_HEIGHT} -lt 1 ]] && { echo "\n${JOB}: _HEIGHT must be > 0" >&2 && return 1 }
						[[ ${_WIDTH} -lt 1 ]] && { echo "\n${JOB}: _WIDTH must be > 0" >&2 && return 1 }
						validate_opts c h w x y
						return ${?}
						;;
		REL_X)	[[ -z ${COORD_ARGS} ]] && { echo "\n${JOB}: COORD_ARGS are not populated" >&2 && return 1 }
						[[ ! ${OPTIONS[(i)h]} -le ${#OPTIONS} ]] && { echo "\n${JOB}: _HEIGHT option is missing" >&2 && return 1 }
						[[ ${_HEIGHT} -lt 1 ]] && { echo "\n${JOB}: _HEIGHT must be > 0" >&2 && return 1 }
						validate_opts c h x
						return ${?}
						;;
		REL_Y) [[ -z ${COORD_ARGS} ]] && { echo "\n${JOB}: COORD_ARGS are not populated" >&2 && return 1 }
						[[ ! ${OPTIONS[(i)w]} -le ${#OPTIONS} ]] && { echo "\n${JOB}: _WIDTH option is missing" >&2 && return 1 }
						[[ ${_WIDTH} -lt 1 ]] && { echo "\n${JOB}: _WIDTH must be > 0" >&2 && return 1 }
						validate_opts c w y
						return ${?}
						;;
	esac
	return 0
}

validate_opts () {
	local OPTS=(${@})
	local O

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	for O in ${OPTS};do
		case ${O} in
			c) if [[ $(( ${#${(z)COORD_ARGS}} % 2 )) -ne 0 ]];then
					echo "${_MOD} ${functrace[1]} COORD_ARGS:${COORD_ARGS} are unbalanced" >&2 && return 1
				fi;;
			h) if ! validate_is_number ${_HEIGHT};then
					echo "${_MOD} ${functrace[1]} HEIGHT is not numeric" >&2 && return 1
				elif [[ ${_HEIGHT} -ge $(tput lines) ]];then
					echo "${_MOD} ${functrace[1]} HEIGHT exceeds maximum $(tput lines)" >&2 && return 1
				elif [[ ${_HEIGHT} -lt 1 ]];then
					echo "${_MOD} ${functrace[1]} HEIGHT must be a positive integer > 0" >&2 && return 1
				fi;;
			w) if ! validate_is_number ${_WIDTH};then
					echo "${_MOD} ${functrace[1]} WIDTH is not numeric" >&2 && return 1
				elif [[ ${_WIDTH} -ge $(tput cols) ]];then
					echo "${_MOD} ${functrace[1]} WIDTH exceeds maximum $(tput cols)" >&2 && return 1
				elif [[ ${_WIDTH} -lt 1 ]];then
					echo "${_MOD} ${functrace[1]} WIDTH must be a positive integer > 0" >&2 && return 1
				fi;;
			x) if ! validate_is_number ${_X_OFF};then
					echo "${_MOD} ${functrace[1]} X_OFF is not numeric" >&2 && return 1
				fi;;
			y) if ! validate_is_number ${_Y_OFF};then
					echo "${_MOD} ${functrace[1]} Y_OFF is not numeric" >&2 && return 1
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
	local BOX=false
	local HORZ=false
	local REL=false
	local REL_X=false
	local REL_Y=false
	local VERT=false

	local COORD_ARGS='' # COORDS array content
	local _HEIGHT=0  # HEIGHT of a box to display
	local _WIDTH=0  # WIDTH of a box to display, width of text to center, or the text itself
	local _X_OFF=0   # Optional Vertical offset from center
	local _Y_OFF=0   # Optional Horizontal offset from center
	local JOB=''

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
	
	if ! validate_is_number ${_WIDTH};then # Allow WIDTH to be passed as text
		_WIDTH=${#_WIDTH}
	fi

	if ! validate_args ${JOB};then
		echo "\nArguments for ${JOB} failed validation" >&2
		kill $$
	fi

	case ${JOB} in
		BOX) get_box_center ${_HEIGHT} ${_WIDTH} ${_X_OFF} ${_Y_OFF};;
		VERT) get_vert_center ${_HEIGHT};;
		HORZ) get_horz_center ${_WIDTH};;
		REL_C) get_relative_center ${COORD_ARGS} ${_HEIGHT} ${_WIDTH} ${_X_OFF} ${_Y_OFF};;
		REL_X) get_relative_x ${COORD_ARGS} ${_HEIGHT} ${_X_OFF};;
		REL_Y) get_relative_y ${COORD_ARGS} ${_WIDTH} ${_Y_OFF};;
	esac
}

