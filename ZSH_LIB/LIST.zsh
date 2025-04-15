# LIB Dependencies
_DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh PATH.zsh STR.zsh TPUT.zsh UTILS.zsh VALIDATE.zsh"

# LIB Declarations
typeset -A _KEY_CALLBACKS=()
typeset -A _CBK_RET=()
typeset -A _LIST_SELECTED=()
typeset -A _LIST_SELECTED_PAGE=() # Selected rows by page
typeset -A _PAGES=()
typeset -A _PAGE_DATA=()
typeset -A _SORT_DATA=()
typeset -a _LIST=() # Holds the values to be managed by the menu
typeset -a _SCREEN=() # Holds the displayed content
typeset -a _LIST_ACTION_MSGS=() # Holds text for contextual prompts
typeset -a _LIST_HEADER=() # Holds header lines
typeset -a _MARKED=()
typeset -a _TARGETS=() # Target indexes

# LIB Vars
_ACTIVE_SEARCH=false
_BARLINES=false
_REUSE_STALE=false
_CLIENT_WARN=true
_CURSOR_NDX=0
_HEADER_CALLBACK_FUNC=''
_LINE_MARKER=')'
_LIST_HEADER_LINES=0
_KEY_CALLBACK_CONT_FUNC=''
_KEY_CALLBACK_QUIT_FUNC=''
_LAST_PAGE=?
_LIST_DELIM='|'
_LIST_HEADER_BREAK=false
_LIST_HEADER_BREAK_COLOR=${WHITE_FG}
_LIST_HEADER_BREAK_LEN=0
_LIST_IS_SEARCHABLE=false
_LIST_IS_SORTABLE=false
_LIST_LINE_ITEM=''
_LIST_NDX=0
_LIST_PROMPT=''
_LIST_SELECT_NDX=0
_LIST_SELECT_ROW=0
_LIST_SELECT_PROMPT_STYLE=none
_MARKER=${_LINE_MARKER}
_MARKERS=false
_MAX_DISPLAY_ROWS=0
_MSG_KEY=n
_NO_TOP_OFFSET=false
_OFF_SCREEN_ROWS_MSG=''
_PAGE_CALLBACK_FUNC=''
_PROMPT_KEYS=''
_LIST_RESTORE_POS=false
_LIST_RESTORE_POS_RESET=false
_SEARCH_MARKER="${BOLD}${RED_FG}\u25CF${RESET}"
_USED_MARKER="${BOLD}${MAGENTA_FG}\u25CA${RESET}"
_LIST_IS_SELECTABLE=true
_SELECTION_LIMIT=0
_SELECT_ACTION='do action'
_SELECT_ALL=false
_SELECT_CALLBACK_FUNC=''
_LIST_TAG_FILE="/tmp/$$.${0:t}.state"
_TARGET_CURSOR=1
_TARGET_KEY=''
_TARGET_NDX=1
_TARGET_PAGE=1

# LIB Functions
list_add_header_break () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_HEADER_BREAK=true
}

list_clear_header () {
	_LIST_HEADER=()
}

list_clear_selected () {
	local NDX=${1}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_SELECTED[${NDX}]=${_AVAIL_ROW}
}

