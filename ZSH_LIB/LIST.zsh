# LIB Dependencies
_DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh PATH.zsh STR.zsh TPUT.zsh UTILS.zsh VALIDATE.zsh"

# Constants
_AVAIL_ROW=0
_HELD_ROW=1
_GHOST_ROW=2 # Not selectable
_LIST_LIB_DBG=4
_SORT_MARKER=$(mktemp /tmp/last_sort.XXXXXX)
 
# LIB Declarations
typeset -A _KEY_QUIT_CALLBACKS=()
typeset -A _LIST_SELECTED=() # Status of selected list items; contains digit 0,1,2, etc.; 0,1 can toggle; -gt 1 cannot toggle (action completed)
typeset -A _LIST_SELECTED_PAGE=() # Selected rows by page
typeset -A _SORT_COLS=() # Sort column mapping
typeset -A _SORT_TABLE=() # Sort assoc array names
typeset -a _LIST=() # Holds the values to be managed by the menu
typeset -a _LIST_ACTION_MSGS=() # Holds text for contextual prompts
typeset -a _LIST_HEADER=() # Holds header lines
typeset -a _LIST_INDEX_RANGE=() # Holds the top and bottom screen row indicies
typeset -a _MARKED=()
typeset -a _SELECTION_LIST=() # Holds indices of selected items in a list
typeset -a _TARGETS=() # Target indexes

# LIB Vars
_ACTIVE_SEARCH=false
_BARLINES=false
_CBC_KEY=''
_CBQ_KEY=''
_CLEAR_GHOSTS=false
_CLIENT_WARN=true
_CURRENT_ARRAY=1
_CURRENT_CURSOR=0
_CURRENT_PAGE=1
_CURSOR_COL=${CURSOR_COL:=0}
_CURSOR_ROW=${CURSOR_ROW:=0}
_HEADER_CALLBACK_FUNC=''
_LINE_MARKER=')'
_HEADER_LINES=0
_HOLD_CURSOR=false
_HOLD_PAGE=false
_KEY_CALLBACK_CONT_FUNC=''
_KEY_CALLBACK_QUIT_FUNC=''
_LIST_DELIM='|'
_LIST_HEADER_BREAK=false
_LIST_HEADER_BREAK_COLOR=${WHITE_FG}
_LIST_HEADER_BREAK_LEN=0
_LIST_IS_SEARCHABLE=true
_LIST_IS_SORTABLE=false
_LIST_LINE_ITEM=''
_LIST_NDX=0
_LIST_PROMPT=''
_LIST_SELECT_NDX=0
_LIST_SELECT_ROW=0
_LIST_SET_DEFAULTS=true
_LIST_SORT_COL_DEFAULT=''
_LIST_SORT_COL_MAX=0
_LIST_SORT_DIR_DEFAULT=''
_LIST_SORT_TYPE=flat
_LIST_USER_PROMPT_STYLE=none
_MARKER=${_LINE_MARKER}
_MSG_KEY=n
_NO_TOP_OFFSET=false
_OFFSCREEN_ROWS_MSG=''
_PAGE_CALLBACK_FUNC=''
_PROMPT_KEYS=''
_ROW_OVERRIDE=false
_SEARCH_MARKER="${BOLD}${RED_FG}\u25CF${RESET}"
_SELECTABLE=true
_SELECTION_LIMIT=0
_SELECT_ALL=false
_SELECT_CALLBACK_FUNC=''
_TARGET_CURSOR=1
_TARGET_KEY=''
_TARGET_NDX=1
_TARGET_PAGE=1

# Initialization
set_exit_callback list_sort_clear_marker
/bin/rm -f /tmp/last_sort* >/dev/null 2>&1

# LIB Functions
list_add_header_break () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_HEADER_BREAK=true
}

list_clear_selected () {
	local NDX=${1}

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_SELECTED[${NDX}]=0
}

