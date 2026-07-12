# LIB Dependencies
_DEPS+=(MSG.zsh TPUT.zsh VALIDATE.zsh UTILS.zsh)

# LIB Vars
_RCT=0
_MOD="[${0:t}]"

# TODO: modify return values to an associative format: X ${X} Y ${Y} H ${HEIGHT} W ${WIDTH}
# LIB Functions
get_relative_center () {
	local REL_COORDS=${1} # Coords of region to place object
	local HEIGHT=${2} # Height of object
	local WIDTH=${3} # Width of object
	local X_OFF=${4:=0}
	local Y_OFF=${5:=0}
	local RX=0
	local RY=0
	local RH=0
	local RW=0
	local X=0
	local Y=0

	IFS=':';read RX RY RH RW <<<${REL_COORDS}
	X=$(get_vert_center ${HEIGHT} ${RH})
	Y=$(get_horz_center ${WIDTH} ${RW})
	[[ ${X_OFF} -ne 0 ]] && X=$(( X + X_OFF ))
	[[ ${Y_OFF} -ne 0 ]] && Y=$(( Y + Y_OFF ))

	if [[ ${_DEBUG} -ge ${LOW_DBG} ]];then
		dbg "${0}: REL_COORDS - ${WHITE_FG}${REL_COORDS}${RESET}"
		dbg "${0}: OBJECT DIMS - HEIGHT:${WHITE_FG}${HEIGHT}${RESET} WIDTH:${WHITE_FG}${WIDTH}${RESET} X_OFF:${WHITE_FG}${X_OFF}${RESET} Y_OFF:${WHITE_FG}${Y_OFF}${RESET}"
		dbg "${0}: RELATIVE REL_COORDS: RX:${WHITE_FG}${RX}${RESET} RY:${WHITE_FG}${RY}${RESET} RH:${WHITE_FG}${RH}${RESET} RW:${WHITE_FG}${RW}${RESET}"
		dbg "${0}: HEIGHT:${WHITE_FG}${HEIGHT}${RESET} RH:${WHITE_FG}${RH}${RESET} V_CENTER:${WHITE_FG}${X}${RESET}"
		dbg "${0}: HEIGHT:${WHITE_FG}${HEIGHT}${RESET} RW:${WHITE_FG}${RW}${RESET} H_CENTER:${WHITE_FG}${Y}${RESET}"
		dbg "${0}: Applied offsets - V_CENTER:${WHITE_FG}${X}${RESET}  H_CENTER:${WHITE_FG}${Y}${RESET}"
		dbg "${0}: Return values - X:${WHITE_FG}${X}${RESET} Y:${WHITE_FG}${Y}${RESET} HEIGHT:${WHITE_FG}${HEIGHT}${RESET} WIDTH:${WHITE_FG}${WIDTH}${RESET}"
	fi

	echo "${X}:${Y}:${HEIGHT}:${WIDTH}"
}

get_box_center () {
	local HEIGHT=${1}
	local WIDTH=${2}
	local X_OFF=${3:=0}
	local Y_OFF=${4:=0}
	local X=0
	local Y=0

	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: OBJECT DIMS - HEIGHT:${WHITE_FG}${HEIGHT}${RESET} WIDTH:${WHITE_FG}${WIDTH}${RESET} X_OFF:${WHITE_FG}${X_OFF}${RESET} Y_OFF:${WHITE_FG}${Y_OFF}${RESET}"

	X=$(get_vert_center ${HEIGHT})
	Y=$(get_horz_center ${WIDTH})
	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: Centers - Vertical X:${WHITE_FG}${X}${RESET}, Horizontal Y:${WHITE_FG}${Y}${RESET}"

	[[ ${X_OFF} -ne 0 ]] && X=$(( X + X_OFF ))
	[[ ${Y_OFF} -ne 0 ]] && Y=$(( Y + Y_OFF ))
	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: Applied offsets - X:${WHITE_FG}${X}${RESET}  Y:${WHITE_FG}${Y}${RESET}"

	echo "${X}:${Y}:${HEIGHT}:${WIDTH}"
}

get_vert_center () {
	local HEIGHT=${1:=$(tput cols)}
	local HEIGHT_CENTER=$(( HEIGHT / 2 ))
	local REGION=${2:=$(tput lines)}
	local REGION_CENTER=$(( REGION / 2 ))
	local REM=0

	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: HEIGHT:${WHITE_FG}${HEIGHT}${RESET} REGION:${WHITE_FG}${REGION}${RESET}"
	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: HEIGHT_CENTER:${WHITE_FG}${HEIGHT_CENTER}${RESET} REGION_CENTER:${WHITE_FG}${REGION_CENTER}${RESET}"

	REM=$(( REGION_CENTER % 2 ))
	[[ ${REM} -ne 0 ]] && (( REGION_CENTER++ ))

	REM=$(( _HEIGHT_CENTER % 2 ))
	[[ ${REM} -ne 0 ]] && (( HEIGHT_CENTER++ ))

	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: CENTERS AFTER ROUNDING - HEIGHT_CENTER:${WHITE_FG}${HEIGHT_CENTER}${RESET} REGION_CENTER:${WHITE_FG}${REGION_CENTER}${RESET}"

	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: Return value (${WHITE_FG}${REGION_CENTER}${RESET} - ${WHITE_FG}${HEIGHT_CENTER}${RESET}):$(( REGION_CENTER - HEIGHT_CENTER ))"
	echo $(( REGION_CENTER - HEIGHT_CENTER ))
}