list_display_page () {
	local HILITE=${1}
	local -A PG_LIMITS=($(list_get_page_limits))
	local R=0
	local X_POS=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${_LIST_RESTORE_POS} == 'true' ]] && list_get_position

	if [[ ${_PAGE_DATA[RESTORE]} == 'true' ]];then
		_PAGE_DATA[PAGE]=$(list_find_page ${_PAGE_DATA[POS_NDX]})
		PG_LIMITS=($(list_get_page_limits))
	fi

	[[ ${HILITE} == 'nohilite' ]] && HILITE=false || HILITE=true 

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${WHITE_FG}GENERATING HEADER FOR PAGE:${_PAGE_DATA[PAGE]}${RESET}"

	list_do_header ${_PAGE_DATA[PAGE]} ${_PAGE_DATA[MAX_PAGE]}

	_LIST_NDX=$(( PG_LIMITS[TOP] - 1 )) # Initialize page top

	[[ -n ${_PAGE_CALLBACK_FUNC} ]] && ${_PAGE_CALLBACK_FUNC} ${PG_LIMITS[TOP]} ${PG_LIMITS[BOT]}

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${WHITE_FG}DISPLAYING LIST FOR PAGE:${_PAGE_DATA[PAGE]}${RESET}"

	_SCREEN=()

	for (( R=1; R <= _MAX_DISPLAY_ROWS; R++ ));do
		((_LIST_NDX++))
		X_POS=$(( R + _PAGE_DATA[TOP_OFFSET] - 1 ))
		if [[ ${X_POS} -le ${PG_LIMITS[MAX_CURSOR]} ]];then
			tcup ${X_POS} 0;tput el
			list_item init ${_LIST_LINE_ITEM} ${X_POS} 0
		else
			tcup ${X_POS} 0;tput el
		fi
	done

	if [[ ${_PAGE_DATA[RESTORE]} == 'true' ]];then
		_LIST_NDX=${_PAGE_DATA[POS_NDX]} # Initialize page position
		_CURSOR_NDX=${_PAGE_DATA[POS_CUR]}
		_PAGE_DATA[RESTORE]=false
	else
		_LIST_NDX=${PG_LIMITS[TOP]} # Initialize page top
		_CURSOR_NDX=${_PAGE_DATA[TOP_OFFSET]}
	fi

	[[ ${HILITE} == 'true' ]] && list_item high ${_LIST_LINE_ITEM} ${_CURSOR_NDX}  0
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

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"


	for (( L=1; L<=${#_LIST_HEADER}; L++ ));do
		HDR_LINE=$(eval ${_LIST_HEADER[${L}]})
		CLEAN_HDR=$(str_strip_ansi <<<${HDR_LINE})
		[[ ${#CLEAN_HDR} > ${LONGEST_HDR} ]] && LONGEST_HDR=${#CLEAN_HDR}
	done

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: HEADER COUNT:${#_LIST_HEADER} PAGE=${PAGE} MAX_PAGE=${MAX_PAGE} SELECTED_COUNT=${SELECTED_COUNT}"
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: LONGEST_HDR:${LONGEST_HDR} (before any modifications)"

	# Position cursor
	tcup 0 0
	tput el

	for (( L=1; L<=${#_LIST_HEADER}; L++ ));do
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Processing header 1 of ${#_LIST_HEADER}"
		if [[ -n ${_LIST_HEADER[${L}]} ]];then

			HDR_LINE=$(eval ${_LIST_HEADER[${L}]})
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: (eval) HEADER LINE:${L} -> ${HDR_LINE}"


			if [[ ${L} -eq 1 ]];then # Top line
			 # Prepend script name
				SCRIPT_TAG=$(eval ${SCRIPT_TAG}) && HDR_LINE="${SCRIPT_TAG} ${HDR_LINE}" && CLEAN_HDR=$(str_strip_ansi <<<${HDR_LINE})
				[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Added header name tag:${HDR_LINE}"
			fi

			[[ ${_LIST_HEADER[${L}]} =~ '_PG' ]] && HDR_PG=true # Do page numbering

				if [[ ${HDR_PG} == 'true' ]];then # Append page number
					PG_TAG=$(eval "printf 'Page:${WHITE_FG}%d${RESET} of ${WHITE_FG}%d${RESET}' ${PAGE} ${MAX_PAGE}") && CLEAN_TAG=$(str_strip_ansi <<<${PG_TAG})
					HDR_LEN=$(( ${#CLEAN_HDR} + ${#CLEAN_TAG} ))
					[[ ${LONGEST_HDR} -gt ${HDR_LEN} ]] && PAD_LEN=$(( LONGEST_HDR - HDR_LEN )) || PAD_LEN=1
					PG_TAG="$(str_rep_char ' ' ${PAD_LEN})${PG_TAG}"

					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: HDR_LEN:${HDR_LEN}, LONGEST_HDR:${LONGEST_HDR}, PAD_LEN:${PAD_LEN}"

					HDR_LINE="${HDR_LINE}${PG_TAG}"
					CLEAN_HDR=$(str_strip_ansi <<<${HDR_LINE})
					LONGEST_HDR=${#CLEAN_HDR} # This header will now be the longest

					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Added header page tag:${HDR_LINE}, LONGEST_HDR:${LONGEST_HDR}"

					HDR_PG=false
				fi
				
				tput el
				echo ${HDR_LINE}
			fi

			tcup ${L} 0
		done

		if [[ ${_LIST_HEADER_BREAK} == 'true' ]];then
			tput el && echo -n ${_LIST_HEADER_BREAK_COLOR} && str_unicode_line ${LONGEST_HDR} && echo -n ${RESET}
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Header break length:${LONGEST_HDR}"
		fi
}

list_find_page () {
	local NDX=${1}
	local -A PG_LIMITS=($(list_get_page_limits))
	local TOP
	local BOT
	local RANGE
	local P

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${NDX} -ge ${PG_LIMITS[TOP]} && ${NDX} -le ${PG_LIMITS[BOT]} ]] && echo ${_PAGE_DATA[PAGE]} && return 0 # Index is on current page
	
	for P in ${(onk)_PAGES};do
		RANGE=${_PAGES[${P}]}
		TOP=$(cut -d: -f1 <<<${RANGE})
		BOT=$(cut -d: -f2 <<<${RANGE})
		[[ ${NDX} -ge ${TOP} && ${NDX} -le ${BOT} ]] && echo ${P} && return 0 # Index is on this page
	done
	return 1 # NDX not found on any page
}

list_get_page_limits () {
	local RANGE=${_PAGES[${_PAGE_DATA[PAGE]}]}
	local TOP=$(cut -d: -f1 <<<${RANGE})
	local BOT=$(cut -d: -f2 <<<${RANGE})
	local MAX_CURSOR=$(( _PAGE_DATA[TOP_OFFSET] + _MAX_DISPLAY_ROWS - ( _MAX_DISPLAY_ROWS - (BOT - TOP) ) ))
	local MIN_CURSOR=$(( _PAGE_DATA[TOP_OFFSET] ))

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo "TOP ${TOP} BOT ${BOT} MAX_CURSOR ${MAX_CURSOR} MIN_CURSOR ${MIN_CURSOR}"
}

list_get_position () {
	local NDX=0
	local CUR=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	if [[ ${_LIST_RESTORE_POS_RESET} == 'true' ]];then
		_PAGE_DATA[POS_NDX]=''
		_PAGE_DATA[POS_CUR]=''
		_LIST_RESTORE_POS_RESET='false'
	elif [[ -e ${_LIST_TAG_FILE} ]];then
		IFS='|' read -r NDX CUR < ${_LIST_TAG_FILE} # Retrieve stored position
		[[ -n ${NDX} ]] && _PAGE_DATA[POS_NDX]=${NDX} || _PAGE_DATA[POS_NDX]=''
		[[ -n ${CUR} ]] && _PAGE_DATA[POS_CUR]=${CUR} || _PAGE_DATA[POS_CUR]=''
		[[ -n ${_PAGE_DATA[POS_NDX]} && -n ${_PAGE_DATA[POS_CUR]} ]] && _PAGE_DATA[RESTORE]=true || _PAGE_DATA[RESTORE]=false
		/bin/rm -f ${_LIST_TAG_FILE}
	fi
}

list_get_selected () {
	local S

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -z ${_LIST_SELECTED} ]] && echo 0 && return 1

	for S in ${(k)_LIST_SELECTED};do
		[[ ${_LIST_SELECTED[${S}]} -ne ${_SELECTED_ROW}  ]] && continue
		echo ${S}
	done
}

list_get_selected_count () {
	local COUNT=0
	local S

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -z ${_LIST_SELECTED} ]] && echo 0 && return 1

	for S in ${(k)_LIST_SELECTED};do
		[[ ${_LIST_SELECTED[${S}]} -ne ${_SELECTED_ROW} ]] && continue
		((COUNT++))
	done

	echo ${COUNT}
}

list_get_selection_limit () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo ${_SELECTION_LIMIT}
}

list_is_valid_selection () {
	local -a SELECTED
	local MAX
	local MIN
	local N

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	MIN=${1};shift
	MAX=${1};shift
	SELECTED=(${@})

	for N in ${SELECTED};do
		if ! validate_is_integer ${N};then
			return 1
		elif ! list_is_within_range ${N} ${MIN} ${MAX};then
			return 1
		elif [[ ${_REUSE_STALE} == 'false' && ${_LIST_SELECTED[${N}]} -eq ${_STALE_ROW} && ${_SELECT_ALL} == 'false' ]];then # Cannot select stale row; select 'all' is the only exception
			return 1
		fi
	done

	return 0
}

list_is_within_range () {
	local NDX=${1}
	local MIN=${2}
	local MAX=${3}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

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
	local BARLINE BAR

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ARGV - MODE:${MODE} LINE_ITEM LEN:${#LINE_ITEM} X_POS:${X_POS} Y_POS:${Y_POS} TOP_OFFSET:${_PAGE_DATA[TOP_OFFSET]} _LIST_NDX:${_LIST_NDX}"

	_MARKER=${_LINE_MARKER}

	MARKER=${_TARGETS[(r)*:${X_POS}:${_PAGE_DATA[PAGE]}*]}
	[[ -n ${MARKER} ]] && _MARKER=${_SEARCH_MARKER} && _MARKERS=true
	[[ ${_DEBUG} -ge ${_HIGH_DBG} && -n ${MARKER} ]] && dbg "${0}: MARKER:${MARKER}"

	tput rmso # Clear any previous smso

	case ${MODE} in
		high) tput smso;;
		norm) tput rmso;;
		select) SHADE=${REVERSE};tput smso;;
		deselect) SHADE='';tput smso;;
	esac

	tcup ${X_POS} ${Y_POS}

	if [[ ${_BARLINES} == 'true' ]];then
		BARLINE=$(( _LIST_NDX % 2 )) # Barlining 
		[[ ${BARLINE} -ne 0 ]] && BAR=${BLACK_BG} || BAR="" # Barlining
	fi

	[[ ${_LIST_SELECTED[${_LIST_NDX}]} -eq ${_SELECTED_ROW} ]] && SHADE=${REVERSE} || SHADE=''
	[[ ${_LIST_SELECTED[${_LIST_NDX}]} -eq ${_USED_ROW} ]] && _MARKER=${_USED_MARKER}

	if [[ ${MODE} == 'init' ]];then # Avoid 2nd eval; print from _SCREEN if init
		_SCREEN+=$(eval ${LINE_ITEM})
		echo -n ${_SCREEN[${#_SCREEN}]}
	else
		eval ${LINE_ITEM} # Output line
	fi

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: _LIST DATA:${_LIST[${_LIST_NDX}]}"

	_CURSOR_NDX=${X_POS}
}

list_nav_handler () {
	local KEY=${1}
	local -A PG_LIMITS=()
	local MODE=''
	local PG=0
	local C

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	if [[ ${KEY} == 'u' ]];then      # Up row
		list_item norm ${_LIST_LINE_ITEM} ${_CURSOR_NDX} 0
		_LIST_NDX=$(list_next_index $(( _LIST_NDX -= 1 )))
		_CURSOR_NDX=$(list_next_cursor $(( _CURSOR_NDX -= 1 )))
		list_item high ${_LIST_LINE_ITEM} ${_CURSOR_NDX} 0

	elif [[ ${KEY} == 'd' ]];then    # Down row
		list_item norm ${_LIST_LINE_ITEM} ${_CURSOR_NDX} 0
		_LIST_NDX=$(list_next_index $(( _LIST_NDX += 1 )))
		_CURSOR_NDX=$(list_next_cursor $(( _CURSOR_NDX += 1 )))
		list_item high ${_LIST_LINE_ITEM} ${_CURSOR_NDX} 0

	elif [[ ${KEY} == 't' ]];then    # Top of page
		list_item norm ${_LIST_LINE_ITEM} ${_CURSOR_NDX} 0
		PG_LIMITS=($(list_get_page_limits))
		_LIST_NDX=${PG_LIMITS[TOP]}
		list_item high ${_LIST_LINE_ITEM} ${PG_LIMITS[MIN_CURSOR]} 0

	elif [[ ${KEY} == 'b' ]];then    # Bottom of page
		list_item norm ${_LIST_LINE_ITEM} ${_CURSOR_NDX} 0
		PG_LIMITS=($(list_get_page_limits))
		_LIST_NDX=${PG_LIMITS[BOT]}
		list_item high ${_LIST_LINE_ITEM} ${PG_LIMITS[MAX_CURSOR]} 0

	elif [[ ${KEY} == 'n' ]];then    # Next page
		_PAGE_DATA[PAGE]=$(list_next_page $((_PAGE_DATA[PAGE] += 1)))
		list_display_page

	elif [[ ${KEY} == 'p' ]];then    # Previous page
		_PAGE_DATA[PAGE]=$(list_next_page $((_PAGE_DATA[PAGE] -= 1)))
		list_display_page

	elif [[ ${KEY} == 'fp' ]];then   # First page
		_PAGE_DATA[PAGE]=1
		list_display_page

	elif [[ ${KEY} == 'lp' ]];then   # Last page
		_PAGE_DATA[PAGE]=${_PAGE_DATA[MAX_PAGE]}
		list_display_page

	elif [[ ${KEY} == 'sort' ]];then # Sort
		list_sort key
		list_display_page

	elif [[ ${KEY} =~ 'mark' ]];then # Search new
		if [[ ${_LIST_IS_SEARCHABLE} == 'false' ]];then
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SEARCH REJECTED: _LIST_IS_SEARCHABLE:${_LIST_IS_SEARCHABLE}"
			return # Ignore not searchable
		fi

		MODE=$(cut -d'_' -f2 <<<${KEY})
		list_search ${MODE} ${_PAGE_DATA[PAGE]}
		RC=${?}
		if [[ ${RC} -ne 0 ]];then
			_MARKER=${_LINE_MARKER}
			list_display_page
		else
			PG=$(list_find_page ${_TARGET_NDX})
			if [[ ${PG} -ne ${_PAGE_DATA[PAGE]} ]];then
				_PAGE_DATA[PAGE]=${PG}
				list_display_page nohilite # No initial highlight of cursor
			fi
			list_item norm ${_LIST_LINE_ITEM} ${_CURSOR_NDX} 0
			list_display_page nohilite # No initial highlight of cursor
			_LIST_NDX=${_TARGET_NDX}
			list_item high ${_LIST_LINE_ITEM} ${_TARGET_CURSOR} 0
		fi
	fi
}

list_next_cursor () {
	local CURSOR=${1}
	local -A PG_LIMITS=($(list_get_page_limits))

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${CURSOR} -gt ${PG_LIMITS[MAX_CURSOR]} ]] && CURSOR=${PG_LIMITS[MIN_CURSOR]}
	[[ ${CURSOR} -lt ${PG_LIMITS[MIN_CURSOR]} ]] && CURSOR=${PG_LIMITS[MAX_CURSOR]}

	echo ${CURSOR}
}

list_next_index () {
	local NDX=${1}
	local -A PG_LIMITS=($(list_get_page_limits))

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${NDX} -lt ${PG_LIMITS[TOP]} ]] && NDX=${PG_LIMITS[BOT]}
	[[ ${NDX} -gt ${PG_LIMITS[BOT]} ]] && NDX=${PG_LIMITS[TOP]}

	echo ${NDX}
}

list_next_page () {
	local PAGE=${1}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${PAGE} -lt 1 ]] && PAGE=${_PAGE_DATA[MAX_PAGE]}
	[[ ${PAGE} -gt ${_PAGE_DATA[MAX_PAGE]} ]] && PAGE=1

	echo ${PAGE}
}

list_quote_marked_elements () {
       local MARKED=(${@})
       local M
       local -a STR

       [[ ${_DEBUG} -ge ${_LIST_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

       for M in ${MARKED};do
               STR+=${(q)_LIST[${M}]}
       done

       echo ${STR}
}

list_reset () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_HEADER=()
	_LIST_PROMPT=''
	_LIST_SELECTED=()
	_MARKED=()
}

list_search () {
	local MODE=${1}
	local PAGE=${2} 
	local KEY=''
	local K_TEXT=''
	local RC

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} MODE:${MODE} PAGE:${PAGE}"

	case ${MODE} in
		new)		list_search_new ${PAGE}
					RC=${?}
					;;
		fwd|rev)	list_search_find ${MODE}
					RC=${?}
					;;
	esac

	[[ ${_DEBUG} -ge ${_MID_DETAIL} ]] && dbg "${0}: list_search_${MODE} RETURNED: ${RC}"

	if [[ ${RC} -eq 0 ]];then
		_ACTIVE_SEARCH=true
		KEY=${_TARGETS[(i)*next_target]} # Index of current target
		IFS=":" read _TARGET_NDX _TARGET_CURSOR _TARGET_PAGE K_TEXT <<<${_TARGETS[${KEY}]}
		[[ ${_DEBUG} -ge ${_MID_DETAIL} ]] && dbg "${0}: ${WHITE_FG}KEY:${KEY}, SEARCH TARGETS SET${RESET} - _TARGET_NDX:${_TARGET_NDX} _TARGET_CURSOR:${_TARGET_CURSOR} _TARGET_PAGE:${_TARGET_PAGE}"
	else
		_ACTIVE_SEARCH=false
	fi

	return ${RC}	
}

list_search_find () {
	local DIR=${1}
	local KEY=''
	local NEXT_TARGET=''
	local R C P T

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -z ${_TARGETS} ]] && return 1

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: DIR: ${DIR}"

	NEXT_TARGET=$(list_search_get_key ${DIR})
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: NEXT KEY: ${NEXT_TARGET}"

	IFS=":" read R C P T <<<${NEXT_TARGET}

	KEY=${_TARGETS[(i)*next_target]} # Index of last target
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: LAST KEY: ${KEY}"

	_TARGETS[${KEY}]=$(sed "s/next_target/seen/" <<<${_TARGETS[${KEY}]}) # Cancel last target
	_TARGETS[${T}]="${R}:${C}:${P}:next_target" # Set next_target

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: LAST_TARGET:${_TARGETS[${KEY}]}, NEXT_TARGET:${_TARGETS[${T}]}"

	return 0
}