list_do_header () {
	local PAGE=${1}
	local MAX_PAGE=${2}
	local CLEAN_HDR
	local CLEAN_TAG
	local HDR_LEN
	local HDR_LINE
	local HDR_PG=false
	local L
	local LONGEST_HDR=0
	local PAD_LEN
	local PAD_TAG
	local PG_TAG
	local SCRIPT_TAG='printf "${_LIST_HEADER_BREAK_COLOR}[${RESET}${_SCRIPT}${_LIST_HEADER_BREAK_COLOR}]${RESET}"'
	local SELECTED_COUNT=$(list_get_selected_count); 

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: HEADER COUNT:${#_LIST_HEADER}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: PAGE=${PAGE} MAX_PAGE=${MAX_PAGE} SELECTED_COUNT=${SELECTED_COUNT}"

	for (( L=1; L<=${#_LIST_HEADER}; L++ ));do
		HDR_LINE=$(eval ${_LIST_HEADER[${L}]})
		CLEAN_HDR=$(str_strip_ansi <<<${HDR_LINE})
		[[ ${#CLEAN_HDR} > ${LONGEST_HDR} ]] && LONGEST_HDR=${#CLEAN_HDR}
	done

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: LONGEST_HDR:${LONGEST_HDR} (before any modifications)"

	# Position cursor
	tcup 0 0
	tput el

	for (( L=1; L<=${#_LIST_HEADER}; L++ ));do
		[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Processing header 1 of ${#_LIST_HEADER}"
		if [[ -n ${_LIST_HEADER[${L}]} ]];then

			HDR_LINE=$(eval ${_LIST_HEADER[${L}]})
			[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: (eval) HEADER LINE:${L} -> ${HDR_LINE}"


			if [[ ${L} -eq 1 ]];then # Top line
			 # Prepend script name
				SCRIPT_TAG=$(eval ${SCRIPT_TAG}) && HDR_LINE="${SCRIPT_TAG} ${HDR_LINE}" && CLEAN_HDR=$(str_strip_ansi <<<${HDR_LINE})
				[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Added header name tag:${HDR_LINE}"
			fi

			[[ ${_LIST_HEADER[${L}]} =~ '_PG' ]] && HDR_PG=true # Do page numbering

				if [[ ${HDR_PG} == 'true' ]];then # Append page number
					PG_TAG=$(eval "printf 'Page:${WHITE_FG}%d${RESET} of ${WHITE_FG}%d${RESET}' ${PAGE} ${MAX_PAGE}") && CLEAN_TAG=$(str_strip_ansi <<<${PG_TAG})
					HDR_LEN=$(( ${#CLEAN_HDR} + ${#CLEAN_TAG} ))
					[[ ${LONGEST_HDR} -gt ${HDR_LEN} ]] && PAD_LEN=$(( LONGEST_HDR - HDR_LEN )) || PAD_LEN=1
					PG_TAG="$(str_rep_char ' ' ${PAD_LEN})${PG_TAG}"
					[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: HDR_LEN:${HDR_LEN}, LONGEST_HDR:${LONGEST_HDR}, PAD_LEN:${PAD_LEN}"

					HDR_LINE="${HDR_LINE}${PG_TAG}"
					CLEAN_HDR=$(str_strip_ansi <<<${HDR_LINE})
					LONGEST_HDR=${#CLEAN_HDR} # This header will now be the longest
					[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Added header page tag:${HDR_LINE}, LONGEST_HDR:${LONGEST_HDR}"

					HDR_PG=false
				fi
				
				tput el
				echo ${HDR_LINE}
			fi

			tcup ${L} 0
		done

		if [[ ${_LIST_HEADER_BREAK} == 'true' ]];then
			tput el && echo -n ${_LIST_HEADER_BREAK_COLOR} && str_unicode_line ${LONGEST_HDR} && echo -n ${RESET}
			[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Header break length:${LONGEST_HDR}"
		fi
}

list_get_index_range () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	echo "${_LIST_INDEX_RANGE}"
}

list_get_next_page () {
	local KEY=${1}
	local PAGE=${2}
	local MAX_PAGE=${3}

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	case ${KEY} in
		n) ((PAGE++));;
		p) ((PAGE--));;
		fp) PAGE=1;;
		lp) PAGE=${MAX_PAGE};;
		*) PAGE=${KEY};;
	esac

	[[ ${PAGE} -lt 1 ]] && PAGE=${MAX_PAGE}
	[[ ${PAGE} -gt ${MAX_PAGE} ]] && PAGE=1

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Returning PAGE:${WHITE_FG}${PAGE}${RESET}"

	echo ${PAGE}
}

list_get_selected () {
	local S

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for S in ${(k)_LIST_SELECTED};do
		[[ ${_LIST_SELECTED[${S}]} -ne 1 ]] && continue
		echo ${S}
	done
}

list_get_selected_count () {
	local COUNT=0
	local S

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for S in ${(k)_LIST_SELECTED};do
		[[ ${_LIST_SELECTED[${S}]} -ne 1 ]] && continue
		((COUNT++))
	done

	echo ${COUNT}
}

list_get_selection_limit () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo ${_SELECTION_LIMIT}
}

list_is_CBQ () {
	local KEY=${1}

	[[ -n ${_KEY_QUIT_CALLBACKS[${KEY}]} ]] && echo ${KEY} || echo ''
}

list_is_valid_selection () {
	local -a SELECTED
	local MAX
	local MIN
	local N

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	MIN=${1};shift
	MAX=${1};shift
	SELECTED=(${@})

	for N in ${SELECTED};do
		if ! validate_is_integer ${N};then
			return 1
		elif ! list_is_within_range ${N} ${MIN} ${MAX};then
			return 1
		elif [[ ${_CLEAR_GHOSTS} == 'false' && ${_LIST_SELECTED[${N}]} -ge ${_GHOST_ROW} && ${_SELECT_ALL} == 'false' ]];then # Cannot select deleted row; select 'all' is exception
			return 1
		fi
	done

	return 0
}

list_is_within_range () {
	local NDX=${1}
	local MIN=${2}
	local MAX=${3}

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if [[ ${NDX} -ge ${MIN} && ${NDX} -le ${MAX} ]];then
		return 0
	else
		echo "Selection:${NDX} not in page range ${MIN}-${MAX}"
		return 1
	fi
}

list_item () {
	local MODE=${1}
	local LINE_ITEM=${2}
	local X_POS=${3}
	local Y_POS=${4}
	local MARKER=''
	local TOP_OFFSET=${_HEADER_LINES}
	local BARLINE BAR

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: ARGS - MODE:${MODE} LINE_ITEM LEN:${#LINE_ITEM} X_POS:${X_POS} Y_POS:${Y_POS} TOP_OFFSET:${TOP_OFFSET} _LIST_NDX:${_LIST_NDX}"
	
	_MARKER=${_LINE_MARKER}

	if [[ ${_ACTIVE_SEARCH} == 'true' ]];then
		[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: _TARGET_NDX:${_TARGET_NDX} _TARGET_CURSOR:${_TARGET_CURSOR} _TARGET_PAGE:${_TARGET_PAGE}"
		MARKER=${_TARGETS[(r)*:${X_POS}:${PAGE}*]}
		if [[ -n ${MARKER} ]];then
			_MARKER=${_SEARCH_MARKER}
			[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: _LIST_NDX:${_LIST_NDX} X_POS:${X_POS} PAGE:${PAGE} MASK:\"$(( X_POS - 1 )):${PAGE}\" MARKER:${MARKER}"
		fi
	fi

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: X_POS:${X_POS} Y_POS:${Y_POS}"
	tcup ${X_POS} ${Y_POS}
	[[ ${MODE} == 'high' ]] && tput smso || tput rmso

	if [[ ${_BARLINES} == 'true' ]];then
		BARLINE=$(( _LIST_NDX % 2 )) # Barlining 
		[[ ${BARLINE} -ne 0 ]] && BAR=${BLACK_BG} || BAR="" # Barlining
	fi

	#tcup ${X_POS} 70;tput el; echo -n "MODE:${MODE} _LIST_NDX:${_LIST_NDX} X_POS:${X_POS} PAGE:${PAGE} MASK:\"$(( X_POS - 1 )):${PAGE}\" MARKER:${_MARKER}"
	eval ${LINE_ITEM} # Output line
}

list_parse_series () {
	local PATTERN=(${@})
	local -a FROM=()
	local -a TO=()
	local -a R1=()
	local -a R2=()
	local -a SELECTED=()
	local -a KEYLIST=()
	local RANGE=false
	local BEG
	local END
	local P K

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	PATTERN+="#" # Force extra parse cycle

	for P in ${PATTERN};do
		[[ ${P} == '-' ]] && RANGE=true && continue

		if [[ ${P} =~ "[,# ]" ]];then # Hit separator
			if [[ ${RANGE} == 'true' ]];then
				BEG=$(str_array_to_num ${FROM})
				KEYLIST+="B${BEG}"
				FROM=()
				END=$(str_array_to_num ${TO})
				KEYLIST+="E${END}"
				TO=()
			else
				ITEM=$(str_array_to_num ${FROM})
				KEYLIST+=${ITEM}

				FROM=()
			fi
			RANGE=false
			continue
		fi

		if [[ ${RANGE} == 'true' ]];then
			TO+=${P}
		else
			FROM+=${P}
		fi
	done


	for K in ${KEYLIST};do
		if [[ ${K[1,1]} =~ "[BE]" ]];then
			case ${K[1,1]} in
				B) R1+=${K[2,${#K}]};continue;;
				E) R2+=${K[2,${#K}]};continue;;
			esac
		fi
		SELECTED+=${K} # Non range element
	done


	# Handle range elements
	if [[ -n ${R1} ]];then
		for (( X=1;X<=${#R1};X++ ));do
			SELECTED+=$(echo {${R1[${X}]}..${R2[${X}]}})
		done
	fi

	echo ${SELECTED}
}

list_quote_marked_elements () {
	local MARKED=(${@})
	local M
	local -a STR

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for M in ${MARKED};do
	 # STR+=${(qqq)_LIST[${M}]}
		STR+=${(q)_LIST[${M}]}
	done

	echo ${STR}
}

list_reset () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_CURSOR_ROW=0
	_HOLD_CURSOR=false
	_LIST_HEADER=()
	_LIST_INDEX_RANGE=()
	_LIST_PROMPT=''
	_LIST_SELECTED=()
	_MARKED=()
	_SELECTION_LIST=()
	_SORT_TABLE=()
}

list_search () {
	local MODE=${1}
	local PAGE=${2} 
	local KEY=''
	local K_TEXT=''
	local RC

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: MODE:${MODE} PAGE:${PAGE}"

	[[ ${_LIST_IS_SEARCHABLE} == 'false' ]] && return

	case ${MODE} in
		new)		list_search_new ${PAGE}
					RC=${?}
					[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: SEARCH: list_search_new returned ${RC}"
					[[ ${RC} -ne 0 ]] && return 1	
					;;
		fwd|rev)	list_search_find ${MODE}
					RC=${?}
					[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: SEARCH: list_search_find returned ${RC}"
					;;
		*) return 1;;
	esac

	#tcup 10 40;tput el; echo -n "${0}: KEY:${KEY} _TARGET_NDX:${_TARGET_NDX} _TARGET_CURSOR:${_TARGET_CURSOR} _TARGET_PAGE:${_TARGET_PAGE}"
	#read
	 
	KEY=${_TARGETS[(i)*next_target]} # Index of current target
	IFS=":" read _TARGET_NDX _TARGET_CURSOR _TARGET_PAGE K_TEXT <<<${_TARGETS[${KEY}]}
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: _TARGET_NDX:${_TARGET_NDX} _TARGET_CURSOR:${_TARGET_CURSOR} _TARGET_PAGE:${_TARGET_PAGE}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: ${WHITE_FG}RETURNING FROM SEARCH - TARGETS SET${RESET}"
	_ACTIVE_SEARCH=true
	return 0
}

list_search_new () {
	local PAGE=${1}
	local HDR=''
	local HL=0
	local H_CTR=0
	local HEIGHT=7
	local PROMPT=''
	local ROW=0
	local V_CTR=0
	local SEARCHTERM=''

	_TARGETS=()
	_TARGET_NDX=''
	_TARGET_CURSOR=''
	_TARGET_PAGE=''

	HDR="<m>$(str_unicode_line 12) List Search (Next:<w>><m>, Prev:<w><<m>) $(str_unicode_line 12)<N>"
	HL=$(msg_nomarkup ${HDR});HL=${#HL}

	V_CTR=$(( _MAX_ROWS/2 - 4 )) # Vertical center
	H_CTR=$(coord_center $(( _MAX_COLS - 3 )) ${HL}) # Horiz center

	for (( ROW=1; ROW<=HEIGHT + 1; ROW++ ));do # Clear a space to place the UI
		tcup $(( V_CTR + ROW - 3 )) $(( H_CTR -3 ))
		tput ech $(( ${#HDR} + 3 ))
	done

	msg_box -x${V_CTR} -y${H_CTR} -w${HL} "${HDR}" # Display header

	tcup $(( V_CTR + 4 )) $(( H_CTR + 2 ))
	PROMPT="${E_RESET}${E_BOLD}Find${E_RESET}:"
	
	sleep 2 &
	SEARCHTERM=$(inline_vi_edit ${PROMPT} "") # Call line editor

	msg_box_clear X Y ${HEIGHT} W  # Clear box containing inline edit 

	if [[ -z ${SEARCHTERM} ]];then # User entered nothing
		list_search_repaint ${HEIGHT} ${PAGE}
		return 1
	fi

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: TARGET:${TARGET}"

	if ! list_search_set_targets ${SEARCHTERM};then
		for (( ROW=0; ROW<=${HEIGHT}; ROW++ ));do # Clear a space to place the MSG
			tcup $(( V_CTR + ROW )) ${H_CTR}
			tput ech ${#HDR}
		done

		msg_box -x${V_CTR} -y$(( H_CTR + 10 )) -p -PK "<m>List Search<N>| |\"<w>${SEARCHTERM}<N>\" - <r>NOT<N> found" 
		msg_box_clear

		list_search_repaint $(( HEIGHT + 3 )) ${PAGE}
		return 1
	fi

	_TARGETS[1]="${_TARGETS[1]}:next_target" # Initialize first target

	list_search_repaint $(( HEIGHT + 1 )) ${PAGE} # Patch the display
	return 0
}

list_search_find () {
	local DIRECTION=${1}
	local KEY=''
	local NEXT_TARGET=''
	local T_CUR=0
	local T_NDX=0
	local T_PAGE=0
	local T_NEXT=0

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: DIRECTION: ${DIRECTION}"
	
	NEXT_TARGET=$(list_search_get_key ${DIRECTION})
	[[ ${?} -ne 0 ]] && return 1

	IFS=":" read T_NDX T_CUR T_PAGE T_NEXT <<<${NEXT_TARGET}
	[[ -z ${T_NDX} ]] && return 1

	KEY=${_TARGETS[(i)*next_target]} # Index of current target
	_TARGETS[${KEY}]=$(sed "s/next_target/seen/" <<<${_TARGETS[${KEY}]}) # Cancel current target
	_TARGETS[${T_NEXT}]="${T_NDX}:${T_CUR}:${T_PAGE}:next_target" # Set next_target
	return 0
}

list_search_get_key () {
	local MODE=${1}
	local NDX=0
	local CUR_TGT_NDX=0
	local MAX_TARGETS=${#_TARGETS}
	local R C P T

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	CUR_TGT_NDX=${_TARGETS[(i)*next_target]}
	[[ -z ${CUR_TGT_NDX} ]] && return 1

	case ${MODE} in
		fwd) [[ $(( CUR_TGT_NDX + 1 )) -gt ${MAX_TARGETS} ]] && NDX=1 || NDX=$(( CUR_TGT_NDX + 1 ));;
		rev) [[ $(( CUR_TGT_NDX - 1 )) -le 0 ]] && NDX=${MAX_TARGETS} || NDX=$(( CUR_TGT_NDX - 1 ));;
	esac

	IFS=":" read R C P T <<<${_TARGETS[${NDX}]}
	echo "${R}:${C}:${P}:${NDX}" # Pass the next index
	return 0
}

list_search_repaint () {
	local -A MSG_COORDS=($(box_coords_get MSG_BOX ))
	local ROWS=${1}
	local PAGE=${2}
	local CURSOR=0
	local DISPLAY_ROWS=0
	local END_COL=0
	local END_ROW=0
	local HDR_OFFSET=${#_LIST_HEADER}
	local LINE_SNIP=''
	local SAVED_NDX=${_LIST_NDX}
	local START_COL=0
	local START_ROW=0
	local R

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: STORED SAVED_NDX:${SAVED_NDX}"

	if [[ -z ${MSG_COORDS} ]];then
		[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: MSG_COORDS is null: returning"
		return
	fi

	START_COL=${MSG_COORDS[Y]}
	START_ROW=${MSG_COORDS[X]}
	END_COL=$(( START_COL + ${MSG_COORDS[W]} ))

	DISPLAY_ROWS=$(( ${_LIST_INDEX_RANGE[2]} - ${_LIST_INDEX_RANGE[1]} + 1 ))
	CURSOR=$(( START_ROW - 1 ))

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: START_COL:${START_COL} START_ROW:${START_ROW} END_COL:${END_COL} DISPLAY_ROWS:${DISPLAY_ROWS} CURSOR:${CURSOR}"
	
	[[ ${_LIST_HEADER_BREAK} == 'false' ]] && ((HDR_OFFSET--))

	START_ROW=$(( ${_LIST_INDEX_RANGE[1]} + START_ROW - HDR_OFFSET - 1 ))
	END_ROW=$(( START_ROW + ROWS ))
	_LIST_NDX=$(( START_ROW - 1 ))

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: START_ROW:${START_ROW} END_ROW:${END_ROW} _LIST_NDX:${_LIST_NDX}"

	_MARKER=${_LINE_MARKER}
	for (( R=START_ROW; R<=END_ROW; R++ ));do
		((CURSOR++))
		((_LIST_NDX++))
		if [[ ${_BARLINES} == 'true' ]];then
			BARLINE=$(( _LIST_NDX % 2 )) # Barlining 
			[[ ${BARLINE} -ne 0 ]] && BAR=${BLACK_BG} || BAR="" # Barlining
		fi
		if [[ ${_LIST_NDX} -le ${#_LIST} ]];then
			tcup ${CURSOR} 0
			eval ${_LIST_LINE_ITEM} # Line item printf
		fi
	done

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: RETURNING SAVED_NDX:${SAVED_NDX}"

	_LIST_NDX=${SAVED_NDX} # Restore NDX
}

list_search_set_pages () {
	local -A PAGES
	local BOT
	local PG=0
	local TOP
	local L

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for (( L=1; L <= ${#_LIST}; L++ ));do
		if [[ $(( L % MAX_DISPLAY_ROWS )) -eq 0 ]];then
			(( PG++))
			TOP=$(( L - MAX_DISPLAY_ROWS + 1 ))
			PAGES[${PG}]="${TOP}:${L}"
		fi
	done

	# Last page
	BOT=$(cut -d: -f2 <<<${PAGES[${PG}]})
	TOP=$(( BOT + 1 ))
	BOT=$(( L - 1 ))
	(( PG++))
	PAGES[${PG}]=${TOP}:${BOT}

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}:${LINENO} RETURNING page boundaries for ${#PAGES} pages"

	echo "${(kv)PAGES}"
}

list_search_set_targets () {
	local SEARCHTERM=${@}
	local -A PAGES=( $(list_search_set_pages) )
	local BOT=0
	local TOP=0
	local TOP_OFFSET=${_HEADER_LINES}
	local C P R

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: SEARCHTERM:${SEARCHTERM}"

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: SEARCHING LIST FOR TARGETS"

	# TODO: list_search_set_targets: :t modifier limits search to commands only.  Should path (entire string) be included?
	# TODO: investigate making all lists searchable - accomodate different list structures - until then mark
	# TODO: incompatibles with SEARCHABLE=false
	_TARGETS=("${(f)$(
	for P in ${(onk)PAGES};do
		IFS=":" read TOP BOT <<<${PAGES[${P}]}
		for (( R=TOP; R<=BOT; R++ ));do
			C=$(( R - TOP + TOP_OFFSET ))
			echo "${C}:${P}:${_LIST[${R}]:t}"
		done
	done | grep --color=never -ni -P ":.*${SEARCHTERM}.*" | perl -p -e "s/^(\d+:\d+:\d+)(.*)$/\1/" # Return key:NDX/CURSOR/PAGE
	)}")

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: FOUND ${#_TARGETS} TARGETS - TOP_OFFSET:${TOP_OFFSET}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: \n$(for R in ${_TARGETS};do echo ${WHITE_FG}${R}${RESET};done)"

	[[ -n ${_TARGETS} ]] && return 0 || return 1
}

list_select () {
	local -a ACTION_MSGS=()
	local -a LIST_RANGE=()
	local -a LIST_SELECTION=()
	local BARLINE BAR SHADE
	local BOT_OFFSET=3
	local COLS=0
	local CURSOR_NDX=0
	local DIR_KEY=''
	local HDR_NDX=0
	local ITEM=''
	local KEY=''
	local KEY_LINE=''
	local L R S 
	local LAST_LIST_NDX=0
	local LINE_ITEM=''
	local LIST_DATA=''
	local MAX_CURSOR=0
	local MAX_DISPLAY_ROWS=0
	local MAX_LINE_WIDTH=0
	local MAX_ITEM=0
	local MAX_PAGE=0
	local MODE=''
	local OUT=0
	local PAGE=1
	local PAGE_BREAK=false
	local PAGE_RANGE_BOT=0
	local PAGE_RANGE_TOP=0
	local REM=0
	local ROWS=$(tput lines)
	local SELECTED_COUNT=0
	local SELECTION_LIMIT=$(list_get_selection_limit)
	local TOP_OFFSET=0
	local USER_PROMPT=''

	# Initialization
	_LIST=(${@})
	MAX_ITEM=${#_LIST}
	_SELECT_ALL=false

	# Max line
	COLS=$(tput cols)
	MAX_LINE_WIDTH=$(( (COLS - ${#${#_LIST}}) - 10 )) # Display-cols minus width-of-line-number plus a 10 space margin

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} _LIST COUNT:${#_LIST}"

	# Calculate display rows based on number of header lines
	[[ -z ${_LIST_HEADER} ]] && _LIST_HEADER+='printf "List of %-d items\tPage %-d of %-d \tSelected:%-d" ${MAX_ITEM} ${PAGE} ${MAX_PAGE} ${SELECTED_COUNT}' # Default header
	TOP_OFFSET=${#_LIST_HEADER}
	[[ ${_LIST_HEADER_BREAK} == 'true' ]] && ((TOP_OFFSET++))
	_HEADER_LINES=${TOP_OFFSET}

	# Boundaries
	MAX_DISPLAY_ROWS=$(( ROWS - (TOP_OFFSET + BOT_OFFSET) ))
	MAX_PAGE=$(( MAX_ITEM / MAX_DISPLAY_ROWS ))
	REM=$(( MAX_ITEM % MAX_DISPLAY_ROWS ))
	[[ ${REM} -ne 0 ]] && ((MAX_PAGE++))

	# Assign Defaults for Header, Prompt, and Line_Item formatting
	[[ -z ${_LIST_LINE_ITEM} ]] && _LIST_LINE_ITEM='printf "${BOLD}${_HILITE_COLOR}%*d${RESET}) ${SHADE}%s${RESET}\n" ${#MAX_ITEM} ${_LIST_NDX} ${${_LIST[${_LIST_NDX}]}[1,${MAX_LINE_WIDTH}]}'
	[[ -n ${_LIST_PROMPT} ]] && USER_PROMPT=${_LIST_PROMPT} || USER_PROMPT="Enter to toggle selection"
	[[ -n ${_LIST_ACTION_MSGS[1]} ]] && ACTION_MSGS[1]=${_LIST_ACTION_MSGS[1]} || ACTION_MSGS[1]="process"
	[[ -n ${_LIST_ACTION_MSGS[2]} ]] && ACTION_MSGS[2]=${_LIST_ACTION_MSGS[2]} || ACTION_MSGS[2]="item"
	[[ -n ${_PROMPT_KEYS} ]] && KEY_LINE=$(eval ${_PROMPT_KEYS}) || KEY_LINE=$(printf "Press ${WHITE_FG}%s%s%s%s${RESET} Home End PgUp PgDn <${WHITE_FG}n${RESET}>ext, <${WHITE_FG}p${RESET}>rev, <${WHITE_FG}b${RESET}>ottom, <${WHITE_FG}t${RESET}>op, <${WHITE_FG}c${RESET}>lear, vi[${WHITE_FG}h,j,k,l${RESET}], <${WHITE_FG}a${RESET}>ll${RESET}, <${GREEN_FG}ENTER${RESET}>${RESET}, <${WHITE_FG}q${RESET}>uit${RESET}" $'\u2190' $'\u2191' $'\u2193' $'\u2192')
	[[ -n ${KEY_LINE} ]] && USER_PROMPT="${KEY_LINE}\n${USER_PROMPT}"

	# Navigation init
	PAGE_BREAK=false
	PAGE_RANGE_TOP=1
	PAGE_RANGE_BOT=${MAX_DISPLAY_ROWS}
	list_set_index_range ${PAGE_RANGE_TOP} ${PAGE_RANGE_BOT}
	# End of Initialization

	# Display current page of list items
	while true;do
		tput civis >&2
		tput clear

		# Prepare page display
		# Navigation; maintain 2 indexes; 1 for array access (_LIST_NDX), 1 for cursor position (CURSOR_NDX)
		if [[ ${PAGE_BREAK} == 'true' ]];then
			PAGE=$(list_get_next_page ${DIR_KEY} ${PAGE} ${MAX_PAGE}) # Next page
			PAGE_RANGE_TOP=$(( (PAGE - 1) * MAX_DISPLAY_ROWS + 1 ))
			PAGE_RANGE_BOT=$(( (PAGE_RANGE_TOP - 1) + MAX_DISPLAY_ROWS ))
			list_set_index_range ${PAGE_RANGE_TOP} ${PAGE_RANGE_BOT}
			PAGE_BREAK=false # Reset
		elif [[ ${_HOLD_PAGE} == 'true' ]];then
			PAGE=${_CURRENT_PAGE}
			PAGE_RANGE_TOP=$(( (_CURRENT_PAGE - 1) * MAX_DISPLAY_ROWS + 1 ))
			PAGE_RANGE_BOT=$(( (PAGE_RANGE_TOP - 1) + MAX_DISPLAY_ROWS ))
			list_set_index_range ${PAGE_RANGE_TOP} ${PAGE_RANGE_BOT}
			_HOLD_PAGE=false # Reset
		fi

		_CURRENT_PAGE=${PAGE} # Store current page position

		LIST_RANGE=($(list_get_index_range ))
		PAGE_RANGE_TOP=${LIST_RANGE[1]}
		PAGE_RANGE_BOT=${LIST_RANGE[2]}

		[[ ${PAGE_RANGE_BOT} -gt ${MAX_ITEM} ]] && PAGE_RANGE_BOT=${MAX_ITEM} # Page boundary check

		[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: ${WHITE_FG}GENERATING HEADER${RESET}"
		list_do_header ${PAGE} ${MAX_PAGE}
		#tcup 10 40; echo -n "${0}: DIR_KEY(PAGE):${DIR_KEY} _CURRENT_ARRAY:${_CURRENT_ARRAY} _CURRENT_CURSOR:${_CURRENT_CURSOR}"

		[[ ${_NO_TOP_OFFSET} == 'false' ]] && tcup ${TOP_OFFSET} 0 # Place cursor
		 
		# Initialize page display
		_LIST_NDX=$(( PAGE_RANGE_TOP - 1 )) # Initialize page top
		[[ -n ${_PAGE_CALLBACK_FUNC} ]] && ${_PAGE_CALLBACK_FUNC} ${PAGE_RANGE_TOP} ${PAGE_RANGE_BOT}

		[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: ${WHITE_FG}DISPLAYING LIST${RESET}"
		for (( R=0; R<${MAX_DISPLAY_ROWS}; R++ ));do
			[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} && -n ${_LIST[${_LIST_NDX}]} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _LIST display loop - ROW:${R} _LIST_NDX:${_LIST_NDX} - _LIST:${_LIST[${_LIST_NDX}]}"

			((_LIST_NDX++)) # Increment array index
			if [[ ${_LIST_NDX} -le ${MAX_ITEM} ]];then
				OUT=${_LIST_NDX}
				[[ ${_LIST_SELECTED[${OUT}]} -eq 1 ]] && SHADE=${REVERSE} || SHADE=''
				list_item init ${_LIST_LINE_ITEM} $(( TOP_OFFSET + R )) 0
			else
				printf "\n" # Output filler
			fi
		done

		# Page is displayed; initialize navigation
		if [[ ${_HOLD_CURSOR} == 'true' ]];then
			_LIST_NDX=${_CURRENT_ARRAY} # Hold array position
			CURSOR_NDX=${_CURRENT_CURSOR} # Hold cursor position
			[[ ${_LIST_SELECTED[${_LIST_NDX}]} -eq 1 ]] && SHADE=${REVERSE} || SHADE='' 
			[[ ${_ACTIVE_SEARCH} == 'false' ]] && list_item high ${_LIST_LINE_ITEM} $(( TOP_OFFSET + CURSOR_NDX - 1 )) 0 # Highlight current item
			_HOLD_CURSOR=false # Reset
		else
			_LIST_NDX=${PAGE_RANGE_TOP} # Page top
			CURSOR_NDX=1 # Page top
			[[ ${_LIST_SELECTED[${_LIST_NDX}]} -eq 1 ]] && SHADE=${REVERSE} || SHADE='' 
			[[ ${_ACTIVE_SEARCH} == 'false' ]] && list_item high ${_LIST_LINE_ITEM} ${TOP_OFFSET} 0 # Highlight first item
		fi

#		if [[ ${_ACTIVE_SEARCH} == 'true' ]];then
#			[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: ${WHITE_FG}LIST DISPLAYED _ACTIVE_SEARCH:${_ACTIVE_SEARCH}${RESET} REPOSITIONING CURSOR"
#			_LIST_NDX=${_TARGET_NDX} # Hold array position
#			list_item high ${_LIST_LINE_ITEM} $(( TOP_OFFSET + ${_TARGET_NDX} - 1 )) 0 # Highlight current item
#		fi

		[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: ${WHITE_FG}STARTING NAVIGATION${RESET}"
		# Main loop for user navigation
		while true;do
			LAST_LIST_NDX=${_LIST_NDX} # Store current index
			_CURRENT_CURSOR=${CURSOR_NDX} # Store current cursor position

			# Partial page boundary
			[[ ${PAGE} -eq ${MAX_PAGE} ]] && MAX_CURSOR=$(( (MAX_ITEM - PAGE_RANGE_TOP) + 1 )) || MAX_CURSOR=${MAX_DISPLAY_ROWS}
	
			# WAIT FOR INPUT
			KEY=$(get_keys ${USER_PROMPT})
			_CBQ_KEY=$(list_is_CBQ ${KEY})

			case ${KEY} in
				1) DIR_KEY=u;((CURSOR_NDX--));_LIST_NDX=$(list_set_index ${DIR_KEY} ${_LIST_NDX} ${PAGE_RANGE_TOP} ${PAGE_RANGE_BOT} ${MAX_ITEM});; # Up Arrow
				2) DIR_KEY=d;((CURSOR_NDX++));_LIST_NDX=$(list_set_index ${DIR_KEY} ${_LIST_NDX} ${PAGE_RANGE_TOP} ${PAGE_RANGE_BOT} ${MAX_ITEM});; # Down Arrow
				3) DIR_KEY=t;CURSOR_NDX=1;_LIST_NDX=${PAGE_RANGE_TOP};; # Left Arrow
				4) DIR_KEY=b;CURSOR_NDX=${MAX_CURSOR};_LIST_NDX=${PAGE_RANGE_BOT};; # Right Arrow
				5) DIR_KEY=p;PAGE_BREAK=true;break;; # PgUp 
				6) DIR_KEY=n;PAGE_BREAK=true;break;; # PgDn
				7) DIR_KEY=fp;PAGE_BREAK=true;break;; # Home
				8) DIR_KEY=lp;PAGE_BREAK=true;break;; # End
				32) [[ ${_SELECTABLE} == 'true' ]] && list_toggle_selected ${_LIST_NDX};; # Space
				47|60|62)	[[ ${KEY} -eq 47 ]] && MODE=new; # Forward slash
								[[ ${KEY} -eq 60 ]] && MODE=rev; # Less than
								[[ ${KEY} -eq 62 ]] && MODE=fwd; # Greater than
								list_search ${MODE} ${PAGE}
								[[ ${?} -ne 0 ]] && break
								if [[ ${_TARGET_PAGE} -eq ${PAGE} ]];then # Same page - move cursor
									CURSOR_NDX=${_TARGET_CURSOR}
									_LIST_NDX=${_TARGET_NDX}
									break
								else # Different page - navigate
#									PAGE_BREAK=true
#									DIR_KEY=${_TARGET_PAGE}
#									break
								fi;;
				a) [[ ${_SELECTABLE} == 'true' ]] && list_toggle_all ${PAGE_RANGE_TOP} ${TOP_OFFSET} ${MAX_DISPLAY_ROWS} ${MAX_ITEM} ${PAGE} ${MAX_PAGE} toggle;; # 'a' Toggle all
				b) DIR_KEY=lp;PAGE_BREAK=true;break;; # 'b' Top row last page
				c) [[ ${_SELECTABLE} == 'true' ]] && list_toggle_all ${PAGE_RANGE_TOP} ${TOP_OFFSET} ${MAX_DISPLAY_ROWS} ${MAX_ITEM} ${PAGE} ${MAX_PAGE} off;; # 'c' Clear
				h) DIR_KEY=t;CURSOR_NDX=1;_LIST_NDX=${PAGE_RANGE_TOP};; # 'h' Top Row current page
				j) DIR_KEY=d;((CURSOR_NDX++));_LIST_NDX=$(list_set_index ${DIR_KEY} ${_LIST_NDX} ${PAGE_RANGE_TOP} ${PAGE_RANGE_BOT} ${MAX_ITEM});; # 'j' Next row
				k) DIR_KEY=u;((CURSOR_NDX--));_LIST_NDX=$(list_set_index ${DIR_KEY} ${_LIST_NDX} ${PAGE_RANGE_TOP} ${PAGE_RANGE_BOT} ${MAX_ITEM});; # 'k' Prev row
				l) DIR_KEY=b;CURSOR_NDX=${MAX_CURSOR};_LIST_NDX=${PAGE_RANGE_BOT};; # 'l' Bottom Row current page
				n) DIR_KEY=n;PAGE_BREAK=true;break;; # 'n' Next page
				p) DIR_KEY=p;PAGE_BREAK=true;break;; # 'p' Prev page
				q) exit_request;break;;
				s) [[ ${_LIST_IS_SORTABLE} == 'true' ]] && list_sort;_HOLD_PAGE=true;break;; # 's' Sort
				t) DIR_KEY=fp;PAGE_BREAK=true;break;; # 't' Top row first page
				z) return -1;; # 'z' Quit loop
				${_CBC_KEY}) ${_KEY_CALLBACK_CONT_FUNC} ${_CBC_KEY};break;; # Callback and continue
				${_CBQ_KEY}) ${_KEY_QUIT_CALLBACKS[${_CBQ_KEY}]};break 2;; # Callback and quit
				0) SELECTED_COUNT=$(list_get_selected_count); # Enter
					_HOLD_PAGE=true;
					_HOLD_CURSOR=true;
					if [[ ${SELECTED_COUNT} -eq 0 ]];then
						break 2
					else
						if [[ ${_CLIENT_WARN} == 'true' ]];then
							list_warn_invisible_rows ${MAX_DISPLAY_ROWS} ${PAGE}
							break 2
						else
							if [[ ${_SELECTION_LIMIT} -ne 0 ]];then
								msg_box -p "${(C)ACTION_MSGS[1]} $(str_pluralize ${ACTION_MSGS[2]} ${SELECTED_COUNT})?|(y/n)"
							else
								msg_box -p "${(C)ACTION_MSGS[1]} ${SELECTED_COUNT} $(str_pluralize ${ACTION_MSGS[2]} ${SELECTED_COUNT})?|(y/n)"
							fi
							if [[ ${_MSG_KEY} == 'y' ]];then
								return ${SELECTED_COUNT}
							else
								continue
							fi
						fi
					fi
					;;
			esac

			# Cursor index boundary
			[[ ${CURSOR_NDX} -gt ${MAX_CURSOR} ]] && CURSOR_NDX=1
			[[ ${CURSOR_NDX} -lt 1 ]] && CURSOR_NDX=${MAX_CURSOR}

			# Clear highlight of last line output
			ITEM=${_LIST_NDX}; _LIST_NDX=${LAST_LIST_NDX} # Save value of _LIST_NDX
			list_item norm ${_LIST_LINE_ITEM} $(( TOP_OFFSET + _CURRENT_CURSOR - 1 )) 0 #_CURRENT_CURSOR is value before nav key

			# Highlight current line output
			_LIST_NDX=${ITEM} # Restore value of _LIST_NDX
			[[ ${_LIST_SELECTED[${_LIST_NDX}]} -eq 1 ]] && SHADE=${REVERSE} || SHADE='' 
			list_item high ${_LIST_LINE_ITEM} $(( TOP_OFFSET + CURSOR_NDX - 1 )) 0 # CURSOR_NDX is value after nav key

			_CURRENT_ARRAY=${ITEM} # Store current array position
			[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${0}: ${WHITE_FG}FINISHED NAVIGATION${RESET} - _LIST_NDX:${_LIST_NDX} CURSOR_NDX:${CURSOR_NDX} _CURRENT_ARRAY:${_CURRENT_ARRAY}"
		done
	done

	list_sort_clear_marker
	return $(list_get_selected_count)
}

list_select_range () {
	local -a RANGE=($@)
	local -a SELECTED
	local NDX=0

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: RANGE:${RANGE}"

	for (( NDX=${RANGE[1]}; NDX <= ${RANGE[2]}; NDX++ ));do
		[[ ${_CLEAR_GHOSTS} == 'false' && ${_LIST_SELECTED[${NDX}]} -ge ${_GHOST_ROW} ]] && continue
		SELECTED[${NDX}]=${NDX}
	done

	echo ${SELECTED}
}

list_set_action_msgs () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_ACTION_MSGS=(${@})
}

list_set_barlines () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_BARLINES=${1}
}

list_set_clear_ghosts () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_CLEAR_GHOSTS=${1}
}

list_set_client_warn () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_CLIENT_WARN=${1}
}

list_set_header () {
	local HDR_LINE=${1}

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} HEADER LINE:${WHITE_FG}${#_LIST_HEADER}${RESET}"

	[[ -z ${HDR_LINE:gs/ //} ]] && HDR_LINE="printf ' '"

	_LIST_HEADER+=${HDR_LINE}
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: RAW HEADER:${HDR_LINE}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ECHO HDR:${WHITE_FG}${#_LIST_HEADER}${RESET}:\"$(eval echo ${HDR_LINE})\""
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: EVAL HDR:${WHITE_FG}${#_LIST_HEADER}${RESET}:\"$(eval ${HDR_LINE})\""
}

list_set_header_break_color () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_HEADER_BREAK_COLOR=${1}
}

list_set_header_callback () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_HEADER_CALLBACK_FUNC=${1}
}

list_set_header_init () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_HEADER=()
}

list_set_index () {
	local KEY=${1}
	local ROW_NDX=${2}
	local PAGE_RANGE_TOP=${3}
	local PAGE_RANGE_BOT=${4}
	local MAX_ITEM=${5}
	local NDX

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${PAGE_RANGE_BOT} -gt ${MAX_ITEM} ]] && PAGE_RANGE_BOT=${MAX_ITEM}

	case ${KEY} in
		u)	((ROW_NDX--));NDX=${ROW_NDX};;
		d)	((ROW_NDX++));NDX=${ROW_NDX};;
	esac

	[[ ${NDX} -lt ${PAGE_RANGE_TOP} ]] && NDX=${PAGE_RANGE_BOT}
	[[ ${NDX} -gt ${PAGE_RANGE_BOT} ]] && NDX=${PAGE_RANGE_TOP}

	echo ${NDX}
}

list_set_index_range () {
	local TOP_NDX=${1}
	local BOT_NDX=${2}

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TOP_NDX:${TOP_NDX} BOT_NDX:${BOT_NDX}"

	[[ ${TOP_NDX} -lt 0 ]] && return 1 # TOP_NDX must be >= 0
	[[ ${BOT_NDX} -lt 0 ]] && return 1 # BOT_NDX must be >= 0

	_LIST_INDEX_RANGE=()
	_LIST_INDEX_RANGE+=${TOP_NDX}
	_LIST_INDEX_RANGE+=${BOT_NDX}

	return 0
}

list_set_key_callback_cont () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_CBC_KEY=${1}
	_KEY_CALLBACK_CONT_FUNC=${2}
}

list_set_key_callback_quit () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${#} -ne 2 ]] && return -1

	_KEY_QUIT_CALLBACKS[${1}]=${2}
}

list_set_key_msg () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_PROMPT_KEYS=${@}
}

list_set_line_item () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_LINE_ITEM=${@}
}

list_set_max_sort_col () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_LIST_SORT_COL_MAX=${1}
	if validate_is_integer ${_LIST_SORT_COL_MAX};then
		return
	else
		msg_box -p -PK "echo ${0}: error _LIST_SORT_COL_MAX not integer:${_LIST_SORT_COL_MAX}"
	fi
}

list_set_no_top_offset () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_NO_TOP_OFFSET=true
}

list_set_page_callback () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_PAGE_CALLBACK_FUNC=${1}
}

list_set_page_hold () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_HOLD_PAGE=true
}

list_set_prompt () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	[[ -n ${@} ]] && _LIST_PROMPT=${@}
}

list_set_searchable () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_LIST_IS_SEARCHABLE=${1}
}

list_set_selectable () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_SELECTABLE=${1}
}

list_set_select_callback () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_SELECT_CALLBACK_FUNC=${1}
}

list_set_selected () {
	local -i ROW=${1}
	local -i VAL=${2}

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${functrace[1]} ARGC:${#@} ROW:${ROW} VAL:${VAL}"

	_LIST_SELECTED[${ROW}]=${VAL}
}

list_set_selection_limit () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_SELECTION_LIMIT=${1}
}

list_set_sortable () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_LIST_IS_SORTABLE=${1}
}