get_horz_center () {
	local WIDTH=${1:=$(tput lines)}
	local WIDTH_CENTER=$(( WIDTH / 2 ))
	local REGION=${2:=$(tput cols)}
	local REGION_CENTER=$(( REGION / 2 ))
	local REM=0

	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: WIDTH:${WHITE_FG}${WIDTH}${RESET} REGION:${WHITE_FG}${REGION}${RESET}"
	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: WIDTH_CENTER:${WHITE_FG}${WIDTH_CENTER}${RESET} REGION_CENTER:${WHITE_FG}${REGION_CENTER}${RESET}"

	REM=$(( REGION_CENTER % 2 ))
	[[ ${REM} -ne 0 ]] && (( REGION_CENTER++ ))

	REM=$(( WIDTH_CENTER % 2 ))
	[[ ${REM} -ne 0 ]] && (( WIDTH_CENTER++ ))

	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: CENTERS AFTER ROUNDING - WIDTH_CENTER:${WHITE_FG}${WIDTH_CENTER}${RESET} REGION_CENTER:${WHITE_FG}${REGION_CENTER}${RESET}"

	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: Return value (${WHITE_FG}${REGION_CENTER}${RESET} - ${WHITE_FG}${WIDTH_CENTER}${RESET}):$(( REGION_CENTER - WIDTH_CENTER ))"
	echo $(( REGION_CENTER - WIDTH_CENTER ))
}

center () {
	#--Begin GetOpts--
	local -a OPTIONS
	local OPTION
	local OPTSTR=":DBHRVc:h:w:s:x:y:"
	local OPTIND=0
	local BOX=false
	local HORZ=false
	local REL=false
	local VERT=false

	local _COORDS='' # COORDS of an existing box
	local _HEIGHT=0  # HEIGHT of a box to display
	local _WIDTH=''  # WIDTH of a box to display, width of text to center, or the text itself
	local _X_OFF=0   # Optional Vertical offset from center
	local _Y_OFF=0   # Optional Horizontal offset from center

	while getopts ${OPTSTR} OPTION;do
		case $OPTION in
		  D) dbg_set_level;;
		  B) BOX=true;;
		  H) HORZ=true;;
		  R) REL=true;;
		  V) VERT=true;;
		  c) _COORDS=${OPTARG};;
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

	if [[ ${BOX} == 'true' ]];then
		[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: Getting Box center"
		validate_opts w h x y
		get_box_center ${_HEIGHT} ${_WIDTH} ${_X_OFF} ${_Y_OFF} # Given WIDTH and HEIGHT returns X,Y center
	elif [[ ${VERT} == 'true' ]];then
		[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: Getting Vertical center"
		validate_opts h
		get_vert_center ${_HEIGHT} # ${_X_OFF} # Given HEIGHT returns X center
	elif [[ ${HORZ} == 'true' ]];then
		[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: Getting Horizontal center"
		validate_opts w
		get_horz_center ${_WIDTH} # ${_Y_OFF} # Given WIDTH Y center
	elif [[ ${REL} == 'true' ]];then
		[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: Getting Relative center"
		validate_opts c h w x y
		get_relative_center ${_COORDS} ${_HEIGHT} ${_WIDTH} ${_X_OFF} ${_Y_OFF} # Given COORDS, WIDTH and HEIGHT returns X,Y relative to COORDS
	fi
}

validate_opts () {
	local OPTS=(${@})
	local O

	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: Validating OPTS:${OPTS}"

	for O in ${OPTS};do
		case ${O} in
			c) if [[ ! ${_COORDS} =~ "\d{1,2}:\d{1,2}" && ! ${_COORDS} =~ "\d{1,2}:\d{1,2}:\d{1,2}:\d{1,2}" ]];then # Compatible with either format
					echo "_COORDS:${_COORDS}"
					echo "${_MOD} COORDS are not in the correct format" >&2 && kill $$
				fi;;
			h) if ! validate_is_number ${_HEIGHT};then
					echo "${_MOD} ${functrace[1]} HEIGHT is not numeric" >&2 && kill $$
				elif [[ ${_HEIGHT} -ge $(tput lines) ]];then
					echo "${_MOD} ${functrace[1]} HEIGHT exceeds maximum $(tput lines)" >&2 && kill $$
				elif [[ ${_HEIGHT} -lt 0 ]];then
					echo "${_MOD} ${functrace[1]} HEIGHT must be a positive integer" >&2 && kill $$
				fi;;
			w) if ! validate_is_number ${_WIDTH};then
					echo "${_MOD} ${functrace[1]} WIDTH is not numeric" >&2 && kill $$
				elif [[ ${_WIDTH} -ge $(tput cols) ]];then
					echo "${_MOD} ${functrace[1]} WIDTH exceeds maximum $(tput cols)" >&2 && kill $$
				elif [[ ${_WIDTH} -lt 0 ]];then
					echo "${_MOD} ${functrace[1]} WIDTH must be a positive integer" >&2 && kill $$
				fi;;
			x) if ! validate_is_number ${_X_OFF};then
					echo "${_MOD} ${functrace[1]} X_OFF is not numeric" >&2 && kill $$
				fi;;
			y) if ! validate_is_number ${_Y_OFF};then
					echo "${_MOD} ${functrace[1]} Y_OFF is not numeric" >&2 && kill $$
				fi;;
		esac
	done

	[[ ${_DEBUG} -ge ${LOW_DBG} ]] && dbg "${0}: OPTS are valid"
}