list_search_get_key () {
	local MODE=${1}
	local NDX=0
	local CUR_TGT_NDX=0
	local MAX_TARGETS=${#_TARGETS}
	local R C P T

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	CUR_TGT_NDX=${_TARGETS[(i)*next_target]}
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CUR_TGT_NDX:${CUR_TGT_NDX} TARGET:${_TARGETS[${CUR_TGT_NDX}]}"

	[[ -z ${CUR_TGT_NDX} ]] && return 1

	case ${MODE} in
		fwd) [[ $(( CUR_TGT_NDX + 1 )) -gt ${MAX_TARGETS} ]] && NDX=1 || NDX=$(( CUR_TGT_NDX + 1 ));;
		rev) [[ $(( CUR_TGT_NDX - 1 )) -le 0 ]] && NDX=${MAX_TARGETS} || NDX=$(( CUR_TGT_NDX - 1 ));;
	esac

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: NDX:${CUR_TGT_NDX} NEXT TARGET:${_TARGETS[${NDX}]}"

	IFS=":" read R C P T <<<${_TARGETS[${NDX}]}

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: PARSED TARGET: R:${R} C:${C} P:${P} NDX:${NDX}"

	echo "${R}:${C}:${P}:${NDX}" # Pass the next index

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

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

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

	tcup $(( V_CTR + 4 )) $(( H_CTR + 2 )) # Position editor
	PROMPT="${E_RESET}${E_BOLD}Find${E_RESET}:"
	SEARCHTERM=$(inline_vi_edit ${PROMPT} "") # Call line editor

	msg_box_clear X Y ${HEIGHT} W  # Clear box containing inline edit 

	if [[ -z ${SEARCHTERM} ]];then # User entered nothing
		return 1
	fi

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: TARGET:${TARGET}"

	if ! list_search_set_targets ${SEARCHTERM};then
		for (( ROW=0; ROW<=${HEIGHT}; ROW++ ));do # Clear a space to place the MSG
			tcup $(( V_CTR + ROW )) ${H_CTR}
			tput ech ${#HDR}
		done

		msg_box -x${V_CTR} -y$(( H_CTR + 10 )) -p -PK "<m>List Search<N>| |\"<w>${SEARCHTERM}<N>\" - <r>NOT<N> found" 
		msg_box_clear

		return 1
	fi

	_TARGETS[1]="${_TARGETS[1]}:next_target" # Initialize first target

	return 0
}

