# LIB Declarations
typeset _COORDS='' # COORDS of an existing box
typeset _HEIGHT=0  # HEIGHT of a box to display
typeset _WIDTH=''  # WIDTH of a box to display, width of text to center, or the text itself
typeset _X_OFF=0   # Optional Vertical offset from center
typeset _Y_OFF=0   # Optional Horizontal offset from center

# LIB Vars
_RCT=0
_MOD="[${0:t}]"

# LIB Functions
get_relative_center () {
	local COORDS=${1}
	local HEIGHT=${2}
	local WIDTH=${3}
	local X_OFF=${4:=0}
	local Y_OFF=${5:=0}
	local RX=0
	local RY=0
	local RH=0
	local RW=0
	local X=0
	local Y=0

	IFS=':';read RX RY RH RW <<<${COORDS}
	
	X=$(get_vert_center ${HEIGHT} ${RH})
	Y=$(get_horz_center ${WIDTH} ${RW})
	[[ ${X_OFF} -ne 0 ]] && X=$(( X + X_OFF ))
	[[ ${Y_OFF} -ne 0 ]] && Y=$(( Y + Y_OFF ))

	echo "${X}:${Y}:${HEIGHT}:${WIDTH}"
}

get_box_center () {
	local HEIGHT=${1}
	local WIDTH=${2}
	local X_OFF=${3:=0}
	local Y_OFF=${4:=0}
	local X=0
	local Y=0

	X=$(get_vert_center ${_HEIGHT})
	Y=$(get_horz_center ${_WIDTH})
	[[ ${X_OFF} -ne 0 ]] && X=$(( X + X_OFF ))
	[[ ${Y_OFF} -ne 0 ]] && Y=$(( Y + Y_OFF ))

	echo "${X}:${Y}:${HEIGHT}:${WIDTH}"
}

get_vert_center () {
	local HEIGHT=${1:=$(tput cols)}
	local REGION=${2:=$(tput lines)}
	local REGION_CENTER=$(( REGION / 2 ))
	local HEIGHT_CENTER=$(( HEIGHT / 2 ))
	local REM=0

	REM=$(( REGION_CENTER % 2 ))
	[[ ${REM} -ne 0 ]] && (( REGION_CENTER++ ))

	REM=$(( _HEIGHT_CENTER % 2 ))
	[[ ${REM} -ne 0 ]] && (( HEIGHT_CENTER++ ))

	echo $(( REGION_CENTER - HEIGHT_CENTER ))
}

get_horz_center () {
	local WIDTH=${1:=$(tput lines)}
	local REGION=${2:=$(tput cols)}
	local REGION_CENTER=$(( REGION / 2 ))
	local WIDTH_CENTER=$(( WIDTH / 2 ))
	local REM=0

	REM=$(( REGION_CENTER % 2 ))
	[[ ${REM} -ne 0 ]] && (( REGION_CENTER++ ))

	REM=$(( WIDTH_CENTER % 2 ))
	[[ ${REM} -ne 0 ]] && (( WIDTH_CENTER++ ))

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

	_HEIGHT=0
	_X_OFF=0
	_Y_OFF=0
	_COORDS=''
	_WIDTH=''

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
		  :) print -u2 "\n${RED_FG}${_MOD} ${WHITE_FG}${functrace}${RESET}: option: -${OPTARG} requires an argument"; exit_leave;;
		 \?) print -u2 "\n${RED_FG}${_MOD} ${WHITE_FG}${functrace}${RESET}: unknown option -${OPTARG}"; exit_leave;;
		esac
		[[ ${OPTION} != 'D' ]] && OPTIONS+=${OPTION}
	done
	shift $((OPTIND -1))
	#--End GetOpts--

	if ! validate_is_number ${_WIDTH};then # Allow WIDTH to be passed as text
		_WIDTH=${#_WIDTH}
	fi

	if [[ ${BOX} == 'true' ]];then
		validate_opts w h x y
		get_box_center ${_HEIGHT} ${_WIDTH} ${_X_OFF} ${_Y_OFF}# Given WIDTH and HEIGHT returns X,Y center
	elif [[ ${VERT} == 'true' ]];then
		validate_opts h
		get_vert_center ${_HEIGHT} # Given HEIGHT returns X center
	elif [[ ${HORZ} == 'true' ]];then
		validate_opts w
		get_horz_center ${_WIDTH} # Given WIDTH Y center
	elif [[ ${REL} == 'true' ]];then
		validate_opts c h w x y
		get_relative_center ${_COORDS} ${_HEIGHT} ${_WIDTH} ${_X_OFF} ${_Y_OFF} # Given COORDS, WIDTH and HEIGHT returns X,Y relative to COORDS
	fi
}

validate_opts () {
	local OPTS=(${@})
	local O

	for O in ${OPTS};do
		case ${O} in
			c) if [[ ! ${_COORDS} =~ "\d{1,2}:\d{1,2}" && ! ${_COORDS} =~ "\d{1,2}:\d{1,2}:\d{1,2}:\d{1,2}" ]];then # Compatible with either format
					echo "_COORDS:${_COORDS}"
					echo "${_MOD} COORDS are not in the correct format" >&2 && kill $$
				fi;;
			h) if ! validate_is_number ${_HEIGHT};then
					echo "${_MOD} ${functrace} HEIGHT is not numeric" >&2 && kill $$
				elif [[ ${_HEIGHT} -ge $(tput lines) ]];then
					echo "${_MOD} ${functrace} HEIGHT exceeds maximum $(tput lines)" >&2 && kill $$
				elif [[ ${_HEIGHT} -lt 0 ]];then
					echo "${_MOD} ${functrace} HEIGHT must be a positive integer" >&2 && kill $$
				fi;;
			w) if ! validate_is_number ${_WIDTH};then
					echo "${_MOD} ${functrace} WIDTH is not numeric" >&2 && kill $$
				elif [[ ${_WIDTH} -ge $(tput cols) ]];then
					echo "${_MOD} ${functrace} WIDTH exceeds maximum $(tput cols)" >&2 && kill $$
				elif [[ ${_WIDTH} -lt 0 ]];then
					echo "${_MOD} ${functrace} WIDTH must be a positive integer" >&2 && kill $$
				fi;;
			x) if ! validate_is_number ${_X_OFF};then
					echo "${_MOD} ${functrace} X_OFF is not numeric" >&2 && kill $$
				fi;;
			y) if ! validate_is_number ${_Y_OFF};then
					echo "${_MOD} ${functrace} Y_OFF is not numeric" >&2 && kill $$
				fi;;
		esac
	done
}
