# LIB Dependencies
_DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh STR.zsh TPUT.zsh UTILS.zsh VALIDATE.zsh"

# LIB Declarations
typeset -A _CAT_COLS=()
typeset -A _LIST_DATA=()
typeset -a _APP_KEYS=()
typeset -a _LIST=()

# LIB Vars
_EXIT_BOX=32
_HAS_CAT=false
_HILITE=${WHITE_ON_GREY}
_HILITE_X=0
_SEL_KEY=''
_SEL_LIB_DBG=4
_SEL_VAL=''
_TAG=''
_TAG_FILE=''

sel_box_center () {
	local BOX_LEFT=${1};shift # Box Y coord
	local BOX_WIDTH=${1};shift # Box W coord
	local TXT=${@} # Text to center
	local TXT_LEN=0
	local BOX_CTR=0
	local CTR=0
	local REM=0
	local TXT_CTR=0

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if validate_is_integer ${TXT};then
		TXT_LEN=${TXT}
	else
		TXT_LEN=${#TXT}
	fi

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TXT:${TXT} TXT_LEN:${TXT_LEN}"

	CTR=$(( TXT_LEN / 2 )) && REM=$((CTR % 2))
	[[ ${REM} -ne 0 ]] && TXT_CTR=$((CTR+1)) || TXT_CTR=${CTR}

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( TXT_LEN / 2 )) && REM=$((CTR % 2))'
	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "CTR:${CTR} REM:${REM}"

	CTR=$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))
	[[ ${REM} -ne 0 ]] && BOX_CTR=$((CTR+1)) || BOX_CTR=${CTR}

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))'
	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "CTR:${CTR} REM:${REM}"

	CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))'
	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "CTR:${CTR}"

	echo ${CTR}
}

sel_hilite () {
	local X=${1}
	local Y=${2}
	local TEXT=${3}
	local F1 F2

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"

	tcup ${X} ${Y}

	do_smso
	if [[ ${_HAS_CAT} == 'true' ]];then
		F1=$(cut -d: -f1 <<<${TEXT})
		F2=$(cut -d: -f2 <<<${TEXT})
		printf "${WHITE_FG}%-*s${RESET} ${_HILITE}%-*s${RESET}\n" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
	else
		echo ${TEXT}
	fi
	do_rmso

	_HILITE_X=${X}
}