list_search_set_targets () {
	local SEARCHTERM=${@}
	local BOT=0
	local TOP=0
	local C P R

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SEARCHTERM:${SEARCHTERM} SEARCHING LIST FOR TARGETS"

	_TARGETS=("${(f)$(
	for P in ${(onk)_PAGES};do
		IFS=":" read TOP BOT <<<${_PAGES[${P}]}
		for (( R=TOP; R<=BOT; R++ ));do
			C=$(( R - TOP + _PAGE_DATA[TOP_OFFSET] ))
			echo "${C}:${P}:${_LIST[${R}]}"
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SEARCHING in ${_LIST[${R}]} for ${SEARCHTERM}"
		done
	done | grep --color=never -ni -P ":.*${SEARCHTERM}.*" | perl -p -e "s/^(\d+:\d+:\d+)(.*)$/\1/" # Return key:NDX/CURSOR/PAGE
	)}")

	if ! arr_is_populated "${_TARGETS}";then
		[[ ${_DEBUG} -ge ${_MID_DETAIL} ]] && dbg "${0}: NO TARGETS FOUND"
		return 1
	fi

	[[ ${_DEBUG} -ge ${_MID_DETAIL} ]] && dbg "${0}: FOUND ${#_TARGETS} TARGETS - TARGET LIST:"
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "\n$(for R in ${_TARGETS};do echo ${WHITE_FG}${R}${RESET};done)"

	msg_box -c -t1 "Found: ${#_TARGETS} $(str_pluralize match ${#_TARGETS})"

	return 0
}

