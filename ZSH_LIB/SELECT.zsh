# LIB Dependencies
_DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh STR.zsh TPUT.zsh ./UTILS.zsh VALIDATE.zsh"

# Constants
_EXIT_BOX=32
_HILITE=${WHITE_ON_GREY}
_PAGE_MAX_ROWS=$(( _MAX_ROWS - 15 )) # Longest list that fits the available display
_DMD="\u25C8"

# LIB Declarations
typeset -A _CAT_COLS=()
typeset -A _LIST_DATA=()
typeset -A _PAGE_TOPS=()
typeset -A _TAG_DATA=()
typeset -a _APP_KEYS=()
typeset -a _LIST=()
typeset -a _PAGE=()

# LIB Vars
_CAT_DELIM=':'
_CAT_SORT=r
_CURRENT_PAGE=0
_HAS_CAT=false
_HILITE_X=0
_SAVE_MENU_POS=false
_SELECT_TAG_FILE="/tmp/$$.${0:t}.state"
_SEL_KEY=''
_SEL_VAL=''
_TAG=''

# Functtons
sel_box_center () {
	local BOX_LEFT=${1};shift # Box Y coord
	local BOX_WIDTH=${1};shift # Box W coord
	local TXT=${@} # Text to center
	local BOX_CTR=0
	local CTR=0
	local REM=0
	local TXT_CTR=0
	local TXT_LEN=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if validate_is_integer ${TXT};then # Accept either strings or integers
		TXT_LEN=${TXT}
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: GOT INTEGER FOR TXT_LEN"
	else
		TXT_LEN=${#TXT}
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: GOT STRING FOR TXT_LEN"
	fi

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ARGC:${#@} TXT:${TXT} TXT_LEN:${TXT_LEN}"

	CTR=$(( TXT_LEN / 2 )) && REM=$((TXT_LEN % 2))
	[[ ${REM} -ne 0 ]] && TXT_CTR=$((CTR+1)) || TXT_CTR=${CTR}

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CTR='$(( TXT_LEN / 2 )) && REM=$((CTR % 2))':$(( TXT_LEN / 2 )) && REM:$((CTR % 2))"

	CTR=$(( BOX_WIDTH / 2 )) && REM=$((BOX_WIDTH % 2))
	[[ ${REM} -ne 0 ]] && BOX_CTR=$((CTR+1)) || BOX_CTR=${CTR}

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CTR='$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))':$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))"

	CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CTR='$(( BOX_LEFT + BOX_CTR - TXT_CTR ))': $(( BOX_LEFT + BOX_CTR - TXT_CTR ))"
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: BOX_LEFT:${BOX_LEFT} BOX_CTR:${BOX_CTR} TXT_CTR:${TXT_CTR}"

	echo ${CTR}
}

sel_clear_region () {
	local -A R_COORDS
	local X_ARG=0
	local Y_ARG=0
	local W_ARG=0
	local H_ARG=0
	local DIFF=0
	local R=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	R_COORDS=($(box_coords_get REGION))

	if [[ -z ${R_COORDS} ]];then
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: R_COORDS is null - returning"
		return -1
	else
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: R_COORDS: ${(kv)R_COORDS}"
	fi

	X_ARG=${R_COORDS[X]}
	Y_ARG=${R_COORDS[Y]}
	W_ARG=${R_COORDS[W]}
	H_ARG=${R_COORDS[H]}

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"

	if	[[ ${R_COORDS[OB_W]} -ne 0 ]];then
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: HAS OUTER BOX"
		((X_ARG-=1))
		Y_ARG=$(( R_COORDS[OB_Y] - 4 ))
		W_ARG=$(( R_COORDS[OB_W] + 8 ))
		((H_ARG+=5))
	else
		((X_ARG-=1))
		((Y_ARG-=2))
		((W_ARG+=4))
		((H_ARG+=2))
	fi
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"

	local STR=$(str_rep_char "#" ${W_ARG})
	for (( R=0; R <= ${H_ARG}; R++ ));do
		tcup $(( X_ARG + R )) ${Y_ARG};tput ech ${W_ARG}
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${STR} # Show cleared display area in debug
	done

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Cleared ${H_ARG} rows starting from row:${X_ARG}, col:${Y_ARG} for:${W_ARG} columns"
}

