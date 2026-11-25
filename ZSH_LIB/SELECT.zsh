# LIB Dependencies
_DEPS+=(ARRAY.zsh BOX.zsh CENTER.zsh MSG.zsh STR.zsh TPUT.zsh VALIDATE.zsh)

# LIB Declarations
typeset -A _CAT_COLS=()
typeset -A _SEL_LIST_META=()
typeset -A _PAGE_TOPS=()
typeset -A _TAG_DATA=()
typeset -a _APP_KEYS=()
typeset -a _LIST=()
typeset -a _PAGE=()

# LIB Constants
_EXIT_BOX=32
_HILITE=${WHITE_ON_GREY}
_PAGE_MAX_ROWS=$(( _MAX_ROWS - 15 )) # Longest list that fits the available display
_DMD="\u25C8"

# LIB Vars
_CAT_DELIM=':'
_CAT_SORT=r
_CURRENT_PAGE=0
_HAS_CAT=false
_HILITE_X=0
_REFRESH=false
_SAVE_MENU_POS=false
_SELECT_TAG_FILE="/tmp/${_MY_PID}.${_SCRIPT}_sel.state"
_SEL_KEY=''
_SEL_VAL=''
_TAG=''

# LIB Functions
sel_clear_region () {
	local FRAME=${1:=false}
	local -A RGN_COORDS
	local X_ARG=0
	local Y_ARG=0
	local W_ARG=0
	local H_ARG=0
	local DIFF=0
	local R=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	RGN_COORDS=(${(z)$(box_coords_get REGION)})

	if [[ -z ${RGN_COORDS} ]];then
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: RGN_COORDS is null - returning"
		return -1
	else
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: RGN_COORDS: ${(kv)RGN_COORDS}"
	fi

	X_ARG=${RGN_COORDS[X]}
	Y_ARG=${RGN_COORDS[Y]}
	W_ARG=${RGN_COORDS[W]}
	H_ARG=${RGN_COORDS[H]}

	local STR=$(str_rep_char " " ${W_ARG}) # Set REGION marker for debug
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: REGION COORDS: X_ARG:${X_ARG} Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"

	[[ ${FRAME} == 'true' ]] && msg_unicode_box $(( X_ARG - 1 )) $(( Y_ARG - 1 )) $(( W_ARG + 2 )) $(( H_ARG + 3 ))

	if [[ ${_DEBUG} -ge ${_MID_DBG} ]];then
		for (( R=0; R <= H_ARG; R++ ));do
			dbg "CLEARING: ROW:$(( X_ARG + R )) COL:${H_ARG} WIDTH:${W_ARG}"
			tcup $(( X_ARG + R )) ${Y_ARG} && tput ech ${W_ARG} # Clear line
			tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${WHITE_ON_GREY}${STR}${RESET} # Mark region
		done
	else
		for (( R=0; R <= H_ARG; R++ ));do
			tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${STR} # Mark region
		done
	fi
}

sel_cursor_hilite () {
	local X=${1}
	local Y=${2}
	local -a TEXT=(${3})
	local F1=""
	local F2=""

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	tcup ${X} ${Y}

	do_smso
	if [[ ${_HAS_CAT} == 'true' ]];then
		IFS="${_CAT_DELIM}" read -r F1 F2 <<< "${TEXT}"
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
		printf "${WHITE_FG}%-*s${RESET} ${_HILITE}%-*s${RESET}\n" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
	else
		echo ${TEXT}
	fi
	do_rmso

	_HILITE_X=${X}
}

sel_cursor_norm () {
	local X=${1}
	local Y=${2}
	local -a TEXT=(${3})
	local F1=""
	local F2=""

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	tcup ${X} ${Y}

	do_rmso
	if [[ ${_HAS_CAT} == 'true' ]];then
		IFS="${_CAT_DELIM}" read -r F1 F2 <<< "${TEXT}"
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
		printf "${WHITE_FG}%-*s${RESET} %-*s\n" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
	else
		echo ${TEXT}
	fi
}