list_select () {
	local -a ACTION_MSGS=()
	local -a LIST_SELECTION=()
	local BARLINE=''
	local BARSHADE=''
	local BOT_OFFSET=3
	local CB_KEY=''
	local COLS=0
	local HDR_NDX=0
	local KEY=''
	local KEY_LINE=''
	local LINE_ITEM=''
	local LIST_DATA=''
	local MAX_ITEM=0
	local MAX_LINE_WIDTH=0
	local MAX_PAGE=0
	local MODE=''
	local NAV_KEY='unset'
	local NDX_SAVE=0
	local OUT=0
	local PAGE_BREAK=false
	local RC=0
	local REM=0
	local ROWS=$(tput lines)
	local SELECTED_COUNT=0
	local SELECTION_LIMIT=$(list_get_selection_limit)
	local SHADE=''
	local SORT_SOURCE="USER"
	local SWAP_NDX=''
	local TOP_OFFSET=0
	local SELECT_PROMPT=''
	local SEL_ALL=' '
	local L R S 

	# Initialization
	_LIST=(${@})
	_SELECT_ALL=false

	# Max line
	COLS=$(tput cols)
	MAX_LINE_WIDTH=$(( (COLS - ${#${#_LIST}}) - 10 )) # Display-cols minus width-of-line-number plus a 10 space margin

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} _LIST COUNT:${#_LIST}"
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: _LIST SAMPLE ROW: ${_LIST[1]}"

	# Calculate header lines
	[[ -z ${_LIST_HEADER} ]] && _LIST_HEADER+='printf "List of %-d items\tPage %-d of %-d \tSelected:%-d" ${MAX_ITEM} ${PAGE} ${MAX_PAGE} ${SELECTED_COUNT}' # Default header
	TOP_OFFSET=${#_LIST_HEADER}
	[[ ${_LIST_HEADER_BREAK} == 'true' ]] && ((TOP_OFFSET++))
	_LIST_HEADER_LINES=${TOP_OFFSET}

	# Boundaries
	_MAX_DISPLAY_ROWS=$(( ROWS - (TOP_OFFSET + BOT_OFFSET) ))
	_PAGES=($(list_set_pages))

	# Assign Defaults for Header, Prompt, and Line_Item formatting
	[[ -z ${_LIST_LINE_ITEM} ]] && _LIST_LINE_ITEM='printf "${BOLD}${_HILITE_COLOR}%*d${RESET}) ${SHADE}%s${RESET}\n" ${#MAX_ITEM} ${_LIST_NDX} ${${_LIST[${_LIST_NDX}]}[1,${MAX_LINE_WIDTH}]}'
	if [[ ${_LIST_IS_SELECTABLE} == 'true' ]];then
		SEL_ALL=" select <${WHITE_FG}a${RESET}>ll${RESET}, "
		[[ -n ${_LIST_PROMPT} ]] && SELECT_PROMPT=${_LIST_PROMPT} || SELECT_PROMPT="Hit <${GREEN_FG}SPACE${RESET}> to select then <${GREEN_FG}ENTER${RESET}> to ${_SELECT_ACTION}. ${WHITE_FG}Note${RESET}: <${GREEN_FG}ENTER${RESET}> will ${ITALIC}${WHITE_FG}exit${RESET} if none are selected"
	fi
	[[ -n ${_LIST_ACTION_MSGS[1]} ]] && ACTION_MSGS[1]=${_LIST_ACTION_MSGS[1]} || ACTION_MSGS[1]="process"
	[[ -n ${_LIST_ACTION_MSGS[2]} ]] && ACTION_MSGS[2]=${_LIST_ACTION_MSGS[2]} || ACTION_MSGS[2]="item"
	[[ -n ${_PROMPT_KEYS} ]] && KEY_LINE=$(eval ${_PROMPT_KEYS}) || KEY_LINE=$(printf "Press ${WHITE_FG}%s%s%s%s${RESET} Home End PgUp PgDn <${WHITE_FG}n${RESET}>ext, <${WHITE_FG}p${RESET}>rev, <${WHITE_FG}b${RESET}>ottom, <${WHITE_FG}t${RESET}>op, <${WHITE_FG}c${RESET}>lear, vi[${WHITE_FG}h,j,k,l${RESET}],${SEL_ALL}<${WHITE_FG}q${RESET}>uit${RESET}" $'\u2190' $'\u2191' $'\u2193' $'\u2192')
	[[ ${_LIST_IS_SORTABLE} == 'true' ]] && KEY_LINE+=", <${WHITE_FG}s${RESET}>ort"
	[[ ${_LIST_IS_SEARCHABLE} == 'true' ]] && KEY_LINE+=", \"${WHITE_FG}/${RESET}\" to ${WHITE_FG}search${RESET}"
	[[ -n ${KEY_LINE} ]] && SELECT_PROMPT="${KEY_LINE}\n${SELECT_PROMPT}"

	# Navigation Init
	_PAGE_DATA=(
		PAGE_STATE init 
		PAGE 1 
		MAX_PAGE ${#_PAGES} 
		MAX_ITEM ${#_LIST} 
		TOP_OFFSET ${TOP_OFFSET}
		LAST_PAGE 0
		RESTORE false
	)
	# End of Navigation Init

	# Sort Init
	if [[ ${_LIST_IS_SORTABLE} == 'true' ]];then
		if [[ -z ${_SORT_DATA} ]];then
			_SORT_DATA=(
				ORDER a
				COL 1
				MAXCOL 0
				DELIM '|'
				TYPE flat
				ARRAY '_LIST'
				TABLE 'null null'
			)
			SORT_SOURCE="GENERATED DEFAULT"
		else
			SORT_SOURCE="PASSED FROM APP"
		fi
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SORT INIT: _SORT_DATA:${(kv)_SORT_DATA} SORT_SOURCE:${SORT_SOURCE}"
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CALLING INITIAL SORT"
		list_sort # Invoke default sort
	fi
	# End of Sort Init
	 
	# Display current page of list items
	tput civis >&2
	tput clear
	list_display_page

	#_LIST_NDX=1
	#_CURSOR_NDX=$(( _LIST_NDX + _PAGE_DATA[TOP_OFFSET] - 1 ))

	# Main navigation loop
	while true;do
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${WHITE_FG}STARTING NAVIGATION FOR PAGE:${_PAGE_DATA[PAGE]}${RESET}"

		while true;do
			NAV_KEY=unset

			# WAIT FOR INPUT
			KEY=$(get_keys ${SELECT_PROMPT})

			[[ -n ${_KEY_CALLBACKS[${KEY}]} ]] && CB_KEY=${KEY} || CB_KEY='NA'

			case ${KEY} in
				1) NAV_KEY=u;break;;  # Up Arrow
				2) NAV_KEY=d;break;;  # Down Arrow
				3) NAV_KEY=t;break;;  # Left Arrow
				4) NAV_KEY=b;break;;  # Right Arrow
				5) NAV_KEY=p;break;;  # PgUp 
				6) NAV_KEY=n;break;;  # PgDn
				7) NAV_KEY=fp;break;; # Home
				8) NAV_KEY=lp;break;; # End
				47) NAV_KEY='mark_new';break;; # Forward slash
				60) NAV_KEY='mark_rev';break;; # Less than
				62) NAV_KEY='mark_fwd';break;; # Greater then
				t) NAV_KEY=fp;break;; # 't' Top row first page
				b) NAV_KEY=lp;break;; # 'b' Top row last page
				h) NAV_KEY=t;break;;  # 'h' Top Row current page
				l) NAV_KEY=b;break;;  # 'l' Bottom Row current page
				k) NAV_KEY=u;break;;  # 'k' Prev row
				j) NAV_KEY=d;break;;  # 'j' Next row
				p) NAV_KEY=p;break;;  # 'p' Prev page
				n) NAV_KEY=n;break;;  # 'n' Next page
				s) [[ ${_LIST_IS_SORTABLE} == 'true' ]] && NAV_KEY='sort';break;; # Sort
				32) [[ ${_LIST_IS_SELECTABLE} == 'true' ]] && list_toggle_selected;; # Space
				a)  [[ ${_LIST_IS_SELECTABLE} == 'true' ]] && list_toggle_all toggle;; # 'a' Toggle all
				c)  [[ ${_LIST_IS_SELECTABLE} == 'true' ]] && list_toggle_all clear;; # 'c' Clear
				q) exit_request; break;;
				z) return -1;; # 'z' Quit loop
				${CB_KEY}) ${_KEY_CALLBACKS[${CB_KEY}]}
					if [[ ${_CBK_RET[${CB_KEY}]} == 'true' ]];then
						break 2
					else
						break
					fi;;
				0) SELECTED_COUNT=$(list_get_selected_count); # Enter key
					[[ ${_LIST_RESTORE_POS} == 'true' ]] && list_set_position
					_PAGE_DATA[PAGE_STATE]='hold';
					if [[ ${SELECTED_COUNT} -eq 0 ]];then
						break 2
					else
						if [[ ${_CLIENT_WARN} == 'true' ]];then
							list_warn_invisible_rows
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
					fi;;
			esac
		done
		list_nav_handler ${NAV_KEY}
	done

	return $(list_get_selected_count)
}

list_select_range () {
	local -a RANGE=($@)
	local -a SELECTED
	local NDX=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} RANGE:${RANGE}"

	for (( NDX=${RANGE[1]}; NDX <= ${RANGE[2]}; NDX++ ));do
		[[ ${_REUSE_STALE} == 'false' && ${_LIST_SELECTED[${NDX}]} -eq ${_STALE_ROW} ]] && continue
		SELECTED[${NDX}]=${NDX}
	done

	echo ${SELECTED}
}

list_set_action_msgs () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_ACTION_MSGS=(${@})
}

list_set_barlines () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_BARLINES=${1}
}

list_set_client_warn () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_CLIENT_WARN=${1}
}

list_set_header () {
	local HDR_LINE=${1}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} HEADER LINE:${WHITE_FG}${#_LIST_HEADER}${RESET}"

	[[ -z ${HDR_LINE:gs/ //} ]] && HDR_LINE="printf ' '"

	_LIST_HEADER+=${HDR_LINE}
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: RAW HEADER:${HDR_LINE}"
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ECHO HDR:${WHITE_FG}${#_LIST_HEADER}${RESET}:\"$(eval echo ${HDR_LINE})\""
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: EVAL HDR:${WHITE_FG}${#_LIST_HEADER}${RESET}:\"$(eval ${HDR_LINE})\""
}

list_set_header_break_color () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_HEADER_BREAK_COLOR=${1}
}

list_set_header_callback () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_HEADER_CALLBACK_FUNC=${1}
}

list_set_header_init () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_HEADER=()
}

list_set_key_callback () {
	local -A KEY_DATA=()
	local -a VALID_OPTS=(KEY FUNC RET) # Add options and _CBK_XXX arrays as needed
	local K=''

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	KEY_DATA=(${@})
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: KEY_DATA: ${(kv)KEY_DATA}"

	for K in ${(k)KEY_DATA};do
		if [[ ${VALID_OPTS[(i)${K}]} -gt ${#KEY_DATA} ]];then
			echo "${0}: INVALID OPTION:${K} - Valid options are:${VALID_OPTS}" >&2
			return 1
		fi
	done

	_KEY_CALLBACKS[${KEY_DATA[KEY]}]=${KEY_DATA[FUNC]}
	_CBK_RET[${KEY_DATA[KEY]}]=${KEY_DATA[RET]}

	return 0
}

list_set_line_item () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_LINE_ITEM=${@}
}

list_set_no_top_offset () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_NO_TOP_OFFSET=true
}

list_set_page_callback () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_PAGE_CALLBACK_FUNC=${1}
}

list_set_page_hold () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_PAGE_DATA[PAGE_STATE]='hold'
}

list_set_pages () {
	local -A PAGES
	local BOT
	local PG=0
	local TOP
	local L

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for (( L=1; L <= ${#_LIST}; L++ ));do
		if [[ $(( L % _MAX_DISPLAY_ROWS )) -eq 0 ]];then
			(( PG++))
			TOP=$(( L - _MAX_DISPLAY_ROWS + 1 ))
			PAGES[${PG}]="${TOP}:${L}"
		fi
	done

	# Last page
	BOT=$(cut -d: -f2 <<<${PAGES[${PG}]})
	TOP=$(( BOT + 1 ))
	BOT=$(( L - 1 ))
	(( PG++))
	PAGES[${PG}]=${TOP}:${BOT}

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: RETURNING page boundaries for ${#PAGES} pages"

	echo "${(kv)PAGES}"
}

list_set_position () {
	local POS=${@}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	echo "${_LIST_NDX}|${_CURSOR_NDX}" > ${_LIST_TAG_FILE}
}

list_set_prompt () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	[[ -n ${@} ]] && _LIST_PROMPT=${@}
}

list_set_restore_pos () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_RESTORE_POS=${1}
}

list_set_restore_pos_reset () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_LIST_RESTORE_POS_RESET=${1}
}

list_set_prompt_msg () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_PROMPT_KEYS=${@}
}

list_set_reuse_stale () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_REUSE_STALE=${1}
}