list_set_sort_cols () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_SORT_COLS=(${@})
}

list_set_sort_defaults () {
	local ARG=${1}
	local COL=''
	local DIR=''

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	if [[ ${ARG} =~ ':' ]];then
		COL=$(cut -d: -f1 <<<${ARG})
		DIR=$(cut -d: -f2 <<<${ARG})
		_LIST_SORT_DIR_DEFAULT=${DIR}
		[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Parsed ARG and set defaults - COL:${COL} DIR:${DIR}"
	else
		COL=${ARG}
		[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Set default COL:${COL}"
	fi

	_LIST_SORT_COL_DEFAULT=${COL}
	if validate_is_integer ${_LIST_SORT_COL_DEFAULT};then
		return
	else
		msg_box -p -PK "echo ${0}: error _LIST_SORT_COL_DEFAULT not integer:${_LIST_SORT_COL_DEFAULT}"
	fi
}

list_set_sort_type () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_LIST_SORT_TYPE=${1}
}

list_show_key () {
	local KEY=${@}

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	[[ ${KEY} == '-' ]] && echo -n - '-' >&2 && return # Show dash and return
	echo -n ${KEY} >&2 # Show key value
}

list_sort () {
	local FIELD_MAX=0
	local SORT_COL=''
	local SORT_DIR=''
	
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if ! list_verify_sort_params;then
		return 1
	fi

	if [[ ${_LIST_SORT_COL_MAX} -eq 0 ]];then
		FIELD_MAX=$(get_delim_field_cnt ${_LIST[1]})
	else
		FIELD_MAX=${_LIST_SORT_COL_MAX}
	fi

	msg_box -p "Enter column to sort:|(1 through ${FIELD_MAX})"
	SORT_COL=${_MSG_KEY}

	if [[ ${SORT_COL} -lt 1 || ${SORT_COL} -gt ${FIELD_MAX} ]];then
		msg_box -p -PK "Invalid sort column:${SORT_COL}"
		return 1
	fi

	SORT_DIR=$(list_sort_toggle)
	_LIST_SET_DEFAULTS=false # List displayed - defaults already set

	case ${_LIST_SORT_TYPE} in
		assoc) list_sort_assoc ${SORT_COL} ${SORT_DIR};;
		flat) list_sort_flat _LIST ${SORT_COL} ${SORT_DIR} ${_LIST_DELIM};;
	esac
}