sel_list () {
	local BOX_BOT=0
	local BOX_H=0
	local BOX_W=0
	local BOX_X_COORD=0
	local BOX_Y_COORD=0
	local F1=''
	local F2=''
	local LIST_H=0
	local LIST_NDX=0
	local LIST_W=0
	local LIST_X=0
	local LIST_Y=0
	local OB_H=0
	local OB_W=0
	local OB_X=0
	local OB_Y=0
	local OB_X_OFFSET=2
	local OB_Y_OFFSET=4
	local PAD=0
	local DIFF=0
	local L

	local OPTION=''
	local OPTSTR=":CF:H:I:M:O:T:x:y:"
	OPTIND=0

	local HAS_OB=false
	local LIST_FTR=''
	local LIST_HDR=''
	local LIST_MAP=''
	local IB_COLOR=''
	local OB_COLOR=''
	local X_COORD_ARG=0
	local Y_COORD_ARG=0
	local HAS_HDR=false
	local HAS_FTR=false
	local HAS_MAP=false
	local _HAS_CAT=false

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	while getopts ${OPTSTR} OPTION;do
		case $OPTION in
	   C) _HAS_CAT=true;;
		F) HAS_FTR=true;LIST_FTR=${OPTARG};;
		H) HAS_HDR=true;LIST_HDR=${OPTARG};;
	   I) IB_COLOR=${OPTARG};;
		M) HAS_MAP=true;LIST_MAP=${OPTARG};;
	   O) HAS_OB=true;OB_COLOR=${OPTARG};;
	   T) _TAG=${OPTARG};;
	   x) X_COORD_ARG=${OPTARG};;
	   y) Y_COORD_ARG=${OPTARG};;
	   :) exit_leave "${RED_FG}${0}${RESET}: option: -${OPTARG} requires an argument";;
	  \?) exit_leave "${RED_FG}${0}${RESET}: unknown option -${OPTARG}";;
		esac
	done
	shift $(( OPTIND - 1 ))

	[[ -n ${_TAG}  ]] && _TAG_FILE="/tmp/$$.${_TAG}.state"

	LIST_W=$(arr_long_elem_len ${_LIST})
	LIST_H=${#_LIST}

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: LIST_W:${LIST_W} LIST_H:${LIST_H}"

	BOX_W=$((LIST_W+2))
	BOX_H=$((LIST_H+2))

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: INNER BOX - BOX_W:${BOX_W} BOX_H:${BOX_H}"

	# Parse columns for lists having categories
	if [[ ${_HAS_CAT} == 'true' ]];then
		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _HAS_CAT:${_HAS_CAT}"
		for L in ${_LIST};do
			F1=$(cut -d: -f1 <<<${L})
			F2=$(cut -d: -f2 <<<${L})
			[[ ${#F1} -gt ${_CAT_COLS[1]} ]] && _CAT_COLS[1]=${#F1}
			[[ ${#F2} -gt ${_CAT_COLS[2]} ]] && _CAT_COLS[2]=${#F2}
		done
	else
		_CAT_COLS=()
	fi

	# If no coords are passed default to center
	[[ ${X_COORD_ARG} -eq 0 ]] && BOX_X_COORD=$(coord_center $(( _MAX_ROWS - 1 )) ${BOX_H}) || BOX_X_COORD=${X_COORD_ARG}
	[[ ${Y_COORD_ARG} -eq 0 ]] && BOX_Y_COORD=$(coord_center $(( _MAX_COLS - 1 )) ${BOX_W}) || BOX_Y_COORD=${Y_COORD_ARG}

	BOX_BOT=$((BOX_X_COORD+BOX_H)) # Store coordinate

	# Handle outer box
	if [[ ${HAS_OB} == 'true' ]];then
		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: OUTER BOX - HAS_OB:${HAS_OB}"
		OB_X=$(( BOX_X_COORD - OB_X_OFFSET ))
		OB_Y=$(( BOX_Y_COORD - OB_Y_OFFSET ))
		OB_W=$(( BOX_W + OB_Y_OFFSET * 2 ))
		OB_H=$(( BOX_H + OB_X_OFFSET * 2 ))
		PAD=$(max ${#LIST_HDR} ${#LIST_FTR} ${#LIST_MAP} ${_EXIT_BOX} ) # Longest text - header, footer, map, or exit msg

		if [[ ${PAD} -gt ${OB_W} ]];then
			DIFF=$(( (PAD - OB_W) / 2 ))
			(( OB_Y-=DIFF ))
			(( OB_W+=DIFF * 2 ))
		fi

		msg_unicode_box ${OB_X} ${OB_Y} ${OB_W} ${OB_H} ${OB_COLOR}
		box_coords_set OUTER_BOX X ${OB_X} Y ${OB_Y} W ${OB_W} H ${OB_H}
	fi

	# Handle inner box for list
	msg_unicode_box ${BOX_X_COORD} ${BOX_Y_COORD} ${BOX_W} ${BOX_H} ${IB_COLOR}
	box_coords_set INNER_BOX X ${BOX_X_COORD} Y ${BOX_Y_COORD} W ${BOX_W} H ${BOX_H} OB_W ${OB_W} OB_Y ${OB_Y}

	# List inside box coords
	LIST_X=$(( BOX_X_COORD+1 ))
	LIST_Y=$(( BOX_Y_COORD+1 ))

	# Save data for future reference
	_LIST_DATA[X]=${LIST_X}
	_LIST_DATA[Y]=${LIST_Y}
	_LIST_DATA[MAX]=${#_LIST}

	# Display list
	cursor_off
	for (( LIST_NDX=1;LIST_NDX <= LIST_H;LIST_NDX++ ));do
		sel_norm $((LIST_X++)) ${LIST_Y} ${_LIST[${LIST_NDX}]}
	done

	# Display header, map, and footer
	if [[ ${HAS_HDR} == 'true' ]];then
		if [[ ${HAS_OB} == 'true' ]];then
			tcup $(( BOX_X_COORD -3 )) $(sel_box_center $(( BOX_Y_COORD - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_HDR}));echo $(msg_markup ${LIST_HDR})
		else
			tcup $(( BOX_X_COORD - 1 )) $(sel_box_center ${BOX_Y_COORD} ${BOX_W} $(msg_nomarkup ${LIST_HDR}));echo $(msg_markup ${LIST_HDR})
		fi
	fi

	if [[ ${HAS_MAP} == 'true' ]];then
		if [[ ${HAS_OB} == 'true' ]];then
			tcup ${BOX_BOT} $(sel_box_center $(( BOX_Y_COORD - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_MAP}));echo $(msg_markup ${LIST_MAP})
		else
			tcup ${BOX_BOT} $(sel_box_center ${BOX_Y_COORD} ${BOX_W} $(msg_nomarkup ${LIST_MAP}));echo $(msg_markup ${LIST_MAP})
		fi
	fi

	if [[ ${HAS_FTR} == 'true' ]];then
		if [[ ${HAS_OB} == 'true' ]];then
			tcup $(( BOX_BOT + 2 )) $(sel_box_center $(( BOX_Y_COORD - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_FTR}));echo $(msg_markup ${LIST_FTR})
		else
			tcup $(( BOX_BOT + 2 )) $(sel_box_center ${BOX_Y_COORD} ${BOX_W} $(msg_nomarkup ${LIST_FTR}));echo $(msg_markup ${LIST_FTR})
		fi
	fi

	sel_scroll
}

sel_norm () {
	local X=${1}
	local Y=${2}
	local TEXT=${3}
	local F1 F2

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"

	tcup ${X} ${Y}
	do_rmso
	if [[ ${_HAS_CAT} == 'true' ]];then
		F1=$(cut -d: -f1 <<<${TEXT})
		F2=$(cut -d: -f2 <<<${TEXT})
		printf "${WHITE_FG}%-*s${RESET} %-*s\n" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
	else
		echo ${TEXT}
	fi
}

sel_scroll () {
	local BOT_X=0
	local KEY=''
	local NAV=''
	local NDX=0
	local NORM_NDX=0
	local SCROLL=''
	local TAG_NDX=0
	local X_OFF=0
	
	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	LIST_X=${_LIST_DATA[X]}
	BOT_X=$(( _LIST_DATA[X] + _LIST_DATA[MAX] - 1 ))
	X_OFF=$(( _LIST_DATA[X] - 1 ))

	if [[ -e ${_TAG_FILE}  ]];then
		read TAG_NDX < ${_TAG_FILE}
	fi

	[[ ${TAG_NDX} -ne 0 ]] && NDX=${TAG_NDX} || NDX=1 # Initialize index
	_SEL_VAL=${_LIST[${NDX}]} # Initialize return value

	sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]} # Initial hilite

	while true;do
		KEY=$(get_keys)

		_SEL_KEY='?'

		# Reserved application key breaks from navigation
		if [[ ${_APP_KEYS[(i)${KEY}]} -le ${#_APP_KEYS} ]];then # App key was pressed
			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"

			_SEL_KEY=${KEY} 

			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"

			break # Quit navigation
		fi

		NAV=true # Return only menu selections

		case ${KEY} in
			0) break;;
			q) exit_request $(sel_set_ebox);break;;
			1|u|k) SCROLL="U";;
			2|d|j) SCROLL="D";;
			3|t|h) SCROLL="T";;
			4|b|l) SCROLL="B";;
			*) NAV=false;;
		esac

		if [[ ${SCROLL} == 'U' ]];then
			NORM_NDX=${NDX} && ((NDX--))
			[[ ${NDX} -lt 1 ]] && NDX=${_LIST_DATA[MAX]}
			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
		elif [[ ${SCROLL} == 'D' ]];then
			NORM_NDX=${NDX} && ((NDX++))
			[[ ${NDX} -gt ${_LIST_DATA[MAX]} ]] && NDX=1
			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
		elif [[ ${SCROLL} == 'T' ]];then
			NORM_NDX=${NDX} && NDX=1
			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
		elif [[ ${SCROLL} == 'B' ]];then
			NORM_NDX=${NDX} && NDX=${_LIST_DATA[MAX]}
			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
		fi

		if [[ ${NAV} == 'true' ]];then # Return (populate) menu selection
			_SEL_KEY=${KEY}
			_SEL_VAL=${_LIST[${NDX}]}
			[[ -n ${_TAG_FILE} ]] && echo "${NDX}" >${_TAG_FILE}
		fi
	done
	return 0
}

sel_set_app_keys () {
	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _APP_KEYS:${_APP_KEYS}"

	_APP_KEYS=(${@})
}

sel_set_ebox () {
	local -A I_COORDS
	local MSG_LEN=28
	local X_ARG=0
	local Y_ARG=0
	local W_ARG=0
	local DIFF=0

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	I_COORDS=($(box_coords_get INNER_BOX))
	X_ARG=$(( I_COORDS[X] + 1 ))
	Y_ARG=$(( I_COORDS[Y] - 2 ))

	if	[[ ${I_COORDS[OB_W]} -ne 0 ]];then
		Y_ARG=$(( I_COORDS[OB_Y] + 2 ))
		W_ARG=$(( I_COORDS[OB_W] -2 ))
	elif [[ ${MSG_LEN} -gt ${I_COORDS[W]}  ]];then
		DIFF=$(( (MSG_LEN - I_COORDS[W]) / 2 ))
		Y_ARG=$(( I_COORDS[Y] - DIFF ))
	fi

	echo ${X_ARG} ${Y_ARG} ${W_ARG} 
}

sel_set_list () {
	local -a LIST=(${@})

	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST=(${LIST})
}