list_set_searchable () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_LIST_IS_SEARCHABLE=${1}
}

list_set_selectable () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_LIST_IS_SELECTABLE=${1}
}

list_set_select_action () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	[[ -n ${@} ]] && _SELECT_ACTION=${@}
}

list_set_select_callback () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_SELECT_CALLBACK_FUNC=${1}
}

list_set_selected () {
	local ROW=${1}
	local VAL=${2}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${functrace[1]} ARGC:${#@} ROW:${ROW} VAL:${VAL}"

	_LIST_SELECTED[${ROW}]=${VAL}
}

list_set_selection_limit () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_SELECTION_LIMIT=${1}
}

list_set_sortable () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"

	_LIST_IS_SORTABLE=${1}
}

list_set_sort_defaults () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
	
	_SORT_DATA=(${@})
}

list_sort () {
	local TRIGGER=${1:=none}
	local PROMPT=false
	local -A ORD_TOGGLE=(a d d a)
	local -A SORT_TEXT=(a ascending d descending)
	local COL=0
	local SORT_SET=false
	local A C
	
	[[ ${TRIGGER} == 'key' ]] && PROMPT=true && _SORT_DATA[ORDER]=${ORD_TOGGLE[${_SORT_DATA[ORDER]}]}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	# Reject non-sortable
	if [[ ${_LIST_IS_SORTABLE} == 'false' ]];then
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SORT DENIED: _LIST_IS_SORTABLE:${_LIST_IS_SORTABLE}"
		return
	fi

	if arr_is_populated "${_LIST_SELECTED}";then
		for A in ${(k)_LIST_SELECTED};do
			if [[ ${_LIST_SELECTED[${A}]} -ne ${_AVAIL_ROW} ]];then
				msg_box -H1 -t2 "<r>Sort Unavailable<N>|Active Selections"
				if [[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]];then
					dbg "${0}: SORT REJECTED: ACTIVE SELECTIONS"
					dbg "$(for C in ${(k)_LIST_SELECTED};do; echo ${C} - ${_LIST_SELECTED[${C}]};done)"
					return
				fi
			fi
		done
	fi

	# Handle MAXCOL
	if [[ ${_SORT_DATA[MAXCOL]} -eq 0 ]];then
		_SORT_DATA[MAXCOL]=$(get_delim_field_cnt ${_LIST[1]})
		if [[ ${_SORT_DATA[MAXCOL]} -eq 0 ]];then
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: DEFAULTING MAXCOL TO 1 COL"
			_SORT_DATA[MAXCOL]=1
		else
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: MAXCOL BASED ON DELIM:${_SORT_DATA[MAXCOL]}"
		fi
	fi

	# Handle prompting
	if [[ ${PROMPT} == 'true' && ${_SORT_DATA[MAXCOL]} -gt 1 ]];then
		msg_box -p "Enter column to sort ${SORT_TEXT[${_SORT_DATA[ORDER]}]}|Range: <w>1<N> through <w>${_SORT_DATA[MAXCOL]}<N>|(Default is <w>${_SORT_DATA[COL]}<N>)"
		COL=${_MSG_KEY}

		[[ ${COL} -eq 27 ]] && return # User hit Esc key
		[[ ${COL} -eq 0 ]] && COL=${_SORT_DATA[COL]} # Set default

		if [[ ${COL} -lt 1 || ${COL} -gt ${_SORT_DATA[MAXCOL]} ]];then
			msg_box -c -p -PK "Invalid sort column:${COL}"
			return 1
		fi

		_SORT_DATA[COL]=${COL} # Either user key or default
	else
		COL=${_SORT_DATA[COL]}
	fi

	SORT_SET=true # No early returns

	[[ -z ${_SORT_DATA[TYPE]} ]] && msg_box -H1 -p -PK "<r>Warning<N>|Application:<w>${_SCRIPT}<N> did not provide a <I><U><w>sort type<N> ( _SORT_DATA[TYPE] )|Need (flat/assoc) - data will remain unsorted"

	# Call sort type
	case ${_SORT_DATA[TYPE]} in
		assoc) list_sort_assoc;;
		flat) list_sort_flat;;
	esac

	# Define highlighting
	for (( C=1; C <= _SORT_DATA[MAXCOL]; C++ ));do
		setopt nowarncreateglobal # No Monitor locals
		if [[ ${COL} -eq ${C} ]];then
			eval "SCOL${C}_CLR"=${E_BOLD}${E_WHITE_FG}
		else
			eval "SCOL${C}_CLR"=${E_MAGENTA_FG}
		fi
		setopt warncreateglobal # Monitor locals
	done

}