list_sort_assoc () {
	local SORT_COL=${1}
	local SORT_DIR=${2}
	local SORT_ARRAY=()
	local SORT_DIR=''
	local S

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	if ! list_verify_sort_params;then
		return 1
	fi

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _SORT_TABLE:${_SORT_TABLE}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _SORT_COL:${SORT_COL}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARRAY to sort:${SORT_ARRAY}"

	SORT_ARRAY=${_SORT_TABLE[${SORT_COL}]}
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _SORT_TABLE array name:${SORT_ARRAY}"
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _SORT_TABLE elements:${#${(P)SORT_ARRAY}}"

	[[ ${#${(P)SORT_ARRAY}} -eq 0 ]] && msg_box -p -PK "_SORT_TABLE ${(P)SORT_ARRAY} has no rows" && return 1 # Bounce

	if [[ ${SORT_DIR} == "a" ]];then
		[[ ${_DEBUG} -gt ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SORT ASCENDING"
		_LIST=("${(f)$(
			for S in ${(k)${(P)SORT_ARRAY}};do
				echo "${S}|${${(P)SORT_ARRAY}[${S}]}"
				[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: sort line:${S}|${${(P)SORT_ARRAY}[${S}]}"
			done | sort -t'|' -k2 | cut -d'|' -f1
		)}")
	else
		[[ ${_DEBUG} -gt ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SORT DESCENDING"
		_LIST=("${(f)$(
			for S in ${(k)${(P)SORT_ARRAY}};do
				echo "${S}|${${(P)SORT_ARRAY}[${S}]}"
				[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: sort line:${S}|${${(P)SORT_ARRAY}[${S}]}"
			done | sort -r -t'|' -k2 | cut -d'|' -f1
		)}")
	fi
}

list_sort_clear_marker () {
	# Exit callback
	if [[ -e ${_SORT_MARKER} ]];then
		/bin/rm -f ${_SORT_MARKER}
		[[ ${?} -ne 0 ]] && echo "WARNING: SORT MARKER not cleared" >&2
	fi
}

list_sort_flat () {
	local ARR_NAME=${1}
	local SORT_COL=${2}
	local SORT_DIR=${3}
	local DELIM=${4:='|'}
	local -A _CAL_SORT=(year G7 month F6 week E5 day D4 hour C3 minute B2 second A1)
	local -a ARR_SORTED=()
	local SORT_KEY=''
	local FLIP=false
	local L

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	# Invoke defaults if present
	if [[ ${_LIST_SET_DEFAULTS} == 'true' ]];then # Initialize display
		[[ -n ${_LIST_SORT_COL_DEFAULT} ]] && SORT_COL=${_LIST_SORT_COL_DEFAULT}
		[[ -n ${_LIST_SORT_DIR_DEFAULT} ]] && SORT_DIR=${_LIST_SORT_DIR_DEFAULT}
		[[ -n ${SORT_DIR} ]] && list_sort_set ${SORT_DIR}
	fi

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SORT_COL:${SORT_COL} SORT_DIR:${SORT_DIR}"

	for L in ${(P)ARR_NAME};do
		if [[ -n ${_SORT_COLS} ]];then
			SORT_KEY=$(cut -d "${DELIM}" -f ${_SORT_COLS[${SORT_COL}]} <<<${L}) # Mapped order
		else
			SORT_KEY=$(cut -d "${DELIM}" -f ${SORT_COL} <<<${L}) # Natural order
		fi

		[[ ${_DEBUG} -gt ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SORT_COL:${SORT_COL} SORT_KEY:${SORT_KEY}"

		[[ ${SORT_KEY} =~ 'year' ]] && ARR_SORTED+="${_CAL_SORT[year]}${SORT_KEY}${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ 'month' ]] && ARR_SORTED+="${_CAL_SORT[month]}${SORT_KEY}${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ 'week' ]] && ARR_SORTED+="${_CAL_SORT[week]}${SORT_KEY}}${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ 'day' ]] && ARR_SORTED+="${_CAL_SORT[day]}${SORT_KEY}${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ 'hour' ]] && ARR_SORTED+="${_CAL_SORT[hour]}${SORT_KEY}${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ 'min' ]] && ARR_SORTED+="${_CAL_SORT[minute]}${SORT_KEY}${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ 'sec' ]] && ARR_SORTED+="${_CAL_SORT[second]}${SORT_KEY}${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ '^[(]?\d{4}-\d{2}-\d{2}' ]] && ARR_SORTED+="${SORT_KEY[1,10]}${DELIM}${L}" && FLIP=true && continue
		[[ ${SORT_KEY} =~ '\d{4}$' ]] && ARR_SORTED+="ZZZZ${DELIM}$(echo ${L} | perl -pe 's/(.*)(\d{4})$/\2\1\2/g')" && continue
		[[ ${SORT_KEY} =~ '\d[.]\d\D' ]] && ARR_SORTED+="ZZZZ${DELIM}$(echo ${L} | perl -pe 's/([.]\d)(.*)((G|M).*)$/${1}0 ${3}/g')" && continue
		[[ ${SORT_KEY} =~ 'Mi?B' ]] && ARR_SORTED+="A888${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ 'Gi?B' ]] && ARR_SORTED+="B999${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ ':' ]] && ARR_SORTED+="B999${DELIM}${L}" && continue
		[[ ${SORT_KEY} =~ '-' ]] && ARR_SORTED+="A888${DELIM}${L}" && continue

		ARR_SORTED+="${SORT_KEY}${DELIM}${L}"
	done

	if [[ ${FLIP} == 'true' ]];then
		[[ ${SORT_DIR} == 'a' ]] && SORT_DIR=d || SORT_DIR=a # Reverse sort for numeric dates
	fi

	if [[ ${SORT_DIR} == "a" ]];then
		[[ ${_DEBUG} -gt ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SORT ASCENDING"
		_LIST=("${(f)$(
			for L in ${(on)ARR_SORTED};do
				cut -d"${DELIM}" -f2- <<<${L}
			done
		)}")
	else
		[[ ${_DEBUG} -gt ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SORT DESCENDING"
		_LIST=("${(f)$(
			for L in ${(On)ARR_SORTED};do
				cut -d"${DELIM}" -f2- <<<${L}
			done
		)}")
	fi

	if [[ ${FLIP} == 'true' ]];then
		[[ ${SORT_DIR} == 'd' ]] && SORT_DIR=a || SORT_DIR=d # Undo flip
	fi

	if [[ ${ARR_NAME} != "_LIST" ]];then # Call expects data
		for L in ${_LIST};do
			echo "${L}"
		done
	fi
}

list_sort_get () {
	echo $(<${_SORT_MARKER})
}

list_sort_set () {
	echo ${1} > ${_SORT_MARKER}
}

list_sort_toggle () {
	local -A DIR_TOGGLE=(a d d a)
	local SORT_DIR

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO} SORT_DIR:${SORT_DIR}"

	SORT_DIR=$(list_sort_get)
	SORT_DIR=${DIR_TOGGLE[${SORT_DIR}]}
	list_sort_set ${SORT_DIR}

	echo $(<${_SORT_MARKER})
}

list_toggle_all () {
	local _LIST_NDX=${1}
	local TOP_OFFSET=${2}
	local MAX_DISPLAY_ROWS=${3}
	local MAX_ITEM=${4}
	local PAGE=${5}
	local MAX_PAGE=${6}
	local ACTION=${7} 
	local -a SELECTED
	local CURSOR_NDX=1
	local FIRST_ITEM=$(( (PAGE * MAX_DISPLAY_ROWS) - MAX_DISPLAY_ROWS + 1 ))
	local LAST_ITEM=$(( PAGE * MAX_DISPLAY_ROWS ))
	local HIGHLIGHTING=false
	local OUT
	local S R

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}:  _LIST_NDX:${_LIST_NDX}, TOP_OFFSET:${TOP_OFFSET}, MAX_DISPLAY_ROWS:${MAX_DISPLAY_ROWS}, MAX_ITEM:${MAX_ITEM}, PAGE:${PAGE}, ACTION:${ACTION}, FIRST_ITEM:${FIRST_ITEM}, LAST_ITEM:${LAST_ITEM}"

	[[ ${LAST_ITEM} -gt ${MAX_ITEM} ]] && LAST_ITEM=${MAX_ITEM} # Partial page

	if [[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]];then
		dbg "${functrace[1]} called ${0}:${LINENO}:  SELECTED:${#SELECTED}, FIRST_ITEM:${FIRST_ITEM}, LAST_ITEM:${LAST_ITEM}"
		dbg "${functrace[1]} called ${0}:${LINENO}:  MAX_ITEM:${MAX_ITEM}, MAX_PAGE:${MAX_PAGE}"
	fi

	if [[ ${ACTION} == 'toggle' ]];then # Mark/unmark all
		[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}:  ACTION:${ACTION}"
		[[ ${_LIST_SELECTED_PAGE[${PAGE}]} -eq 1 ]] && _LIST_SELECTED_PAGE[${PAGE}]=0 || _LIST_SELECTED_PAGE[${PAGE}]=1 # Toggle state

		if [[ ${MAX_PAGE} -gt 1 && ${_LIST_SELECTED_PAGE[${PAGE}]} -eq 1 ]];then # Prompt only for setting range
			msg_box -p -P"(A)ll, (P)age, or (N)one" "Select Range"
			case ${_MSG_KEY:l} in
				a) SELECTED=($(list_select_range 1 ${MAX_ITEM})); _LIST_SELECTED_PAGE[0]=1;;
				p) SELECTED=($(list_select_range ${FIRST_ITEM} ${LAST_ITEM})); _LIST_SELECTED_PAGE[0]=0;;
				*) SELECTED=();;
			esac
			msg_box_clear

			[[ -z ${SELECTED} ]] && return
		else # Set clearing scope - all or page
			if [[ ${_LIST_SELECTED_PAGE[0]} -eq 1 ]];then # All was set
				SELECTED=($(list_select_range 1 ${MAX_ITEM})) && _LIST_SELECTED_PAGE[0]=0
			else
				SELECTED=($(list_select_range ${FIRST_ITEM} ${LAST_ITEM}))
			fi
		fi
	else
		_LIST_SELECTED_PAGE[${PAGE}]=0 # Clear - unmark page
		_LIST_SELECTED_PAGE[0]=0 # Clear - unmark all
		SELECTED=($(list_select_range 1 ${MAX_ITEM}))
		_MARKED=()
	fi

	for S in ${SELECTED};do
		_LIST_SELECTED[${S}]=${_LIST_SELECTED_PAGE[${PAGE}]}
	done

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}:  _HEADER_CALLBACK_FUNC:${_HEADER_CALLBACK_FUNC}"
	[[ -n ${_HEADER_CALLBACK_FUNC} ]] && ${_HEADER_CALLBACK_FUNC} 0 "${0}|${_LIST_SELECTED_PAGE[${PAGE}]}"

	tcup ${TOP_OFFSET} 0
	for (( R=0; R<${MAX_DISPLAY_ROWS}; R++ ));do
		tcup $(( TOP_OFFSET + CURSOR_NDX - 1 )) 0
		if [[ ${_LIST_NDX} -le ${MAX_ITEM} ]];then
			OUT=${_LIST_NDX}

			if [[ $_BARLINES == 'true' ]];then
				BARLINE=$((_LIST_NDX % 2 )) # Barlining 
				[[ ${BARLINE} -ne 0 ]] && BAR=${BLACK_BG} || BAR="" # Barlining
			fi

			if [[ ${_LIST_SELECTED[${OUT}]} -eq 1 ]];then
				_SELECT_ALL=true
				SHADE=${REVERSE}
			else
				_SELECT_ALL=false
				SHADE=''
			fi

			eval ${_LIST_LINE_ITEM} # Output the line
			[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}:  _LIST_LINE_ITEM:${_LIST_LINE_ITEM}"
		else
			printf "\n" # Output filler
		fi
		((_LIST_NDX++))
		((CURSOR_NDX++))
	done

	list_do_header ${PAGE} ${MAX_PAGE}
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}:  PAGE:${PAGE}, MAX_PAGE:${MAX_PAGE}"
}

list_toggle_selected () {
	local ROW_NDX=${1}
	local COUNT=$(list_get_selected_count)

	if [[ -n ${_SELECT_CALLBACK_FUNC} ]];then
		${_SELECT_CALLBACK_FUNC} ${ROW_NDX}
		[[ ${?} -ne 0 ]] && return
	fi

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ROW_NDX:${ROW_NDX} _CLEAR_GHOSTS:${_CLEAR_GHOSTS} _SELECTION_LIMIT:${_SELECTION_LIMIT}"

	[[ ${_CLEAR_GHOSTS} == 'false' && ${_LIST_SELECTED[${ROW_NDX}]} -ge ${_GHOST_ROW} ]] && return # Ignore ghosts

	if [[ ${_LIST_SELECTED[${ROW_NDX}]} -ne 1 ]];then
		if [[ ${_SELECTION_LIMIT} -ne 0 && ${COUNT} -gt $((_SELECTION_LIMIT - 1 )) ]];then
			msg_box -p -PK "Selection is limited to ${_SELECTION_LIMIT}"
			msg_box_clear
			return # Ignore over limit
		fi
		list_set_selected ${ROW_NDX} 1 
		[[ -n ${_HEADER_CALLBACK_FUNC} ]] && ${_HEADER_CALLBACK_FUNC} ${ROW_NDX} "${0}|1" # All on
	else
		list_set_selected ${ROW_NDX} 0
		[[ -n ${_HEADER_CALLBACK_FUNC} ]] && ${_HEADER_CALLBACK_FUNC} ${ROW_NDX} "${0}|0" # All off
	fi

	list_do_header ${PAGE} ${MAX_PAGE}
}

list_validate_selection () {
	local -a KEYLIST
	local -A OPTION
	local -a R1
	local -a R2
	local -a SELECTED
	local -a NDX_RANGE
	local K X MSG
	local RC

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${1} == '-r' ]] && OPTION[no_range_check]=1 && shift

	KEYLIST=(${@})
	KEYLIST=("${(f)$(echo ${KEYLIST} | grep -o .)}")
	KEYLIST=$(list_parse_series ${KEYLIST})

	R1=()
	R2=()
	SELECTED=()
	for K in ${=KEYLIST};do
		if [[ ${K[1,1]} =~ "[BE]" ]];then
			case ${K[1,1]} in
				B) R1+=${K[2,${#K}]};continue;;
				E) R2+=${K[2,${#K}]};continue;;
			esac
		fi
		SELECTED+=${K} # Non range element
	done

	# Handle range elements
	if [[ -n ${R1} ]];then
		for (( X=1;X<=${#R1};X++ ));do
			SELECTED+=$(echo {${R1[${X}]}..${R2[${X}]}})
		done
	fi

	RC=0
	if [[ ${OPTION[no_range_check]} -ne 1 ]];then
		NDX_RANGE=($(list_get_index_range ))
		MSG=$(list_is_valid_selection ${NDX_RANGE[1]} ${NDX_RANGE[-1]} ${SELECTED})
		RC=$?
	fi

	if [[ ${RC} -eq 0 ]];then
		echo ${(on)SELECTED}

		return 0
	else
		echo "Invalid Selection"

		return 1
	fi
}

list_verify_sort_params () {
	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO} Inspecting _LIST_SORT_COL_MAX:${_LIST_SORT_COL_MAX}"
	if ! validate_is_integer ${_LIST_SORT_COL_MAX};then
		msg_box -p -PK "Invalid sort column:${_LIST_SORT_COL_MAX}"
		return 1
	fi

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO} Inspecting _LIST_SORT_TYPE:${_LIST_SORT_TYPE}"
	if [[ ${_LIST_SORT_TYPE} == 'assoc' ]];then
		if [[ -z ${_SORT_TABLE} ]];then
			msg_box -p -PK "_SORT_TABLE:${#_SORT_TABLE} is not populated"
			return 1
		fi
	fi

	return 0
}

list_warn_invisible_rows () {
	local MAX_DISPLAY_ROWS=${1}
	local PAGE=${2}
	local FIRST_ITEM=$(( (PAGE * MAX_DISPLAY_ROWS - MAX_DISPLAY_ROWS) + 1 ))
	local LAST_ITEM=$(( PAGE * MAX_DISPLAY_ROWS ))
	local S

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${LAST_ITEM} -gt ${MAX_ITEM} ]] && LAST_ITEM=${MAX_ITEM} # Partial page

	# Warn user of marked rows not on current page
	_OFFSCREEN_ROWS_MSG=''
	for S in ${(k)_LIST_SELECTED};do
		if [[ ${S} -ge ${FIRST_ITEM} && ${S} -le ${LAST_ITEM}  ]];then
			continue 
		else
			[[ ${_LIST_SELECTED[${S}]} -eq 0 || ${_LIST_SELECTED[${S}]} -ge ${_GHOST_ROW} ]] && continue 
			_OFFSCREEN_ROWS_MSG="(<w><I>there are marked rows on other pages<N>)|"
			break
		fi
	done
}

list_write_to_file () {
	local ALIST=(${@})
	local L

	[[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if [[ -n ${ALIST[1]} ]];then
		[[ -e ${_SCRIPT}.out ]] && rm -f ${_SCRIPT}.out
		msg_box -c -p "Writing ${#ALIST} list $(str_pluralize item) to file: ${_SCRIPT}.out|Press any key"
		for L in ${ALIST};do
			echo ${L} >> ${_SCRIPT}.out
		done
	else
		msg_box -c -p "List is empty - nothing to write|Press any key"
	fi
}