sel_disp_page () {
	local NDX=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"

	for (( NDX=1; NDX <= ${#_PAGE}; NDX++ ));do
		sel_norm $(( _LIST_DATA[X] + NDX - 1 )) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
	done
}

sel_get_position () {
	local PAGE=0
	local NDX=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	if [[ -e ${_SELECT_TAG_FILE} ]];then
		IFS='|' read -r PAGE NDX < ${_SELECT_TAG_FILE} # Retrieve stored position
		[[ -n ${PAGE} ]] && _TAG_DATA[PAGE]=${PAGE} || _TAG_DATA[PAGE]=''
		[[ -n ${NDX} ]] && _TAG_DATA[NDX]=${NDX} || _TAG_DATA[NDX]=''
		[[ -n ${_TAG_DATA[PAGE]} && -n ${_TAG_DATA[NDX]} ]] && _TAG_DATA[RESTORE]=true || _TAG_DATA[RESTORE]=false
		/bin/rm -f ${_SELECT_TAG_FILE}
	fi
}

sel_hilite () {
	local X=${1}
	local Y=${2}
	local TEXT=${3}
	local F1 F2

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"

	tcup ${X} ${Y}

	do_smso
	if [[ ${_HAS_CAT} == 'true' ]];then
		F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${TEXT})
		F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${TEXT})
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
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
	local BOX_X=0
	local BOX_Y=0
	local DIFF=0
	local F1=''
	local F2=''
	local FTR_X=0
	local FTR_Y=0
	local HDR_X=0
	local HDR_Y=0
	local LIST_H=0
	local LIST_NDX=0
	local LIST_W=0
	local LIST_X=0
	local LIST_Y=0
	local MAP_X=0
	local MAP_Y=0
	local MH=0
	local NM_H=''
	local NM_F=''
	local NM_M=''
	local NM_P=''
	local PGH_X=0
	local PGH_Y=0
	local PH=0
	local MAX=0
	local OB_H=0
	local OB_W=0
	local OB_X=0
	local OB_X_OFFSET=2
	local OB_Y=0
	local OB_Y_OFFSET=4
	local PAGING=false
	local PAGE_HDR=''
	local L

	local OPTION=''
	local OPTSTR=":F:H:I:M:O:T:W:d:s:x:y:SCc"
	OPTIND=0

	local CLEAR_REGION=false
	local HAS_FTR=false
	local HAS_HDR=false
	local HAS_MAP=false
	local HAS_OUTER=false
	local IB_COLOR=${RESET}
	local LIST_FTR=''
	local LIST_HDR=''
	local LIST_MAP=''
	local LM=0
	local MAX=0
	local MAX_PAGE=0
	local MIN=0
	local OB_COLOR=${RESET}
	local OB_PAD=0
	local X_COORD_ARG=0
	local Y_COORD_ARG=0
	local _HAS_CAT=false
	local STR=''

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	while getopts ${OPTSTR} OPTION;do
		case $OPTION in
	   C) _HAS_CAT=true;;
		F) HAS_FTR=true;LIST_FTR=${OPTARG};;
		H) HAS_HDR=true;LIST_HDR=${OPTARG};;
	   I) IB_COLOR=${OPTARG};;
		M) HAS_MAP=true;LIST_MAP=${OPTARG};;
	   O) HAS_OUTER=true;OB_COLOR=${OPTARG};;
		S) _SAVE_MENU_POS=true;;
	   T) _TAG=${OPTARG};;
	   W) OB_PAD=${OPTARG};;
	   c) CLEAR_REGION=true;;
	   d) _CAT_DELIM=${OPTARG};;
	   s) _CAT_SORT=${OPTARG};;
	   x) X_COORD_ARG=${OPTARG};;
	   y) Y_COORD_ARG=${OPTARG};;
	   :) exit_leave "${RED_FG}${0}${RESET}: option: -${OPTARG} requires an argument";;
	  \?) exit_leave "${RED_FG}${0}${RESET}: unknown option -${OPTARG}";;
		esac
	done
	shift $(( OPTIND - 1 ))

	[[ ${#_LIST} -gt 100 ]] && msg_box -c "<w>Building select list...<N>"

	[[ -n ${_TAG}  ]] && _SELECT_TAG_FILE="/tmp/$$.${_TAG}.state"

	# If no X,Y coords are passed default to center
	LIST_W=$(arr_long_elem_len ${_LIST})
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: arr_long_elem_len returned: ${LIST_W}"

	if [[ ${LIST_W} -gt ${_MAX_COLS} ]];then
		LIST_W=$(( _MAX_COLS - 20 ))
		local LONG_EL=$(arr_long_elem ${_LIST})
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: arr_long_elem returned: ${LONG_EL}"
	fi

	[[ ${#_LIST} -gt ${_PAGE_MAX_ROWS} ]] && LIST_H=${_PAGE_MAX_ROWS} || LIST_H=${#_LIST}
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: LIST_W:${LIST_W} LIST_H:${LIST_H}"

	BOX_H=$((LIST_H+2)) # Box height based on list count
	[[ ${_HAS_CAT} == 'true' ]] && BOX_W=$(( LIST_W + 6 )) || BOX_W=$(( LIST_W + 2 )) # Categories get extra padding
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: INNER BOX SET: BOX_W:${BOX_W} BOX_H:${BOX_H}"

	[[ ${X_COORD_ARG} -eq 0 ]] && BOX_X=$(coord_center $(( _MAX_ROWS - 1 )) ${BOX_H}) || BOX_X=${X_COORD_ARG}
	[[ ${Y_COORD_ARG} -eq 0 ]] && BOX_Y=$(coord_center $(( _MAX_COLS - 1 )) ${BOX_W}) || BOX_Y=${Y_COORD_ARG}

	# Set field widths for lists having categories
	if [[ ${_HAS_CAT} == 'true' ]];then
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CATEGORIES DETECTED"
		for L in ${_LIST};do
			F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${L})
			F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${L})
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
			[[ ${#F1} -gt ${_CAT_COLS[1]} ]] && _CAT_COLS[1]=${#F1}
			[[ ${#F2} -gt ${_CAT_COLS[2]} ]] && _CAT_COLS[2]=${#F2}
		done
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SET category field widths: F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
		case ${_CAT_SORT} in
			r) _LIST=(${(O)_LIST});; # Descending categories
			a) _LIST=(${(o)_LIST});; # Ascending categories
			n) _LIST=(${_LIST});; # No sorting of categories
		esac
	else
		_CAT_COLS=()
	fi

	_PAGE_TOPS=($(sel_set_pages ${#_LIST} ${LIST_H})) # Create table of page top indexes

	PAGE_HDR="Page <w>${_PAGE_TOPS[MAX]}<N> of <w>${_PAGE_TOPS[MAX]}<N> ${_DMD} (<w>N<N>)ext (<w>P<N>)rev" # Create paging template

	# Decorations w/o markup
	NM_H=$(msg_nomarkup ${LIST_HDR})
	NM_F=$(msg_nomarkup ${LIST_FTR})
	NM_M=$(msg_nomarkup ${LIST_MAP})
	NM_P=$(msg_nomarkup ${PAGE_HDR})

	[[ ${_PAGE_TOPS[MAX]} -gt 1 ]] && PAGING=true

	MH=${#NM_M} # Set default MAP width
	[[ ${PAGING} == 'true' ]] && PH=${#NM_P} # Set default PAGING width
	if [[ ${HAS_OUTER} == 'true' ]];then
		((MH+=6)) # Add padding for MAP
		[[ ${PAGING} == 'true' ]] && ((PH+=4)) # Add padding for PAGING
	fi

	# Widest decoration - inner box, header, footer, map, paging, or exit msg
	MAX=$(max ${BOX_W} ${#NM_H} ${#NM_F} ${MH} ${PH} ${_EXIT_BOX}) # Add padding for MAP
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${#NM_H} LIST_FTR:${#NM_F} LIST_MAP:${MH} PAGE_HDR:${PH} _EXIT_BOX:${_EXIT_BOX}" 

	# Handle outer box coords
	if [[ ${HAS_OUTER} == 'true' ]];then
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Setting OUTER BOX coords"
		OB_X=$(( BOX_X - OB_X_OFFSET ))
		OB_Y=$(( BOX_Y - OB_Y_OFFSET ))
		OB_W=$(( BOX_W + OB_Y_OFFSET * 2 ))
		OB_H=$(( BOX_H + OB_X_OFFSET * 2 ))

		if [[ ${MAX} -gt ${OB_W} ]];then
			DIFF=$(( (MAX - OB_W) / 2 ))
			(( OB_Y-=DIFF ))
			(( OB_W+=DIFF * 2 ))
		fi
		MIN=$(min ${OB_X} ${OB_Y} ${OB_W} ${OB_H})
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: OUTER_BOX coords: MIN:${MIN} OB_X:${OB_X}  OB_Y:${OB_Y} OB_W:${OB_W} OB_H:${OB_H}"

		if [[ ${MIN} -lt 1 ]];then
			exit_leave "[${WHITE_FG}SELECT.zsh${RESET}] ${RED_FG}OUTER BOX${RESET} would exceed available display. ${CYAN_FG}HINT${RESET}: increase sel_list -y option from ${Y_COORD_ARG} to $(( (MIN * -1) + Y_COORD_ARG + 1 ))"
		fi
	fi

	# Store OUTER_BOX coords
	box_coords_set OUTER_BOX HAS_OUTER ${HAS_OUTER} X ${OB_X} Y ${OB_Y} W ${OB_W} H ${OB_H} COLOR ${OB_COLOR}

	BOX_BOT=$(( BOX_X + BOX_H)) # Store coordinate

	# Set coords for list decorations
	if [[ ${HAS_OUTER} == 'true' ]];then
		HDR_X=$(( BOX_X - 3 ))
		HDR_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) ${NM_H})
		MAP_X=${BOX_BOT}
		MAP_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) ${NM_M})
		FTR_X=$(( BOX_BOT + 2 ))
		FTR_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) ${NM_F})
		PGH_X=$(( BOX_X - 1 ))
		PGH_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) ${NM_P})
	else
		HDR_X=$(( BOX_X - 1 ))
		HDR_Y=$(sel_box_center ${BOX_Y} ${BOX_W} ${NM_H})
		[[ -n ${PAGE_HDR} ]] && MAP_X=$(( BOX_BOT + 1 )) || MAP_X=${BOX_BOT} # Move map down if blocked
		MAP_Y=$(sel_box_center ${BOX_Y} ${BOX_W} ${NM_M})
		[[ -n ${LIST_MAP} || -n ${PAGE_HDR} ]] && FTR_X=$(( MAP_X + 1 )) || FTR_X=${BOX_BOT} # Move footer down if blocked
		FTR_Y=$(sel_box_center ${BOX_Y} ${BOX_W} ${NM_F})
		PGH_X=${BOX_BOT}
		PGH_Y=$(sel_box_center ${BOX_Y} ${BOX_W} ${NM_P})
	fi

	# Store DECOR coords
	box_coords_set DECOR HAS_HDR ${HAS_HDR} HDR_X ${HDR_X} HDR_Y ${HDR_Y} HAS_MAP ${HAS_MAP} MAP_X ${MAP_X} MAP_Y ${MAP_Y} HAS_FTR ${HAS_FTR} FTR_X ${FTR_X} FTR_Y ${FTR_Y}

	# Set coords for region clearing
	local R_H=$(max $(( FTR_X - BOX_X )) $(( MAP_X - BOX_X )) $(( PGH_X - BOX_X )) ${BOX_H}) 
	local R_Y=$(min ${HDR_Y} ${MAP_Y} ${FTR_Y} ${PGH_Y} ${BOX_Y})
	local R_W=$(max ${#LIST_HDR} ${#LIST_MAP} ${#LIST_FTR} ${#PAGE_HDR} ${BOX_W})

	# Store REGION clearing coords
	box_coords_set REGION X ${HDR_X} Y ${R_Y} W ${R_W} H ${R_H} OB_W ${OB_W} OB_Y ${OB_Y} # For display region clearing if needed

	# Store INNER_BOX coords
	box_coords_set INNER_BOX X ${BOX_X} Y ${BOX_Y} W ${BOX_W} H ${BOX_H} COLOR ${IB_COLOR} OB_W ${OB_W} OB_Y ${OB_Y}

	# List coords w/ box offset
	LIST_X=$(( BOX_X + 1 ))
	LIST_Y=$(( BOX_Y + 1 ))

	# Save data for future reference
	_LIST_DATA[BOX_W]=${BOX_W}
	_LIST_DATA[BOX_Y]=${BOX_Y}
	_LIST_DATA[CLEAR_REGION]=${CLEAR_REGION}
	_LIST_DATA[FTR]=${LIST_FTR}
	_LIST_DATA[HDR]=${LIST_HDR}
	_LIST_DATA[H]=${LIST_H}
	_LIST_DATA[MAP]=${LIST_MAP}
	_LIST_DATA[PAGING]=${PAGING}
	_LIST_DATA[PGH_X]=${PGH_X}
	_LIST_DATA[PGH_Y]=${PGH_Y}
	_LIST_DATA[X]=${LIST_X}
	_LIST_DATA[Y]=${LIST_Y}

	msg_box_clear

	sel_scroll 1 # Display list page 1 and handle user inputs
}

sel_load_page () {
	local PAGE=${1}
	local NDX=0
	local TOP_ROW=1

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	# Evaluate/validate PAGE arg
	if [[ -n ${_PAGE_TOPS[${PAGE}]} ]];then
		TOP_ROW=${_PAGE_TOPS[${PAGE}]}
	else
		TOP_ROW=1
		PAGE=1
	fi
	 
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: TOP_ROW:${TOP_ROW}"

	_PAGE=()
	for (( NDX=1; NDX <= _LIST_DATA[H]; NDX++ ));do
		[[ -z ${_LIST[$(( NDX + TOP_ROW - 1 ))]} ]] && continue # No blank rows
		_PAGE+=${_LIST[$(( NDX + TOP_ROW - 1 ))]}
		[[ ${NDX} -eq ${#_LIST} ]] && break
	done
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ADDED NDX ROWS"
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: _LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE} PAGE:${PAGE}"

	_CURRENT_PAGE=${PAGE} # Set the currently displayed page
}

sel_norm () {
	local X=${1}
	local Y=${2}
	local TEXT=${3}
	local F1 F2

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"

	tcup ${X} ${Y}
	do_rmso
	if [[ ${_HAS_CAT} == 'true' ]];then
		F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${TEXT})
		F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${TEXT})
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
		printf "${WHITE_FG}%-*s${RESET} %-*s\n" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
	else
		echo ${TEXT}
	fi
}

sel_scroll () {
	local PAGE=${1}
	local -A D_COORDS=($(box_coords_get DECOR))
	local -A I_COORDS=($(box_coords_get INNER_BOX))
	local -A O_COORDS=($(box_coords_get OUTER_BOX))
	local BOT_X=0
	local KEY=''
	local LAST_TAG=?
	local LIST_X=0
	local NAV=''
	local NDX=0
	local NORM_NDX=0
	local SCROLL=''
	local TAG_PAGE=0
	local TAG_NDX=0
	local X_OFF=0
	local PAGE_CHANGE=false
	
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	cursor_off

	[[ ${_LIST_DATA[CLEAR_REGION]} == 'true' ]] && sel_clear_region # Clear space around list if indicated

	LIST_X=${_LIST_DATA[X]} # First row
	BOT_X=$(( _LIST_DATA[X] + _LIST_DATA[H] - 1 )) # Last row
	X_OFF=$(( _LIST_DATA[X] - 1 )) # Cursor offset

	while true;do
		# Display decorations
		[[ ${O_COORDS[HAS_OUTER]} == 'true' ]] && msg_unicode_box ${O_COORDS[X]} ${O_COORDS[Y]} ${O_COORDS[W]} ${O_COORDS[H]} ${O_COORDS[COLOR]}
		msg_unicode_box ${I_COORDS[X]} ${I_COORDS[Y]} ${I_COORDS[W]} ${I_COORDS[H]} ${I_COORDS[COLOR]}

		# Display list decorations
		if [[ ${D_COORDS[HAS_HDR]} == 'true' ]];then
			tcup ${D_COORDS[HDR_X]} ${D_COORDS[HDR_Y]};echo $(msg_markup ${_LIST_DATA[HDR]})
		fi

		if [[ ${D_COORDS[HAS_FTR]} == 'true' ]];then
			tcup ${D_COORDS[FTR_X]} ${D_COORDS[FTR_Y]};echo $(msg_markup ${_LIST_DATA[FTR]})
		fi

		if [[ ${D_COORDS[HAS_MAP]} == 'true' ]];then
			tcup ${D_COORDS[MAP_X]} ${D_COORDS[MAP_Y]};echo $(msg_markup ${_LIST_DATA[MAP]})
		fi

		# Handle stored list position
		sel_get_position
		if [[ ${_TAG_DATA[RESTORE]} == 'true'  ]];then
			LAST_TAG=${_SELECT_TAG_FILE} # Only use position memory for differing menus unless _SAVE_MENU_POS is indicated
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: RESTORING MENU POS: _SELECT_TAG_FILE:${_SELECT_TAG_FILE}  LAST_TAG:${LAST_TAG}"
		fi

		NDX=1 # Initialize index
		if [[ ${PAGE_CHANGE} == 'false' ]];then
			if [[ ${_TAG_DATA[RESTORE]} == 'true' ]];then
				if [[ ${_SAVE_MENU_POS} == 'true' ]];then
					NDX=${_TAG_DATA[NDX]} # Restore menu position regardless
					PAGE=${_TAG_DATA[PAGE]} # Restore menu position regardless
					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:RESTORED POSITION: ${_TAG_DATA[NDX]}"
				else
					[[ ${LAST_TAG} != ${_SELECT_TAG_FILE} ]] && NDX=${_TAG_DATA[NDX]} && PAGE=${_TAG_DATA[PAGE]} # Restore menu position only if menu changed
					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:MENU CHANGED - RESTORED POSITION: ${_TAG_DATA[NDX]}"
				fi
				_TAG_DATA[RESTORE]=false
			fi
		fi

		# Populate current page array 
		sel_load_page ${PAGE} # Sets _CURRENT_PAGE
		PAGE=${_CURRENT_PAGE}

		# Add header for paging
		if [[ ${_LIST_DATA[PAGING]} == 'true' ]];then
			tcup ${_LIST_DATA[PGH_X]} ${_LIST_DATA[PGH_Y]};echo -n $(msg_markup "Page <w>${PAGE}<N> of <w>${_PAGE_TOPS[MAX]}<N> <m>${_DMD}<N> (<w>N<N>)ext (<w>P<N>)rev")
		fi

		sel_disp_page # Display list items

		_SEL_VAL=${_PAGE[${NDX}]} # Initialize return value

		sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]} # Initial item hilite

		# Get user inputs
		while true;do
			KEY=$(get_keys)
			_SEL_KEY='?'

			# Reserved application key breaks from navigation
			if [[ ${_APP_KEYS[(i)${KEY}]} -le ${#_APP_KEYS} ]];then # App key was pressed
				[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"

				_SEL_KEY=${KEY} 
				[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"

				break 2 # Quit navigation
			fi

			NAV=true # Return only menu selections

			case ${KEY} in
				0) sel_set_position ${PAGE} ${NDX}; break 2;;
				q) exit_request $(sel_set_ebox);break;;
				27) _SEL_KEY=${KEY} && return -1;;
				1|u|k) SCROLL="U";;
				2|d|j) SCROLL="D";;
				3|t|h) SCROLL="T";;
				4|b|l) SCROLL="B";;
				5|p) SCROLL="P";;
				6|n) SCROLL="N";;
				7|H) SCROLL="H";;
				8|L) SCROLL="L";;
				*) NAV=false;;
			esac

			# Handle navigation
			if [[ ${SCROLL} == 'U' ]];then
				NORM_NDX=${NDX} && ((NDX--))
				[[ ${NDX} -lt 1 ]] && NDX=${#_PAGE}
				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
			elif [[ ${SCROLL} == 'D' ]];then
				NORM_NDX=${NDX} && ((NDX++))
				[[ ${NDX} -gt ${#_PAGE} ]] && NDX=1
				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
			elif [[ ${SCROLL} == 'T' ]];then
				NORM_NDX=${NDX} && NDX=1
				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
			elif [[ ${SCROLL} == 'B' ]];then
				NORM_NDX=${NDX} && NDX=${#_PAGE}
				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
			elif [[ ${SCROLL} == 'N' ]];then
				((PAGE++))
				PAGE_CHANGE=true
				break
			elif [[ ${SCROLL} == 'P' ]];then
				[[ ${PAGE} -eq 1 ]] && PAGE=${_PAGE_TOPS[MAX]} || ((PAGE--))
				PAGE_CHANGE=true
				break
			elif [[ ${SCROLL} == 'H' ]];then
				PAGE=1
				PAGE_CHANGE=true
				break
			elif [[ ${SCROLL} == 'L' ]];then
				PAGE=${_PAGE_TOPS[MAX]}
				PAGE_CHANGE=true
				break
			fi

			if [[ ${NAV} == 'true' ]];then # Set key pressed and item selected
				_SEL_KEY=${KEY}
				_SEL_VAL=${_PAGE[${NDX}]}
			fi
		done
	done
	return 0
}

sel_set_app_keys () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _APP_KEYS:${_APP_KEYS}"

	_APP_KEYS=(${@})
}

sel_set_ebox () {
	local -A I_COORDS
	local MSG_LEN=$(( _EXIT_BOX - 4 ))
	local X_ARG=0
	local Y_ARG=0
	local W_ARG=0
	local DIFF=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	# Set coords for exit msg display
	I_COORDS=($(box_coords_get INNER_BOX))
	X_ARG=$(( I_COORDS[X] + 1 ))
	Y_ARG=$(( I_COORDS[Y] - 2 ))

	if	[[ ${I_COORDS[OB_W]} -ne 0 ]];then
		Y_ARG=$(( I_COORDS[OB_Y] + 2 ))
		W_ARG=$(( I_COORDS[OB_W] - 2 ))
	elif [[ ${MSG_LEN} -gt ${I_COORDS[W]}  ]];then
		DIFF=$(( (MSG_LEN - I_COORDS[W]) / 2 ))
		Y_ARG=$(( I_COORDS[Y] - DIFF ))
	else
		X_ARG=$(( I_COORDS[X] + 2 ))
		Y_ARG=$(( I_COORDS[Y] + 2 ))
		W_ARG=$(( I_COORDS[W] - 2 ))
	fi

	echo ${X_ARG} ${Y_ARG} ${W_ARG} 
}

sel_set_list () {
	local -a LIST=(${@})

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST=(${LIST})
}

sel_set_pages () {
	local LIST_MAX=${1}
	local LIST_HEIGHT=${2}
	local MAX_PAGE=0
	local -A PAGE_TOPS=()
	local PAGE=0
	local PG_TOP=0
	local REM=0
	local P

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	PAGE=$(( LIST_MAX / LIST_HEIGHT ))
	REM=$(( LIST_MAX % LIST_HEIGHT ))
	[[ ${REM} -ne 0 ]] && (( PAGE++ ))

	MAX_PAGE=${PAGE} # Page boundary
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: MAX_PAGE:${MAX_PAGE} PAGE:${PAGE}"

	for (( P=1; P<=PAGE; P++ ));do
		[[ ${P} -eq 1 ]] && PG_TOP=1 || PG_TOP=$(( PAGE_TOPS[$(( P-1 ))] + LIST_HEIGHT ))
		PAGE_TOPS[${P}]=${PG_TOP}
	done

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: _PAGE_TOPS:${(kv)PAGE_TOPS}"

	PAGE_TOPS[MAX]=${MAX_PAGE}

	echo ${(kv)PAGE_TOPS}
}

sel_set_position () {
	PAGE=${1}
	NDX=${2}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: NDX:${NDX}"

	[[ -n ${_SELECT_TAG_FILE} ]] && echo "${PAGE}|${NDX}" >${_SELECT_TAG_FILE} # Save menu position
	[[ -e ${_SELECT_TAG_FILE} ]] && dbg "${_SELECT_TAG_FILE} was created" || dbg "_SELECT_TAG_FILE NOT defined"
}