list_sort_assoc () {
	local ARGS=${@}
	local -A ARG_TABLE=()
	local -a SORT_TABLE=()
	local -A TABLE=()
	local DELIM=${_SORT_DATA[DELIM]}
	local TCNT=0
	local REV=''
	local R 

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	# Handle direct call
	if [[ -n ${ARGS} ]];then
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: DIRECT CALL - PARSING ARGUMENTS"

		ARG_TABLE=(${=ARGS})
		for A in ${(k)ARG_TABLE};do
			_SORT_DATA[${A}]=${ARG_TABLE[${A}]}
		done
	fi

	# Handle sort table
	if [[ -n ${_SORT_DATA[TABLE]} ]];then
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SORT TABLE FOUND - LOADING TABLE DATA"

		[[ ! ${_SORT_DATA[TABLE]} =~ 'null' ]] && TABLE=(${=_SORT_DATA[TABLE]}) || TABLE=()
	fi

	TCNT=${#TABLE}
	SORT_TABLE=${TABLE[${_SORT_DATA[COL]}]}

	if [[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]];then
		dbg "${0}: TABLE COUNT:${TCNT}"
		dbg "${0}: TABLE DATA:${(kv)TABLE}"
		dbg "${0}: SORT KEY:${_SORT_DATA[COL]}"
		dbg "${0}: SORT TABLE:${SORT_TABLE}"
		dbg "${0}: SORT TABLE SAMPLE:${${(P)SORT_TABLE}[1]}"
		dbg "${0}: PREPARING TO SORT ${#${(P)SORT_TABLE}} ROWS in ${SORT_TABLE}"
	fi

	[[ ${_SORT_DATA[ORDER]} == "a" ]] && REV='' || REV=-r

	_LIST=("${(f)$(
		for (( R=1; R<=${#${(P)SORT_TABLE}}; R++ ));do
			echo -n "${${(P)SORT_TABLE}[${R}]}"
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SORT_TABLE[${R}]:${${(P)SORT_TABLE}[${R}]}"

			for (( T=1; T<=TCNT; T++ ));do
				echo -n "${DELIM}${(k)${(P)TABLE[${T}]}[${R}]}"
				[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: (k)TABLE[${T}][${R}]:${DELIM}${(k)${(P)TABLE[${T}]}[${R}]}"
			done
			echo
		done | sort ${REV} -n -t"${DELIM}" -k1 | cut -d"${DELIM}" -f2
	)}")

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SORTED ${#_LIST} ROWS"
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: _LIST DATA SAMPLE:${_LIST[1,2]}"
}

list_sort_flat () {
	local ARGS=(${@})
	local -A ARG_TABLE=()
	local -A TABLE=()
	local -A _CAL_SORT=(year G7 month F6 week E5 day D4 hour C3 minute B2 second A1)
	local -a SORT_ARRAY=()
	local ARRAY_NAME=''
	local FLDCNT=0
	local FLIP=false
	local DELIM=''
	local FIELD=''
	local SORT_KEY=''
	local SORT_ORDER=''
	local NDX=0
	local SEL=0
	local A L R

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	# Handle direct call
	if [[ -n ${ARGS} ]];then
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: DIRECT CALL - PARSING ARGUMENTS"
		ARG_TABLE=(${=ARGS})
		for A in ${(k)ARG_TABLE};do
			_SORT_DATA[${A}]=${ARG_TABLE[${A}]}
		done
	fi

	# Simplify vars
	ARRAY_NAME=${_SORT_DATA[ARRAY]:=_LIST}
	DELIM=${_SORT_DATA[DELIM]}
	SORT_ORDER=${_SORT_DATA[ORDER]}
		
	if [[ ${_SORT_DATA[NOKEY]} == 'true' ]];then # Not using keys
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SORTING WITHOUT KEYS"

		SORT_ARRAY=(${(P)ARRAY_NAME})

		if [[ ${SORT_ORDER} == "a" ]];then
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SORT ASCENDING"
			_LIST=(${(on)SORT_ARRAY})
		else
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SORT DESCENDING"
			_LIST=(${(On)SORT_ARRAY})
		fi
	else
		# Handle sort table
		if [[ -n ${_SORT_DATA[TABLE]} && ! ${_SORT_DATA[TABLE]} =~ 'none' ]];then
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SORT TABLE FOUND - LOADING TABLE DATA"
			TABLE=(${=_SORT_DATA[TABLE]})
			FIELD=${TABLE[${_SORT_DATA[COL]}]} # Mapped keys
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: MAPPED SORT KEY IS:${FIELD}"
		else
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: NO SORT TABLE FOUND"
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SORT KEY IS _SORT_DATA[COL]:${_SORT_DATA[COL]}"
		fi

		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: PREPARING TO SORT ${#${(P)ARRAY_NAME}} ROWS in ARRAY:${ARRAY_NAME}"

		for L in ${(P)ARRAY_NAME};do # Dereference array name
			if [[ -n ${FIELD} ]];then
				SORT_KEY=$(cut -d "${_SORT_DATA[DELIM]}" -f${FIELD} <<<${L}) # Keys based on line content
			else
				SORT_KEY=$(cut -d "${_SORT_DATA[DELIM]}" -f ${_SORT_DATA[COL]} <<<${L}) # Keys based on line content
			fi

			[[ ${SORT_KEY} =~ "year" ]] && SORT_ARRAY+="${_CAL_SORT[year]}${SORT_KEY}${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ "month" ]] && SORT_ARRAY+="${_CAL_SORT[month]}${SORT_KEY}${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ "week" ]] && SORT_ARRAY+="${_CAL_SORT[week]}${SORT_KEY}${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ "day" ]] && SORT_ARRAY+="${_CAL_SORT[day]}${SORT_KEY}${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ "hour" ]] && SORT_ARRAY+="${_CAL_SORT[hour]}${SORT_KEY}${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ "min" ]] && SORT_ARRAY+="${_CAL_SORT[minute]}${SORT_KEY}${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ "sec" ]] && SORT_ARRAY+="${_CAL_SORT[second]}${SORT_KEY}${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ '^[A-Za-z]' ]] && SORT_ARRAY+="${SORT_KEY[1]}${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ '^[(]?\d{4}-\d{2}-\d{2}' ]] && SORT_ARRAY+="${SORT_KEY[1,10]}${DELIM}${L}" && FLIP=true && continue
			[[ ${SORT_KEY} =~ '\d{4}$' ]] && SORT_ARRAY+="ZZZZ${DELIM}$(echo ${L} | perl -pe 's/(.*)(\d{4})$/\2\1\2/g')" && continue
			[[ ${SORT_KEY} =~ '\d[.]\d\D' ]] && SORT_ARRAY+="ZZZZ${DELIM}$(echo ${L} | perl -pe 's/([.]\d)(.*)((G|M).*)$/${1}0 ${3}/g')" && continue
			[[ ${SORT_KEY} =~ 'Mi?B' ]] && SORT_ARRAY+="A888${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ 'Gi?B' ]] && SORT_ARRAY+="B999${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ ':' ]] && SORT_ARRAY+="B999${DELIM}${L}" && continue
			[[ ${SORT_KEY} =~ '-' ]] && SORT_ARRAY+="A888${DELIM}${L}" && continue

			SORT_ARRAY+="${SORT_KEY}${DELIM}${L}"
		done

		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SORTED ${#SORT_ARRAY} ROWS"

		if [[ ${FLIP} == 'true' ]];then
			[[ ${_SORT_DATA[ORDER]} == 'a' ]] && SORT_ORDER=d || SORT_ORDER=a # Reverse sort for numeric dates
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Flipped SORT_ORDER for numeric date"
		fi

		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SORT_ORDER:${SORT_ORDER}"

		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: USING SORT KEYS"

		if [[ ${SORT_ORDER} == "a" ]];then
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SORT ASCENDING"
			_LIST=("${(f)$(
				for L in ${(on)SORT_ARRAY};do # Ascending
					cut -d"${_SORT_DATA[DELIM]}" -f2- <<<${L}
				done
			)}")
		else
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SORT DESCENDING"
			_LIST=("${(f)$(
				for L in ${(On)SORT_ARRAY};do # Descending
					cut -d"${_SORT_DATA[DELIM]}" -f2- <<<${L}
				done
			)}")
		fi
	fi

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ADDED ${#_LIST} ROWS to _LIST ARRAY"

	if [[ -n ${ARGS} ]];then # Called directly - return list to caller
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: DIRECT CALL - ECHOING ${#_LIST} ROWS"
		for L in ${_LIST};do
			echo ${L}
		done
	fi
}

list_toggle_all () {
	local ACTION=${1} 
	local -a SELECTED=()
	local FIRST_ITEM=$(( ( _PAGE_DATA[PAGE] * _MAX_DISPLAY_ROWS) - _MAX_DISPLAY_ROWS + 1 ))
	local LAST_ITEM=$(( _PAGE_DATA[PAGE] * _MAX_DISPLAY_ROWS ))
	local S R

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}:  _LIST_NDX:${_LIST_NDX}, TOP_OFFSET:${_PAGE_DATA[TOP_OFFSET]}, MAX_DISPLAY_ROWS:${_MAX_DISPLAY_ROWS}, MAX_ITEM:${_PAGE_DATA[MAX_ITEM]}, PAGE:${_PAGE_DATA[PAGE]}, ACTION:${ACTION}, FIRST_ITEM:${FIRST_ITEM}, LAST_ITEM:${LAST_ITEM}"

	[[ ${LAST_ITEM} -ge ${_PAGE_DATA[MAX_ITEM]} ]] && LAST_ITEM=${_PAGE_DATA[MAX_ITEM]} # Partial page

	if [[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]];then
		dbg "${0}: SELECTED:${#SELECTED}, FIRST_ITEM:${FIRST_ITEM}, LAST_ITEM:${LAST_ITEM}"
		dbg "${0}: MAX_ITEM:${_PAGE_DATA[MAX_ITEM]}, MAX_PAGE:${_PAGE_DATA[MAX_PAGE]}"
	fi

	if [[ ${ACTION} == 'toggle' ]];then # Mark/unmark all
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ACTION:${ACTION}"
		[[ ${_LIST_SELECTED_PAGE[${_PAGE_DATA[PAGE]}]} -eq 1 ]] && _LIST_SELECTED_PAGE[${_PAGE_DATA[PAGE]}]=0 || _LIST_SELECTED_PAGE[${_PAGE_DATA[PAGE]}]=1 # Toggle state

		if [[ ${_PAGE_DATA[MAX_PAGE]} -gt 1 && ${_LIST_SELECTED_PAGE[${_PAGE_DATA[PAGE]}]} -eq 1 ]];then # Prompt only for setting range
			msg_box -p -P"(A)ll or (P)age" "Enter Select Range"
			case ${_MSG_KEY:l} in
				a) SELECTED=($(list_select_range 1 ${_PAGE_DATA[MAX_ITEM]})); _LIST_SELECTED_PAGE[0]=1;;
				p) SELECTED=($(list_select_range ${FIRST_ITEM} ${LAST_ITEM})); _LIST_SELECTED_PAGE[0]=0;;
			esac
			[[ -n ${SELECTED} ]] && msg_box_clear 
			[[ -z ${SELECTED} ]] && msg_box_clear && list_display_page && return
		else # Set clearing scope - all or page
			if [[ ${_LIST_SELECTED_PAGE[0]} -eq 1 ]];then # All was set
				SELECTED=($(list_select_range 1 ${_PAGE_DATA[MAX_ITEM]})) && _LIST_SELECTED_PAGE[0]=0
			else
				SELECTED=($(list_select_range ${FIRST_ITEM} ${LAST_ITEM}))
			fi
		fi
	elif [[ ${ACTION} == 'clear' ]];then # Mark/unmark all
		_LIST_SELECTED_PAGE[${_PAGE_DATA[PAGE]}]=${_AVAIL_ROW} # Clear - unmark page
		_LIST_SELECTED_PAGE[0]=${_AVAIL_ROW} # Clear - unmark all
		SELECTED=($(list_select_range 1 ${_PAGE_DATA[MAX_ITEM]}))
		_MARKED=()
	fi

	for S in ${SELECTED};do
		_LIST_SELECTED[${S}]=${_LIST_SELECTED_PAGE[${_PAGE_DATA[PAGE]}]}
	done

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: _HEADER_CALLBACK_FUNC:${_HEADER_CALLBACK_FUNC}"
	[[ -n ${_HEADER_CALLBACK_FUNC} ]] && ${_HEADER_CALLBACK_FUNC} 0 "${0}|${_LIST_SELECTED_PAGE[${_PAGE_DATA[PAGE]}]}"

	list_display_page
}

