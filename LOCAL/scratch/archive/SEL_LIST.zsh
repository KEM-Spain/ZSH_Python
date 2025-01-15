# LIB Dependencies
_DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh STR.zsh TPUT.zsh UTILS.zsh"

# LIB Declarations
typeset -A _COL_WIDTHS=()
typeset -A _SEL_MENU_COORDS=()
typeset -A _PAGE_TOPS=()
typeset -a _APP_KEYS=()
typeset -a _CENTER_COORDS=()
typeset -a _SEL_LIST=()
typeset -a _SEL_LIST_TEXT=()

# LIB Vars
	_CUR_PAGE=1
	_HILITE=${WHITE_ON_GREY}
	_HILITE_X=0
	_MAX_PAGE=0
	_PAGE_OPTION_KEY_HELP=''
	_SEL_KEY=?
	_SEL_LIST_HDR=''
	_SEL_LIST_LIB_DBG=3
	_SEL_LIST_RESTORE=true
	_SEL_VAL=?
	_SL_CATEGORY=false
	_SL_MAX_ITEM_LEN=0
	_TITLE_HL=${WHITE_ON_GREY}

# TODO: Possible enhancement: create state file for every list and restore state if redisplayed
# TODO: allowing a chain of lists to maintain state across invocations.
# TODO: Assign each list an ID comprised of process id and coord tag
# Functions
sel_list () {
	local -A SKEYS
	local -a SLIST
	local MAX_NDX=${#_SEL_LIST}

	local BOUNDARY_SET=false
	local BOX_BOT=0
	local BOX_HEIGHT=$(( MAX_NDX + 2 ))
	local BOX_NDX=0
	local BOX_PARTIAL=0
	local BOX_ROW=0
	local BOX_TOP=0
	local BOX_WIDTH=0
	local BOX_X=0
	local BOX_X_COORD=0
	local BOX_Y=0
	local BOX_Y_COORD=0
	local CENTER_Y=0
	local CLEAN_TEXT=''
	local CURSOR_NDX=0
	local CURSOR_ROW=0
	local DIR=''
	local F1='' F2=''
	local GUIDE=false
	local GUIDE_OFFSET=2
	local GUIDE_ROW=0
	local GUIDE_ROWS=1
	local KEY=''
	local LAST_NDX=0
	local LAST_ROW=0
	local LINE=''
	local LIST_BOT=0
	local LIST_NDX=0
	local LIST_TOP=0
	local LONGEST=0
	local MAX_BOX=0
	local MAX_X_COORD=$(( _MAX_ROWS -5 )) # Up from bottom 
	local OPTION=''
	local OPTSTR=''
	local OPT_KEY_ROW=0
	local PG_BOT=0
	local PG_TOP=0
	local REM=''
	local ROWS_OUT=0
	local SX SY SW SH SL
	local TITLE=''
	local TOP_SET=false
	local XPAD=2
	local YPAD=6
	local _SORT_KEY=false
	local L P Q 

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	OPTSTR=":x:y:cr:w:O:I:s"
	OPTIND=0

	local ITEM_PAD=2
	local ROW_ARG=0
	local INNER_BOX_COLOR=${RESET}
	local OUTER_BOX_COLOR=${RESET}
	local X_COORD_ARG=0
	local Y_COORD_ARG=0

	_SL_CATEGORY=false
	_SORT_KEY=false

	while getopts ${OPTSTR} OPTION;do
		case $OPTION in
	   O) OUTER_BOX_COLOR=${OPTARG};;
	   I) INNER_BOX_COLOR=${OPTARG};;
	   c) _SL_CATEGORY=true;;
	   r) ROW_ARG=${OPTARG};;
	   s) _SORT_KEY=true;;
	   w) ITEM_PAD=${OPTARG};;
	   x) X_COORD_ARG=${OPTARG};;
	   y) Y_COORD_ARG=${OPTARG};;
	   :) exit_leave "${RED_FG}${0}${RESET}: option: -${OPTARG} requires an argument";;
	  \?) exit_leave "${RED_FG}${0}${RESET}: unknown option -${OPTARG}";;
		esac
	done
	shift $(( OPTIND - 1 ))

	cursor_off

	if [[ ${_SORT_KEY} == 'true' ]];then
		for L in ${_SEL_LIST};do
			SKEYS+=$(cut -d':' -f1 <<<${L})
			SLIST+=$(cut -d':' -f2- <<<${L})
		done
		_SEL_LIST=(${SLIST})
	fi

	if [[ -z ${_SEL_LIST} ]];then
		exit_leave "_SEL_LIST is unset"
	else
		if [[ ${_SL_MAX_ITEM_LEN} -eq 0 ]];then
			_SL_MAX_ITEM_LEN=$(arr_long_elem_len ${_SEL_LIST}); (( _SL_MAX_ITEM_LEN++ )) # 1 char pad
			_SL_MAX_ITEM_LEN=$(( _SL_MAX_ITEM_LEN + ITEM_PAD ))
		fi
		BOX_WIDTH=$(( _SL_MAX_ITEM_LEN + 2 ))
	fi

	[[ ${MAX_X_COORD} -lt ${BOX_HEIGHT} ]] && BOX_HEIGHT=$(( MAX_X_COORD - 10 )) # Long list

	CLEAN_TEXT=$(msg_nomarkup ${TITLE})
	[[ ${#CLEAN_TEXT} -gt ${LONGEST} ]] && LONGEST=${#CLEAN_TEXT} # Find widest element for box width

	CLEAN_TEXT=$(msg_nomarkup ${_PAGE_OPTION_KEY_HELP})
	[[ ${#CLEAN_TEXT} -gt ${LONGEST} ]] && LONGEST=${#CLEAN_TEXT}

	[[ ${LONGEST} -lt ${_SL_MAX_ITEM_LEN} ]] && SW=$(( _SL_MAX_ITEM_LEN+2 )) || SW=$(( LONGEST+2 ))

	[[ ${X_COORD_ARG} -gt 0 ]] && BOX_X_COORD=${X_COORD_ARG} || BOX_X_COORD=$(coord_center $(( _MAX_ROWS )) ${BOX_HEIGHT})
	[[ ${Y_COORD_ARG} -gt 0 ]] && BOX_Y_COORD=${Y_COORD_ARG} || BOX_Y_COORD=$(coord_center $(( _MAX_COLS )) ${SW})

	SX=$(( BOX_X_COORD-XPAD ))
	SY=$(( BOX_Y_COORD-YPAD ))
	SW=$(( YPAD * 2 + SW ))
	SH=$(( XPAD * 2 + BOX_HEIGHT ))

	[[ $(( SW % 2 )) -ne 0 ]] && (( SW++ )) # Even width cols
	[[ $(( BOX_WIDTH % 2 )) -ne 0 ]] && (( BOX_WIDTH++ )) # Even width cols
	box_coords_set INNER_BOX X ${BOX_X_COORD} Y ${CENTER_Y} W ${BOX_WIDTH} H ${BOX_HEIGHT}

	SL=$(( SX+BOX_HEIGHT + (XPAD * 2) - 1 )) # Loop limit

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: BOX_X_COORD:${BOX_X_COORD} BOX_Y_COORD:${BOX_Y_COORD} BOX_WIDTH:${BOX_WIDTH} BOX_HEIGHT:${BOX_HEIGHT} XPAD:${XPAD} YPAD:${YPAD}"
	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SX:${SX}->SL:${SL}, SY:${SY}->SW:${SW}"

	# Clear space around list
	for (( L=SX; L<=SL; L++ ));do
		tput cup ${L} ${SY};tput ech ${SW}
	done

	# Set boundaries
	if [[ ${BOUNDARY_SET} == 'false' ]];then
		[[ ${BOX_HEIGHT} -lt ${MAX_NDX} ]] && MAX_BOX=$(( BOX_HEIGHT - XPAD )) || MAX_BOX=${MAX_NDX} # Set box boundary
		_MAX_PAGE=$(( ${#_SEL_LIST} / MAX_BOX ))
		REM=$(( ${#_SEL_LIST} % MAX_BOX ))
		[[ ${REM} -ne 0 ]] && (( _MAX_PAGE++ )) && BOX_PARTIAL=${REM}

		for (( P=1; P<=_MAX_PAGE; P++ ));do
			[[ ${P} -eq 1 ]] && PG_TOP=1 || PG_TOP=$(( _PAGE_TOPS[$(( P-1 ))] + MAX_BOX ))
			_PAGE_TOPS[${P}]=${PG_TOP}
		done

		# Extend box height if 2 guide info rows are needed
		[[ ${_MAX_PAGE} -gt 1 && -n ${_PAGE_OPTION_KEY_HELP} ]] && (( SH++ )) && GUIDE_ROWS=2 && GUIDE_OFFSET=3

		# Outer box w/ title
		[[ -n ${_SEL_LIST_HDR} ]] && tput cup $((SX-1)) $(coord_center $(( _MAX_COLS )) ${#_SEL_LIST_HDR});echo -n ${BOLD}${(C)_SEL_LIST_HDR}${RESET}

		msg_unicode_box ${SX} ${SY} ${SW} ${SH} ${OUTER_BOX_COLOR} # OUTER box
		box_coords_set OUTER_BOX X ${SX} Y ${SY} W ${SW} H ${SH}

		CLEAN_TEXT=$(msg_nomarkup ${TITLE})
		tput cup $(( SX+1 )) $(( SY+(SW/2)-(${#CLEAN_TEXT}/2) ));echo $(msg_markup ${TITLE})

		GUIDE_ROW=$(( ${SX}+${SH} - ${GUIDE_OFFSET} ))

		# Option key guide
		if [[ -n ${_PAGE_OPTION_KEY_HELP} ]];then
			CLEAN_TEXT=$(msg_nomarkup ${_PAGE_OPTION_KEY_HELP})
			[[ ${GUIDE_ROWS} -eq 2 ]] && OPT_KEY_ROW=$(( GUIDE_ROW+1 )) || OPT_KEY_ROW=${GUIDE_ROW}
			tput cup ${OPT_KEY_ROW} $(( SY+(SW/2)-(${#CLEAN_TEXT}/2) ));echo $(msg_markup ${_PAGE_OPTION_KEY_HELP})
		fi

		BOUNDARY_SET=true
	fi

	# Save box coords
	box_coords_set MSG_BOX X ${SX} Y ${SY} W ${SW} H ${SH}

	# Initialize
	_SEL_LIST_TEXT=()
	CENTER_Y=$(( SY+(SW/2) - (BOX_WIDTH/2) )) # New Y to center list
	BOX_X=$(( BOX_X_COORD + 1 ))
	BOX_Y=$(( CENTER_Y + 1 ))
	BOX_TOP=${BOX_X}
	BOX_BOT=0
	LIST_NDX=0
	LIST_TOP=1
	LIST_BOT=0
	LAST_NDX=0
	LAST_ROW=0

 # Record page tops
	for P in ${(onk)_PAGE_TOPS};do
		Q=$(( P + 1 ))
		[[ -n ${_PAGE_TOPS[${Q}]} ]] && PG_BOT=${_PAGE_TOPS[${Q}]} || PG_BOT=${MAX_NDX}
		if [[ ${ROW_ARG} -ge ${_PAGE_TOPS[${P}]} && ${ROW_ARG} -le ${PG_BOT} ]];then
			LIST_TOP=${_PAGE_TOPS[${P}]}
			TOP_SET=true
			break
		fi
	done

	# Save box coords
	box_coords_set INNER_BOX X ${BOX_X_COORD} Y ${CENTER_Y} W ${BOX_WIDTH} H ${BOX_HEIGHT}

	# Display list
	while true;do
		BOX_ROW=${BOX_X}
		BOX_NDX=1
		msg_unicode_box ${BOX_X_COORD} ${CENTER_Y} ${BOX_WIDTH} ${BOX_HEIGHT} ${INNER_BOX_COLOR} # Display INNER box for list

	 # Set column widths for lists having categories
		if [[ ${_SL_CATEGORY} == 'true' ]];then
			for L in ${_SEL_LIST};do
				F1=$(cut -d: -f1 <<<${L})
				F2=$(cut -d: -f2 <<<${L})
				[[ ${#F1} -gt ${_COL_WIDTHS[1]} ]] && _COL_WIDTHS[1]=${#F1}
				[[ ${#F2} -gt ${_COL_WIDTHS[2]} ]] && _COL_WIDTHS[2]=${#F2}
			done
		fi

		# Paging key guide
		if [[ ${_MAX_PAGE} -gt 1 ]];then
			tput cup ${GUIDE_ROW} ${BOX_Y}
			printf "${CYAN_FG}Page:${WHITE_FG}%-2d ${CYAN_FG}of ${WHITE_FG}%d %s${RESET}\n" ${_CUR_PAGE} ${_MAX_PAGE} "(n)ext (p)rev"
			_SEL_LIST_TEXT="${GUIDE_ROW}|${BOX_Y}|$(printf "${CYAN_FG}Page:${WHITE_FG}%-2d ${CYAN_FG}of ${WHITE_FG}%d %s${RESET}\n" ${_CUR_PAGE} ${_MAX_PAGE} "(n)ext (p)rev")"
		fi

		# Generate list
		ROWS_OUT=0
		for (( LIST_NDX=LIST_TOP; LIST_NDX<=MAX_NDX; LIST_NDX++ ));do
			[[ $(( BOX_NDX++ )) -gt ${MAX_BOX} ]] && break # Increments BOX_NDX, break when page is full

			tput cup ${BOX_ROW} ${BOX_Y}
			[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: POSITIONING CURSOR: ROW:${BOX_ROW} COL:${BOX_Y}"

			if [[ ${BOX_ROW} -eq ${BOX_X} ]];then
				tput smso && _HILITE_X=${BOX_X}
			else
				tput rmso # Highlight first item
			fi

			if [[ ${_SL_CATEGORY} == 'true' ]];then
				F1=$(sel_list_get_cat ${LIST_NDX})
				F2=$(sel_list_get_label ${LIST_NDX})
				_HILITE=''
				printf "${WHITE_FG}%-*s${RESET} ${_HILITE}%-*s${RESET}\n" ${_COL_WIDTHS[1]} ${F1} ${_COL_WIDTHS[2]} ${F2}
				_SEL_LIST_TEXT+="${BOX_ROW}|${BOX_Y}|$(printf "${WHITE_FG}%-*s${RESET} ${_HILITE}%-*s${RESET}\n" ${_COL_WIDTHS[1]} ${F1} ${_COL_WIDTHS[2]} ${F2})"
			else
				echo ${_SEL_LIST[${LIST_NDX}]}
				_SEL_LIST_TEXT+="${BOX_ROW}|${BOX_Y}|${_SEL_LIST[${LIST_NDX}]}"
			fi

			(( BOX_ROW++ ))
			(( ROWS_OUT++ ))
		done
		_HILITE=${_TITLE_HL}

		LIST_BOT=$(( LIST_NDX - 1 ))
		[[ ${ROWS_OUT} -lt ${MAX_BOX} ]] && BOX_BOT=$(( BOX_ROW-1 )) || BOX_BOT=$(( BOX_X + MAX_BOX - 1 ))

		[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}LIST_TOP${RESET}:${LIST_TOP} ${WHITE_FG}LIST_BOT${RESET}:${LIST_BOT}"
		[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG} BOX_TOP${RESET}:${BOX_TOP} ${WHITE_FG} BOX_BOT${RESET}:${BOX_BOT}"

		# Restore cursor to previous position when returning from an outside task
		_SEL_MENU_COORDS=($(box_coords_get SEL_MENU))
		[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}_SEL_MENU_COORDS${RESET}:${(kv)_SEL_MENU_COORDS}"
		if [[ ${_SEL_LIST_RESTORE} == 'true' && -n ${_SEL_MENU_COORDS} && ${_SEL_MENU_COORDS[RESET]} == 'true' ]];then
			CURSOR_NDX=${_SEL_MENU_COORDS[NDX]} # Saved menu index
			CURSOR_ROW=${_SEL_MENU_COORDS[ROW]} # Saved menu row
			sel_list_norm ${BOX_TOP} ${BOX_Y} ${_SEL_LIST[${LIST_TOP}]}
			sel_list_hilite ${CURSOR_ROW} ${BOX_Y} ${_SEL_LIST[${CURSOR_NDX}]}
		else
			CURSOR_NDX=${LIST_TOP} # First menu index
			CURSOR_ROW=${BOX_TOP} # First menu row
		fi

		# Get keypress and navigate
		while true;do
			KEY=$(get_keys)
			_SEL_VAL='?'
			_SEL_KEY='?'

			# If calling application reserves a key then save list position and break from navigation
			if [[ ${_APP_KEYS[(i)${KEY}]} -le ${#_APP_KEYS} ]];then # App key was pressed
				[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"

				_SEL_KEY=${KEY} 
				_SEL_VAL=${_SEL_LIST[${CURSOR_NDX}]}
				[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"

				box_coords_set SEL_MENU NDX ${LIST_TOP} ROW ${BOX_TOP} RESET false
				break 2 # Quit navigation
			fi

			# Parse menu action
			case ${KEY} in
				0) sel_list_save_menu_pos ${CURSOR_NDX} ${CURSOR_ROW};_SEL_VAL=${_SEL_LIST[${CURSOR_NDX}]} && break 2;; # Enter key
				n) CURSOR_ROW=${BOX_TOP};CURSOR_NDX=$(sel_list_set_pg 'N' ${CURSOR_NDX});DIR='N';; # Next page
				p) CURSOR_ROW=${BOX_TOP};CURSOR_NDX=$(sel_list_set_pg 'P' ${CURSOR_NDX});DIR='P';; # Previous page
				q) sel_list_save_menu_pos ${CURSOR_NDX} ${CURSOR_ROW};exit_request $(sel_list_ebox_coords);break;; # Quit menu
				1|k) (( CURSOR_ROW-- ));(( CURSOR_NDX-- ));DIR='U';; # Previous item
				2|j) (( CURSOR_ROW++ ));(( CURSOR_NDX++ ));DIR='D';; # Next item
				3|t) DIR='T';; # Top item
				4|b) DIR='B';; # Bottom item
				27) msg_box_clear; return 2;; # Escape key
			esac

			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: KEY PRESS:${KEY} DIR:${DIR}"

			# Ensure sane index boundaries
			[[ ${MAX_NDX} -eq 1 && ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${RED_FG}MAX_NDX = 1 - BREAKING${RESET}"
			[[ ${MAX_NDX} -eq 1 ]] && break 

			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${RED_FG}PRE${RESET} BOUNDARY CHECK - CURSOR_NDX:${CURSOR_NDX} CURSOR_ROW:${CURSOR_ROW}"

			# Roll-arounds
			if [[ ${CURSOR_NDX} -lt ${LIST_TOP} ]];then
				CURSOR_NDX=${LIST_BOT}
				CURSOR_ROW=${BOX_BOT}
			elif [[ ${CURSOR_NDX} -gt ${LIST_BOT} ]];then
				CURSOR_NDX=${LIST_TOP}
				CURSOR_ROW=${BOX_TOP}
			fi
			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${GREEN_FG}POST${RESET} BOUNDARY CHECK - CURSOR_NDX:${CURSOR_NDX} CURSOR_ROW:${CURSOR_ROW}"
			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${RED_FG}PRE${RESET} ROLL AROUND - LAST_NDX:${LAST_NDX} LAST_ROW:${LAST_ROW}"

			case ${DIR} in
				D)	if [[ ${CURSOR_NDX} -eq ${LIST_TOP} ]];then
						LAST_NDX=${LIST_BOT}
						LAST_ROW=${BOX_BOT}
					else
						LAST_NDX=$(( CURSOR_NDX-1 ))
						LAST_ROW=$(( CURSOR_ROW-1 ))
					fi
					;;
				U)	if [[ ${CURSOR_NDX} -eq ${LIST_BOT} ]];then
						LAST_NDX=${LIST_TOP}
						LAST_ROW=${BOX_TOP}
					else
						LAST_NDX=$(( CURSOR_NDX+1 ))
						LAST_ROW=$(( CURSOR_ROW+1 ))
					fi
					;;
			esac
			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${GREEN_FG}POST${RESET} ROLL AROUND - LAST_NDX:${LAST_NDX} LAST_ROW:${LAST_ROW}"

			# Row and Page changes
			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${RED_FG}PRE${RESET} ROW/PAGE - CURSOR_NDX:${CURSOR_NDX} CURSOR_ROW:${CURSOR_ROW}"

			# Directionals
			case ${DIR} in
				D|U)	sel_list_hilite ${CURSOR_ROW} ${BOX_Y} ${_SEL_LIST[${CURSOR_NDX}]}
						sel_list_norm ${LAST_ROW} ${BOX_Y} ${_SEL_LIST[${LAST_NDX}]}
						;;

				T) 	if [[ ${CURSOR_NDX} -ne ${LIST_TOP} ]];then
							sel_list_hilite ${BOX_TOP} ${BOX_Y} ${_SEL_LIST[${LIST_TOP}]}
							sel_list_norm ${CURSOR_ROW} ${BOX_Y} ${_SEL_LIST[${CURSOR_NDX}]}
							CURSOR_NDX=${LIST_TOP}
							CURSOR_ROW=${BOX_TOP}
						fi
						;;

				B)		if [[ ${CURSOR_NDX} -ne ${LIST_BOT} ]];then
							sel_list_hilite ${BOX_BOT} ${BOX_Y} ${_SEL_LIST[${LIST_BOT}]}
							sel_list_norm ${CURSOR_ROW} ${BOX_Y} ${_SEL_LIST[${CURSOR_NDX}]}
							CURSOR_NDX=${LIST_BOT}
							CURSOR_ROW=${BOX_BOT}
						fi
						;;

				N) if [[ $(( _CUR_PAGE+1 )) -le ${_MAX_PAGE} ]];then
						(( _CUR_PAGE++ ))
						LIST_TOP=${_PAGE_TOPS[${_CUR_PAGE}]}
						break
					else
						_CUR_PAGE=1
						LIST_TOP=${_PAGE_TOPS[${_CUR_PAGE}]}
						break
					fi
					;;

				P) if [[ $(( _CUR_PAGE-1 )) -ge 1 ]];then
						(( _CUR_PAGE-- ))
						LIST_TOP=${_PAGE_TOPS[${_CUR_PAGE}]}
						break
					else
						_CUR_PAGE=${_MAX_PAGE}
						LIST_TOP=${_PAGE_TOPS[${_CUR_PAGE}]}
						break
					fi
					;;
			esac
			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${GREEN_FG}POST${RESET} ROW/PAGE - CURSOR_NDX:${CURSOR_NDX} CURSOR_ROW:${CURSOR_ROW}"
		done
	done
	return 0
}

sel_list_ebox_coords () {
	local -A I_COORDS
	local MSG_LEN=28
	local W_ARG
	local Y_ARG

	I_COORDS=($(box_coords_get INNER_BOX))

	if [[ $(( I_COORDS[W] + 6 )) -le ${MSG_LEN} ]];then
		W_ARG=${MSG_LEN}
		Y_ARG=$(( I_COORDS[Y] - 2 ))
	else
		W_ARG=$(( I_COORDS[W] + 6 ))
		Y_ARG=$(( I_COORDS[Y] - 2 ))
	fi

	echo $(( I_COORDS[X] + 1 )) ${Y_ARG} ${W_ARG} # X Y W
}

sel_list_get_cat () {
	local NDX=${1}

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	cut -d: -f1 <<<${_SEL_LIST[${NDX}]}
}

sel_list_get_label () {
	local NDX=${1}

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	cut -d: -f2 <<<${_SEL_LIST[${NDX}]}
}

sel_list_hilite () {
	local X=${1}
	local Y=${2}
	local TEXT=${3}
	local F1 F2

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"

	tput cup ${X} ${Y}

	tput smso
	if [[ ${_SL_CATEGORY} == 'true' ]];then
		F1=$(cut -d: -f1 <<<${TEXT})
		F2=$(cut -d: -f2 <<<${TEXT})
		printf "${WHITE_FG}%-*s${RESET} ${_HILITE}%-*s${RESET}\n" ${_COL_WIDTHS[1]} ${F1} ${_COL_WIDTHS[2]} ${F2}
	else
		echo ${TEXT}
	fi
	tput rmso

	_HILITE_X=${X}
}

sel_list_norm () {
	local X=${1}
	local Y=${2}
	local TEXT=${3}
	local F1 F2

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"

	tput cup ${X} ${Y}
	tput rmso
	if [[ ${_SL_CATEGORY} == 'true' ]];then
		F1=$(cut -d: -f1 <<<${TEXT})
		F2=$(cut -d: -f2 <<<${TEXT})
		printf "${WHITE_FG}%-*s${RESET} %-*s\n" ${_COL_WIDTHS[1]} ${F1} ${_COL_WIDTHS[2]} ${F2}
	else
		echo ${TEXT}
	fi
}

sel_list_repaint () {
	local -A I_COORDS
	local -A E_COORDS
	local LX LY LT
	local L X

	E_COORDS=($(box_coords_get EXR_BOX))
	for (( X=E_COORDS[X] -1; X <= ( E_COORDS[X] + E_COORDS[H] -1 ) - 1; X++ ));do
		tput cup ${X} $(( E_COORDS[Y] -1 ))
		tput ech $(( E_COORDS[W] ))
	done

	I_COORDS=($(box_coords_get INNER_BOX))
	msg_unicode_box ${I_COORDS[X]} ${I_COORDS[Y]} ${I_COORDS[W]} ${I_COORDS[H]}

	for L in ${_SEL_LIST_TEXT};do
		LX=$(cut -d'|' -f1 <<<${L})
		LY=$(cut -d'|' -f2 <<<${L})
		LT=$(cut -d'|' -f3 <<<${L})
		tput cup ${LX} ${LY}; echo ${LT}
	done
}

sel_list_save_menu_pos () {
	local CURSOR_NDX=${1}
	local CURSOR_ROW=${2}

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: CURSOR_NDX:${CURSOR_NDX} CURSOR_ROW:${CURSOR_ROW}"

	box_coords_set SEL_MENU NDX ${CURSOR_NDX} ROW ${CURSOR_ROW} RESET true
}

sel_list_set () {
	local -a LIST=(${@})

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_SEL_LIST=(${(on)LIST})
	_SL_MAX_ITEM_LEN=0 # Trigger column width reset

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${0} _SEL_LIST:${#_SEL_LIST} ITEMS"
}

sel_list_set_app_keys () {
	_APP_KEYS=(${@})
	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _APP_KEYS:${_APP_KEYS}"
}

sel_list_set_header () {
	_SEL_LIST_HDR=${1}
}

sel_list_set_restore () {
	local BOOL=${1:=false}

	_SEL_LIST_RESTORE=${BOOL}
}

sel_list_set_page_help () {
	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_PAGE_OPTION_KEY_HELP=${@}
}

sel_list_set_pg () {
	local DIR=${1}
	local NDX=${2}
	local P

	[[ ${_DEBUG} -ge ${_SEL_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for P in ${(onk)_PAGE_TOPS};do
		[[ ${NDX} -ge ${_PAGE_TOPS[${P}]} ]] && _CUR_PAGE=${P}
	done

	if [[ ${DIR} == 'P' ]];then
		if [[ ${_CUR_PAGE} -eq 1 ]];then
			echo ${NDX}
			return
		else
			_CUR_PAGE=$(( _CUR_PAGE - 1 ))
		fi
	fi

	if [[ ${DIR} == 'N' ]];then
		if [[ ${_CUR_PAGE} -eq ${_MAX_PAGE} ]];then
			echo ${NDX}
			return
		else
			_CUR_PAGE=$(( _CUR_PAGE + 1 ))
		fi
	fi

	echo ${_PAGE_TOPS[${_CUR_PAGE}]}
}