sel_disp_page () {
	local NDX=0

	for (( NDX=1; NDX <= ${#_PAGE}; NDX++ ));do
		sel_cursor_norm $(( _SEL_LIST_META[X] + NDX - 1 )) ${_SEL_LIST_META[Y]} ${_PAGE[${NDX}]}
	done
}

sel_get_interior_coords () {
	local -A OB=(${(z)$(box_coords_get "OUTER_FRAME")})
	echo "Y $(( OB[Y] + 2 )) W $(( OB[W] - 4 ))" # Return interior coords and optimum width
}

sel_get_position () {
	local PAGE=0
	local NDX=0

	if [[ -e ${_SELECT_TAG_FILE} ]];then
		IFS='|' read -r PAGE NDX < ${_SELECT_TAG_FILE} # Retrieve stored position
		[[ -n ${PAGE} ]] && _TAG_DATA[PAGE]=${PAGE} || _TAG_DATA[PAGE]=''
		[[ -n ${NDX} ]] && _TAG_DATA[NDX]=${NDX} || _TAG_DATA[NDX]=''
		[[ -n ${_TAG_DATA[PAGE]} && -n ${_TAG_DATA[NDX]} ]] && _TAG_DATA[RESTORE]=true || _TAG_DATA[RESTORE]=false
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}: _TAG_DATA:${(kv)_TAG_DATA}"
	fi
}

sel_list () {
	local BASE_ROWS=8 # perimeter, frames, and headers
	local BASE_COLS=6 # perimeter, frames, and headers
	local FTR_X=0
	local FTR_Y=0
	local HDR_X=0
	local HDR_Y=0
	local IF_BOT=0
	local IF_H=0
	local IF_W=0
	local IF_X=0
	local IF_Y=0
	local LIST_H=0
	local LIST_HDR=''
	local LIST_W=0
	local MAP_X=0
	local MAP_Y=0
	local MAX_LIST_H=0
	local MAX_RGN_H=0
	local MAX_RGN_W=0
	local OF_BOT=0
	local OF_H=0
	local OF_W=0
	local OF_X=0
	local OF_Y=0
	local PAGING=false
	local LSH_Y=0
	local RGN_H=0
	local RGN_W=0
	local RGN_X_COORD=0
	local RGN_Y_COORD=0
  local LSH_X=0
	local F1=""
	local F2=""
	local L

	local -A OPTIONS=()
	local OPTION=''
	local OPTSTR=":CF:H:I:M:O:RST:W:d:s:x:y:c"
	local O
	OPTIND=0

	local CLEAR_REGION=false
	local DEC_W=0
	local FRAME_FTR=''
	local FRAME_HDR=''
	local HAS_FTR=false
	local HAS_HDR=false
	local HAS_MAP=false
	local IF_COLOR=${RESET}
	local LIST_MAP=''
	local LONG_ELEM=0
	local MAX=0
	local MAX_PAGE=0
	local MIN=0
	local OF_COLOR=${RESET}
	local OF_DEC_W=0
	local STR=''
	local VISIBLE_OUTER=false
	local X_COORD_ARG=0
	local Y_COORD_ARG=0

	_HAS_CAT=false # Reset to default on each call to sel_list

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	while getopts ${OPTSTR} OPTION;do
		case ${OPTION} in
			C) _HAS_CAT=true;;
			F) HAS_FTR=true;FRAME_FTR=${OPTARG};;
			H) HAS_HDR=true;FRAME_HDR=${OPTARG};;
			I) IF_COLOR=${OPTARG};;
			M) HAS_MAP=true;LIST_MAP=${OPTARG};;
			O) VISIBLE_OUTER=true;OF_COLOR=${OPTARG};;
			R) _REFRESH=true;;
			S) _SAVE_MENU_POS=true;;
			T) _TAG=${OPTARG};;
			W) OF_DEC_W=${OPTARG};;
			c) CLEAR_REGION=true;;
			d) _CAT_DELIM=${OPTARG};;
			s) _CAT_SORT=${OPTARG};;
			x) X_COORD_ARG=${OPTARG};;
			y) Y_COORD_ARG=${OPTARG};;
			:) exit_leave "${RED_FG}${0}${RESET}: option: -${OPTARG} requires an argument";;
			\?) exit_leave "${RED_FG}${0}${RESET}: unknown option -${OPTARG}";;
		esac
		OPTIONS[${OPTION}]=${(qqq)OPTARG}
	done
	shift $(( OPTIND - 1 ))

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: echo "\\n${WHITE_FG}OPTIONS${RESET}\\n" $(for O in ${(k)OPTIONS};do echo "Option:-${O} ${OPTIONS[${O}]}";done)"

	_TAG=$(str_no_ansi "${_TAG}") # Clean tag

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: _REFRESH:${_REFRESH}"

	if [[ -z ${_SEL_LIST_META} || ${_REFRESH} == 'true' ]];then # IMPORTANT: _LIST changes must set REFRESH to be seen
		_REFRESH=false # Reset
		[[ ${#_LIST} -gt 100 ]] && msg_box -x1 -y1 -c "<w>Building select list...<N>"

		if [[ -n ${_TAG}  ]];then
			_SELECT_TAG_FILE="/tmp/${_MY_PID}.${_TAG}.state"
		fi

		# 1: based on passed X,Y for top left list placement
		# 2: the length and width of the list establish the height,width of the inner box
		# 3: outer box height based on inner box, width bassed on list and decorations
		# 6. Variants & decoraations - there is a vertical stack order from top to bottom: 
		# 1.  region perimeter (optional frame header)
		# 2.    outer frame
		# 3.     list header
		# 4.      list frame
		# 5.      list
		# 6.      list frame
		# 7.     (optional map line)
		# 8.    outer frame
		# 9.   (optional footer below)
		# 10. region perimeter
		
		# List header
		LIST_HDR="Page <w>${_PAGE_TOPS[MAX]}<N> of <w>${_PAGE_TOPS[MAX]}<N> ${_DMD} (<w>N<N>)ext (<w>P<N>)rev" # Create paging template

		# List dimensions
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: Setting LIST height -> _LIST ITEMS:${#_LIST}"
		if [[ ${#_LIST} -gt ${_PAGE_MAX_ROWS} ]];then
			LIST_H=${_PAGE_MAX_ROWS}
			[[ ${HAS_MAP} == 'false' ]] && HAS_MAP=true && LIST_MAP="Press N or P to Navigate list"
		else
			LIST_H=${#_LIST}
		fi
		_PAGE_TOPS=($(sel_set_pages ${#_LIST} ${LIST_H})) # Create table of page top indexes
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: #_LIST:${_#LIST} LIST_H:${LIST_H}"

		LIST_W=$(arr_long_elem_len ${_LIST})
		[[ ${_HAS_CAT} == 'true' ]] && (( LIST_W += 5 )) || (( LIST_W += 2 )) 
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: LIST_W:${LIST_W}"

		# Find widest decoration
		[[ ${HAS_HDR} == 'true' ]] && DEC_W="${#$(msg_nomarkup ${FRAME_HDR})}"
		[[ ${HAS_FTR} == 'true' && "${#$(msg_nomarkup ${FRAME_FTR})}" -gt ${DEC_W} ]] && DEC_W="${#$(msg_nomarkup ${FRAME_FTR})}"
		[[ ${HAS_MAP} == 'true' && "${#$(msg_nomarkup ${LIST_MAP})}" -gt ${DEC_W} ]] && DEC_W="${#$(msg_nomarkup ${LIST_MAP})}"
		[[ ${LIST_W} -gt ${DEC_W} ]] && DEC_W=${LIST_W}
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: DEC_W:${DEC_W}"

		# Set field widths for lists having categories
		if [[ ${_HAS_CAT} == 'true' ]];then
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CATEGORIES DETECTED"
			for L in ${_LIST};do
				IFS="${_CAT_DELIM}" read -r F1 F2 <<< "${L}"
				[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
				[[ ${#F1} -gt ${_CAT_COLS[1]} ]] && _CAT_COLS[1]=${#F1}
				[[ ${#F2} -gt ${_CAT_COLS[2]} ]] && _CAT_COLS[2]=${#F2}
			done
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SET category field widths: F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
			case ${_CAT_SORT} in
				r) _LIST=(${(O)_LIST});; # Descending categories
				a) _LIST=(${(o)_LIST});; # Ascending categories
				n) _LIST=(${_LIST});; # No sorting of categories
			esac
		else
			_CAT_COLS=()
		fi

		# Set region 
		RGN_W=$(( BASE_COLS + DEC_W ))
		RGN_H=$(( BASE_ROWS + LIST_H ))
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: RGN_W:${RGN_W} RGN_H:${RGN_H}"

		[[ ${X_COORD_ARG} -ge 1 ]] && RGN_X_COORD=${X_COORD_ARG} || RGN_X_COORD=$(center -V -h${RGN_H}) # Widget placement
		[[ ${Y_COORD_ARG} -ge 1 ]] && RGN_Y_COORD=${Y_COORD_ARG} || RGN_Y_COORD=$(center -H -w${RGN_W}) # Widget placement
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: RGN_X_COORD:${RGN_X_COORD} RGN_Y_COORD:${RGN_Y_COORD}"

		# Store REGION coords
		box_coords_set REGION X ${RGN_X_COORD} Y ${RGN_Y_COORD} W ${RGN_W} H ${RGN_H}
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: REGION X ${RGN_X_COORD} Y ${RGN_Y_COORD} W ${RGN_W} H ${RGN_H}"

		# Set outer
		OF_X=$(( RGN_X_COORD + 1 )) # Down past header
		OF_W=$(( DEC_W + 6 )) # Widest decoration plus gutter
		[[ ${OF_W} -lt ${_EXIT_BOX} ]] && OF_W=$(( _EXIT_BOX + 2 ))  # Minimum width is sufficient to enclose exit box prompt
		OF_Y=$(center -Y -c"$(box_coords_get "REGION")" -w${OF_W}) # Left side
		OF_H=$(( RGN_H - 2 )) # Up past map
		OF_BOT=$(( OF_X + OF_H - 1 ))

		# Store OUTER coords
		box_coords_set OUTER_FRAME X ${OF_X} Y ${OF_Y} W ${OF_W} H ${OF_H} VISIBLE ${VISIBLE_OUTER} C ${OF_COLOR} 
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: OUTER_FRAME X ${OF_X} Y ${OF_Y} W ${OF_W} H ${OF_H} VISIBLE ${VISIBLE_OUTER} C ${OF_COLOR}"

		# Set inner
		IF_X=$(( RGN_X_COORD + 3 )) # Inner top
		IF_W=${LIST_W}
		IF_Y=$(center -Y -c"$(box_coords_get "OUTER_FRAME")" -w${IF_W}) # Left side
		IF_H=$(( LIST_H + 2 ))
		IF_BOT=$(( IF_X + IF_H - 1 ))

		# Store INNER coords
		box_coords_set INNER_FRAME X ${IF_X} Y ${IF_Y} W ${IF_W} H ${IF_H} C ${IF_COLOR}
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: INNER_FRAME X ${IF_X} Y ${IF_Y} W ${IF_W} H ${IF_H} C ${IF_COLOR}"

		# Set coords for list decorations
		LSH_X=$(( IF_X - 1 ))
		LSH_Y=$(center -Y -c"$(box_coords_get "OUTER_FRAME")" -w"${#$(msg_nomarkup ${LIST_HDR})}")
		[[ ${HAS_HDR} == 'true' ]] && HDR_X=${RGN_X_COORD} || HDR_X=0
		[[ ${HAS_HDR} == 'true' ]] && HDR_Y=$(center -Y -c"$(box_coords_get "REGION")" -w"${#$(msg_nomarkup ${FRAME_HDR})}") || HDR_Y=0
		[[ ${HAS_MAP} == 'true' ]] && MAP_X=$(( OF_BOT - 1 )) || MAP_X=0
		[[ ${HAS_MAP} == 'true' ]] && MAP_Y=$(center -Y -c"$(box_coords_get "OUTER_FRAME")" -w"${#$(msg_nomarkup ${LIST_MAP})}") || MAP_Y=0
		[[ ${HAS_FTR} == 'true' ]] && FTR_X=$(( OF_BOT + 1 )) || FTR_X=0
		[[ ${HAS_FTR} == 'true' ]] && FTR_Y=$(center -Y -c"$(box_coords_get "REGION")" -w"${#$(msg_nomarkup ${FRAME_FTR})}") || FTR_Y=0

		# Store DECOR coords
		box_coords_set DECOR HAS_HDR ${HAS_HDR} HDR_X ${HDR_X} HDR_Y ${HDR_Y} HAS_MAP ${HAS_MAP} MAP_X ${MAP_X} MAP_Y ${MAP_Y} HAS_FTR ${HAS_FTR} FTR_X ${FTR_X} FTR_Y ${FTR_Y}
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: DECOR HAS_HDR ${HAS_HDR} HDR_X ${HDR_X} HDR_Y ${HDR_Y} HAS_MAP ${HAS_MAP} MAP_X ${MAP_X} MAP_Y ${MAP_Y} HAS_FTR ${HAS_FTR} FTR_X ${FTR_X} FTR_Y ${FTR_Y}"

		# Save list meta data
		_SEL_LIST_META[IF_W]=${IF_W}
		_SEL_LIST_META[IF_Y]=${IF_Y}
		_SEL_LIST_META[CLEAR_REGION]=${CLEAR_REGION}
		_SEL_LIST_META[FTR]=${FRAME_FTR}
		_SEL_LIST_META[HDR]=${FRAME_HDR}
		_SEL_LIST_META[H]=${LIST_H}
		_SEL_LIST_META[MAP]=${LIST_MAP}
		_SEL_LIST_META[PAGING]=${PAGING} # Seems unused
		_SEL_LIST_META[LSH_X]=${LSH_X}
		_SEL_LIST_META[LSH_Y]=${LSH_Y}
		_SEL_LIST_META[X]=$(( IF_X + 1 ))
		_SEL_LIST_META[Y]=$(( IF_Y + 1 ))

		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}:\n${WHITE_ON_GREY}_SEL_LIST_META${RESET}\n$(for L in ${(k)_SEL_LIST_META};do echo "${L} -> ${_SEL_LIST_META[${L}]}";done)\n---\n"
	fi

	msg_box_clear

	sel_scroll # Display list and handle user inputs
}

sel_load_page () {
	local PAGE=${1}
	local NDX=0
	local TOP_ROW=1

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	# Evaluate/validate PAGE arg
	if [[ -n ${_PAGE_TOPS[${PAGE}]} ]];then
		TOP_ROW=${_PAGE_TOPS[${PAGE}]}
	else
		TOP_ROW=1
		PAGE=1
	fi
	 
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: TOP_ROW:${TOP_ROW}"

	_PAGE=()
	for (( NDX=1; NDX <= _SEL_LIST_META[H]; NDX++ ));do
		[[ -z ${_LIST[$(( NDX + TOP_ROW - 1 ))]} ]] && continue # No blank rows
		_PAGE+=${_LIST[$(( NDX + TOP_ROW - 1 ))]}
		[[ ${NDX} -eq ${#_LIST} ]] && break
	done
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ADDED NDX ROWS"
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: _LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE} PAGE:${PAGE}"

	_CURRENT_PAGE=${PAGE} # Set the currently displayed page
}

sel_scroll () {
	local PAGE=1
	local -A D_COORDS=(${(z)$(box_coords_get DECOR)})
	local -A I_COORDS=(${(z)$(box_coords_get INNER_FRAME)})
	local -A O_COORDS=(${(z)$(box_coords_get OUTER_FRAME)})
	local BOT_X=0
	local KEY=''
	local BOX_TAG=?
	local LIST_X=0
	local NAV=''
	local NDX=0
	local NORM_NDX=0
	local LSH_Y=0
	local PAGE_CHANGE=false
	local SCROLL=''
	local TAG_NDX=0
	local TAG_PAGE=0
	local X_OFF=0
	
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	cursor_off

	[[ ${_SEL_LIST_META[CLEAR_REGION]} == 'true' ]] && sel_clear_region # Clear space around list if indicated

	LIST_X=${_SEL_LIST_META[X]} # First row
	BOT_X=$(( _SEL_LIST_META[X] + _SEL_LIST_META[H] - 1 )) # Last row
	X_OFF=$(( _SEL_LIST_META[X] - 1 )) # Cursor offset

	stty -echo
	while true;do
		# Display decorations
		if [[ ${O_COORDS[VISIBLE]} == 'true' ]];then # Display OUTER frame?
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: OUTER COORDS: O_COORDS[X]:${O_COORDS[X]} O_COORDS[Y]:${O_COORDS[Y]} O_COORDS[W]:${O_COORDS[W]} O_COORDS[H]:${O_COORDS[H]}"
			msg_unicode_box ${O_COORDS[X]} ${O_COORDS[Y]} ${O_COORDS[W]} ${O_COORDS[H]} ${O_COORDS[C]} # Outer box
		fi

		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: INNER COORDS: I_COORDS[X]:${I_COORDS[X]} I_COORDS[Y]:${I_COORDS[Y]} I_COORDS[W]:${I_COORDS[W]} I_COORDS[H]:${I_COORDS[H]}"
		msg_unicode_box ${I_COORDS[X]} ${I_COORDS[Y]} ${I_COORDS[W]} ${I_COORDS[H]} ${I_COORDS[C]} # Inner box

		# Display list decorations
		if [[ ${D_COORDS[HAS_HDR]} == 'true' ]];then
			tcup ${D_COORDS[HDR_X]} ${D_COORDS[HDR_Y]};echo $(msg_markup ${_SEL_LIST_META[HDR]})
		fi

		if [[ ${D_COORDS[HAS_FTR]} == 'true' ]];then
			tcup ${D_COORDS[FTR_X]} ${D_COORDS[FTR_Y]};echo $(msg_markup ${_SEL_LIST_META[FTR]})
		fi

		if [[ ${D_COORDS[HAS_MAP]} == 'true' ]];then
			tcup ${D_COORDS[MAP_X]} ${D_COORDS[MAP_Y]};echo $(msg_markup ${_SEL_LIST_META[MAP]})
		fi

		# Handle list position
		sel_get_position
		if [[ ${_TAG_DATA[RESTORE]} == 'true'  ]];then
			BOX_TAG=${_SELECT_TAG_FILE} # Maintain cursor position if _SAVE_MENU_POS is set
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: RESTORING MENU POS: _SELECT_TAG_FILE:${_SELECT_TAG_FILE}  BOX_TAG:${BOX_TAG}"
		fi

		NDX=1 # Initialize index
		if [[ ${PAGE_CHANGE} == 'false' ]];then
			if [[ ${_TAG_DATA[RESTORE]} == 'true' ]];then
				if [[ ${_SAVE_MENU_POS} == 'true' ]];then
					NDX=${_TAG_DATA[NDX]} # Restore list position regardless
					PAGE=${_TAG_DATA[PAGE]} # Restore list position regardless
					[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}:RESTORED POSITION: ${_TAG_DATA[NDX]}"
				else
					[[ ${BOX_TAG} != ${_SELECT_TAG_FILE} ]] && NDX=${_TAG_DATA[NDX]} && PAGE=${_TAG_DATA[PAGE]} # Restore list position only if list changed
					[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}:MENU CHANGED - RESTORED POSITION: ${_TAG_DATA[NDX]}"
				fi
				_TAG_DATA[RESTORE]=false
			fi
		fi

		# Populate current page array 
		sel_load_page ${PAGE} # Sets _CURRENT_PAGE
		PAGE=${_CURRENT_PAGE}

		# Add header for paging
		if [[ ${_SEL_LIST_META[PAGING]} == 'true' ]];then
			tcup ${_SEL_LIST_META[LSH_X]} ${_SEL_LIST_META[LSH_Y]};echo -n $(msg_markup "Page <w>${PAGE}<N> of <w>${_PAGE_TOPS[MAX]}<N> <m>${_DMD}<N> (<w>N<N>)ext (<w>P<N>)rev")
		else
			LIST_HDR="Showing <w>${#_LIST}<N> ${(C)$(str_pluralize item ${#_LIST})}"
			LSH_Y=$(center -Y -c"$(box_coords_get "OUTER_FRAME")" -w"${#$(msg_nomarkup ${LIST_HDR})}" -y1)
			tcup ${_SEL_LIST_META[LSH_X]} ${LSH_Y};echo -n $(msg_markup ${LIST_HDR}) 
		fi

		sel_disp_page # Display list items

		_SEL_VAL=${_PAGE[${NDX}]} # Initialize return value

		sel_cursor_hilite $(( NDX + X_OFF )) ${_SEL_LIST_META[Y]} ${_PAGE[${NDX}]} # Initial item hilite

		# Get user inputs
		while true;do
			KEY=$(get_keys)
			_SEL_KEY='?'

			# Reserved application key breaks from navigation
			if [[ ${_APP_KEYS[(i)${KEY}]} -le ${#_APP_KEYS} ]];then # App key was pressed
				[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"

				_SEL_KEY=${KEY} 
				[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"

				sel_set_position ${PAGE} ${NDX}
				break 2 # Quit navigation
			fi

			NAV=true # Return only list selections

			case ${KEY} in
				0) sel_set_position ${PAGE} ${NDX}; break 2;;
				q) exit_request $(sel_set_ebox);break;;
				s) sel_show_keys; break;;
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
			if [[ ${SCROLL} == 'U' ]];then # Up
				NORM_NDX=${NDX} && ((NDX--))
				[[ ${NDX} -lt 1 ]] && NDX=${#_PAGE}
				sel_cursor_norm $(( NORM_NDX + X_OFF )) ${_SEL_LIST_META[Y]} ${_PAGE[${NORM_NDX}]}
				sel_cursor_hilite $(( NDX + X_OFF )) ${_SEL_LIST_META[Y]} ${_PAGE[${NDX}]}
			elif [[ ${SCROLL} == 'D' ]];then # Down
				NORM_NDX=${NDX} && ((NDX++))
				[[ ${NDX} -gt ${#_PAGE} ]] && NDX=1
				sel_cursor_norm $(( NORM_NDX + X_OFF )) ${_SEL_LIST_META[Y]} ${_PAGE[${NORM_NDX}]}
				sel_cursor_hilite $(( NDX + X_OFF )) ${_SEL_LIST_META[Y]} ${_PAGE[${NDX}]}
			elif [[ ${SCROLL} == 'T' ]];then # Top
				NORM_NDX=${NDX} && NDX=1
				sel_cursor_norm $(( NORM_NDX + X_OFF )) ${_SEL_LIST_META[Y]} ${_PAGE[${NORM_NDX}]}
				sel_cursor_hilite $(( NDX + X_OFF )) ${_SEL_LIST_META[Y]} ${_PAGE[${NDX}]}
			elif [[ ${SCROLL} == 'B' ]];then # Bot
				NORM_NDX=${NDX} && NDX=${#_PAGE}
				sel_cursor_norm $(( NORM_NDX + X_OFF )) ${_SEL_LIST_META[Y]} ${_PAGE[${NORM_NDX}]}
				sel_cursor_hilite $(( NDX + X_OFF )) ${_SEL_LIST_META[Y]} ${_PAGE[${NDX}]}
			elif [[ ${SCROLL} == 'N' ]];then # Next Page
				((PAGE++))
				PAGE_CHANGE=true
				break
			elif [[ ${SCROLL} == 'P' ]];then # Previous Page
				[[ ${PAGE} -eq 1 ]] && PAGE=${_PAGE_TOPS[MAX]} || ((PAGE--))
				PAGE_CHANGE=true
				break
			elif [[ ${SCROLL} == 'H' ]];then # Top
				PAGE=1
				PAGE_CHANGE=true
				break
			elif [[ ${SCROLL} == 'L' ]];then # Bot
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
	stty echo

	return 0
}

sel_set_app_keys () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	_APP_KEYS=(${@})
}

sel_set_ebox () {
	local -A COORDS=(${(z)$(box_coords_get OUTER_FRAME)})
	local Y=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	Y=$(center -Y -c"${(kv)COORDS}" -w${_EXIT_BOX}) # Left side

	echo $(( COORDS[X] + 1 ))  ${Y} ${_EXIT_BOX} 
}

sel_set_list () {
	_LIST=(${@})
	_LIST=(${(o)_LIST})

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"
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

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	PAGE=$(( LIST_MAX / LIST_HEIGHT ))
	REM=$(( LIST_MAX % LIST_HEIGHT ))
	[[ ${REM} -ne 0 ]] && (( PAGE++ ))

	MAX_PAGE=${PAGE} # Page boundary
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: MAX_PAGE:${MAX_PAGE} PAGE:${PAGE}"

	for (( P=1; P<=PAGE; P++ ));do
		[[ ${P} -eq 1 ]] && PG_TOP=1 || PG_TOP=$(( PAGE_TOPS[$(( P-1 ))] + LIST_HEIGHT ))
		PAGE_TOPS[${P}]=${PG_TOP}
	done

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: _PAGE_TOPS:${(kv)PAGE_TOPS}"

	PAGE_TOPS[MAX]=${MAX_PAGE}

	echo ${(kv)PAGE_TOPS}
}

sel_set_position () {
	local PAGE=${1}
	local NDX=${2}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: _SELECT_TAG_FILE:${_SELECT_TAG_FILE} PAGE:${PAGE}: NDX:${NDX}"

	[[ -n ${_SELECT_TAG_FILE} ]] && echo "${PAGE}|${NDX}" >${_SELECT_TAG_FILE} # Save list position
	[[ -e ${_SELECT_TAG_FILE} ]] && dbg "${_SELECT_TAG_FILE} was created" || dbg "_SELECT_TAG_FILE NOT found"
}

sel_show_keys () {
	local -a KEY_LIST=()

	KEY_LIST=(
		"q   -> Exit"
		"Esc -> Cancel"
		"u/k -> Up 1 Line"
		"d/j -> Down 1 Line"
		"t/h -> Top of List"
		"b/l -> Bottom of List"
		"p   -> Previous Page"
		"n   -> Next Page"
		"H   -> First Page"
		"L   -> Last Page"
	)

	msg_box -H1 -p -PK "Menu Navigation Keys| |$(msg_list_bullet ${KEY_LIST})|<Z>|<L>NumPad/Arrow keys"
}