list_toggle_selected () {
	local COUNT=$(list_get_selected_count)

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if [[ -n ${_SELECT_CALLBACK_FUNC} ]];then
		${_SELECT_CALLBACK_FUNC} ${_LIST_NDX}
		[[ ${?} -ne 0 ]] && return
	fi

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: _LIST_NDX:${_LIST_NDX} _REUSE_STALE:${_REUSE_STALE} _SELECTION_LIMIT:${_SELECTION_LIMIT}"

	if [[ ${_REUSE_STALE} == 'false' && ${_LIST_SELECTED[${_LIST_NDX}]} -eq ${_STALE_ROW} ]];then
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: STALE ROW:${_LIST_NDX} WAS REJECTED _LIST_SELECTED: ${_LIST_SELECTED[${_LIST_NDX}]}"
		return # Ignore stale
	fi

	if [[ ${_SELECTION_LIMIT} -ne 0 && ${COUNT} -gt $((_SELECTION_LIMIT - 1 )) ]];then
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SELECTION_LIMIT WAS TRIGGERED SELECTION_LIMIT:${SELECTION_LIMIT} COUNT:${COUNT}"
		msg_box -p -PK "Selection is limited to ${_SELECTION_LIMIT}"
		msg_box_clear
		return # Ignore over limit
	fi

	if [[ ${_LIST_SELECTED[${_LIST_NDX}]} -eq ${_AVAIL_ROW} ]];then
		list_set_selected ${_LIST_NDX} ${_SELECTED_ROW} 
		list_item select ${_LIST_LINE_ITEM} ${_CURSOR_NDX} 0
		[[ -n ${_HEADER_CALLBACK_FUNC} ]] && ${_HEADER_CALLBACK_FUNC} ${_LIST_NDX} "${0}|1" # All on
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ROW:${_LIST_NDX} was set to ${_SELECTED_ROW}"
	else
		if [[ ${_LIST_SELECTED[${_LIST_NDX}]} -eq ${_SELECTED_ROW} ]];then
			list_set_selected ${_LIST_NDX} ${_AVAIL_ROW}
			list_item deselect ${_LIST_LINE_ITEM} ${_CURSOR_NDX} 0
			[[ -n ${_HEADER_CALLBACK_FUNC} ]] && ${_HEADER_CALLBACK_FUNC} ${_LIST_NDX} "${0}|0" # All off
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ROW:${_LIST_NDX} was set to ${_AVAIL_ROW}"
		elif [[ ${_LIST_SELECTED[${_LIST_NDX}]} -eq ${_STALE_ROW} ]];then
			msg_box -c -p -PK "Row <r>not<N> selectable|This row is marked as STALE"
			msg_box_clear
		fi
	fi

	list_do_header ${_PAGE_DATA[PAGE]} ${_PAGE_DATA[MAX_PAGE]}
}

list_warn_invisible_rows () {
	local PAGE=${_PAGE_DATA[PAGE]}
	local FIRST_ITEM=$(( (PAGE * _MAX_DISPLAY_ROWS - _MAX_DISPLAY_ROWS) + 1 ))
	local LAST_ITEM=$(( PAGE * _MAX_DISPLAY_ROWS ))
	local S

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${LAST_ITEM} -ge ${_PAGE_DATA[MAX_ITEM]} ]] && LAST_ITEM=${_PAGE_DATA[MAX_ITEM]} # Partial page

	# Warn user of marked rows not on current page
	_OFF_SCREEN_ROWS_MSG=''
	for S in ${(k)_LIST_SELECTED};do
		if [[ ${S} -ge ${FIRST_ITEM} && ${S} -le ${LAST_ITEM}  ]];then
			continue 
		else
			if [[ ${_LIST_SELECTED[${S}]} -eq ${_SELECTED_ROW} ]];then
				_OFF_SCREEN_ROWS_MSG="(<w><I>There are marked rows on other pages<N>)|"
				break
			fi
		fi
	done
	[[ -n ${_OFF_SCREEN_ROWS_MSG} ]] && msg_box -H1 -p -PK "<r>Warning<N>|${_OFF_SCREEN_ROWS_MSG}"
}

list_write_to_file () {
	local ALIST=(${@})
	local L

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if [[ -n ${ALIST[1]} ]];then
		[[ -e ${_SCRIPT}.out ]] && rm -f ${_SCRIPT}.out
		msg_box -c -p "Writing ${#ALIST} list $(str_pluralize item) to file: ${_SCRIPT}.out|Press any key"
		for L in ${ALIST};do
			echo ${L} >> ${_SCRIPT}.out
		done
	else
		msg_box -c -p -PK "List is empty - nothing to write"
	fi
}

