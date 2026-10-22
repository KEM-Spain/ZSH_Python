# LIB Dependencies
_DEPS+=(ARRAY.zsh BOX.zsh CENTER.zsh STR.zsh TPUT.zsh)

# LIB Declarations
typeset -a _CONT_BUFFER=()
typeset -A _CONT_DATA=(BOX false COLS 0 HEADER 0 MAX 0 OUT 0 SCR 0 TOP 0 Y 0 W 0)

# LIB Vars
_BOX_LINE_WEIGHT=''
_MSG_KEY=n
_PROC_MSG=false
_MSG_BOX_TAG=MSG_BOX
_PROC_BOX_TAG=PROC_BOX
_CONT_BOX_TAG=CONT_BOX
_DELIM='|'
_LAST_MSG_TAG=''
_REPAINT=false
_HDR_SECTION=false

# LIB Functions
msg_box () {
	local -a MSGS=()
	local -a MSG_HEADER=()
	local -a MSG_BODY=()
	local -a MSG_FOOTER=()
	local -a MSG_FOLD=()
	local -A CONT_COORDS=()

	local MAX_X_COORD=$(( _MAX_ROWS - 5 )) # Not including frame 5 up from bottom, 4 with frame
	local MAX_Y_COORD=$(( _MAX_COLS - 10 )) # Not including frame 10 from sides, 9 with frame
	local MIN_X_COORD=$(( (_MAX_ROWS - MAX_X_COORD) - 1 )) # Vertical limit
	local MIN_Y_COORD=$(( _MAX_COLS - MAX_Y_COORD )) # Horiz limit
	local USABLE_COLS=$(( MAX_Y_COORD - MIN_Y_COORD )) # Horizontal space boundary
	local USABLE_ROWS=$(( MAX_X_COORD - MIN_X_COORD )) # Vertical space boundary
	local MAX_LINE_WIDTH=$(( USABLE_COLS - 20 ))

	local BOX_HEIGHT=0
	local BOX_WIDTH=0
	local BODY_MAX=0
	local BOX_X_COORD=0
	local BOX_Y_COORD=0
	local BOX_TEXT_CSR=0
	local DELIM_COUNT=0
	local DTL_NDX=0
	local FOOTER_MAX=0
	local GAP=0
	local GAP_NDX=0
	local HDR_MAX=0
	local KEY=''
	local MAX_ELEM=0
	local MSG_COLS=0
	local MSG_DTL=0
	local MSG_LEN=0
	local MSG_NDX=0
	local MSG_OUT=0
	local MSG_PAGE=1
	local MSG_PAGES=0
	local MSG_PAGING=false
	local MSG_ROWS=0
	local MSG_SEP=''
	local MSG_STR=''
	local MSG_X_COORD=0
	local MSG_Y_COORD=0
	local NAV_BAR="<c>Navigation keys<N>: <w>c<N>=continue <w>t<N>,<w>h<N>=top <w>b<N>,<w>l<N>=bottom <w>p<N>,<w>k<N>=up <w>n<N>,<w>j<N>=down, <w>Esc<N>=close<N>"
	local OPTION=''
	local PAGING_BOT=0
	local PARTIAL=0
	local PG_LINES=0
	local PG_INIT=''
	local SCR_NDX=0
	local TAG=''
	local H K M T X 

	# OPTIONS
	local -A COORD_ARGS=()
	local -a MSG=()
	local CLEAR_MSG=false
	local CONTINUOUS=false
	local DELIM_ARG=false
	local DISPLAY_AREA=0
	local FOLD_WIDTH=${MAX_LINE_WIDTH}
	local FRAME_COLOR=''
	local HDR_LINES=0
	local HDR_FTR_LINES=0
	local MSG_H_COORD_ARG=0
	local LEN=0
	local MSG_X_COORD_ARG=-1
	local MSG_Y_COORD_ARG=-1
	local PROMPT_ARG=''
	local PROMPT_USER=false
	local QUIET=false
	local RELATIVE=false
	local SAFE=true
	local BUFFER_FULL=false
	local SO=false
	local TAG_ARG=''
	local TEXT_STYLE=c # Default is center - Accepted Values:[(l)eft,(c)enter]
	local TIMEOUT=0
	local MSG_W_COORD_ARG=0

	local OPTSTR=":A:H:P:O:CIRT:cf:h:j:pqrs:t:uw:x:y:Zz"
	OPTIND=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	while getopts ${OPTSTR} OPTION;do
		case ${OPTION} in
			A) COORD_ARGS=(${(z)OPTARG});; # Create array of coordinates
			C) CONTINUOUS=true;; # Message is added to the existing continuous msg
			H) HDR_LINES=${OPTARG};; # Number of msg lines that comprise header
			I) _CONT_DATA[BOX]=false;; # Trigger initialization of continuous message
			O) FRAME_COLOR=${OPTARG};; # Set color for message frame
			P) PROMPT_ARG=${OPTARG};; # Text for message prompt
			R) RELATIVE=true;; # Use this tag to retrieve an alternative placement coord
			T) TAG_ARG=${OPTARG};; # TAG name to use when saving message coordinates
			Z) _REPAINT=true;; # Repaint screen from buffer
			c) CLEAR_MSG=true;; # Clear the previous message before displaying the current message
			f) FOLD_WIDTH=${OPTARG};; # Fold the message text using this line width
			h) MSG_H_COORD_ARG=${OPTARG};; # Specify a message box height other than the default
			j) TEXT_STYLE=${OPTARG};; # Specify desired text justification (center, left)
			p) PROMPT_USER=true;; # Request user input following message display
			q) QUIET=true;; # Suppress any messages
			r) SO=true;; # Request standout mode
			s) DELIM_ARG="${OPTARG}";; # Use this delimiter to parse message sections
			t) TIMEOUT="${OPTARG}";; # Display message for this time limit
			u) SAFE=false;; # Ensure no coordinates violate available screen dimensions
			w) MSG_W_COORD_ARG=${OPTARG};; # Specify a message box width other than the default
			x) MSG_X_COORD_ARG=${OPTARG};; # Specify a message display row other than the default
			y) MSG_Y_COORD_ARG=${OPTARG};; # Specify a message display col other than the default
			z) _REPAINT=false;; # No repaints
			:) print -u2 " ${_SCRIPT}: ${0}: option: -${OPTARG} requires an argument" >&2;read ;;
			\?) print -u2 " ${_SCRIPT}: ${0}: unknown option -${OPTARG}" >&2; read;;
		esac
	done
	shift $(( OPTIND - 1 ))

	[[ -n ${TAG_ARG} ]] && TAG=${TAG_ARG} || TAG=${_MSG_BOX_TAG}

	# Hide cursor
	if [[ ${_CURSOR_STATE} == 'on' ]];then
		tput civis >&2
		_CURSOR_STATE=off
	fi

	[[ ${CLEAR_MSG} == 'true' ]] && msg_box_clear # Clear last msg?

	# Process MSG arguments
	MSG=(${@}) # MSG text
	[[ -z ${MSG} ]] && return # If no MSG

	# Long messages display feedback while parsing
	MSG_LEN=${#${(z)@}}
	[[ ${#MSG_LEN} -gt 250 && ${QUIET} == 'false' ]] && _PROC_MSG=true
	
	# Append prompt to msgs
	if [[ -n ${PROMPT_ARG} ]];then
		case ${PROMPT_ARG} in
			B) MSG_FOOTER+="|<Z>|<w>Reboot? (y/n)<N>";;
			C) MSG_FOOTER+="|<Z>|<w>Continue? (y/n)<N>";;
			D) MSG_FOOTER+="|<Z>|<w>Delete? (y/n)<N>";;
			E) MSG_FOOTER+="|<Z>|<w>Edit? (y/n)<N>";;
			G) MSG_FOOTER+="|<Z>|<w>Download? (y/n)<N>";;
			I) MSG_FOOTER+="|<Z>|<w>Install? (y/n)<N>";;
			K) MSG_FOOTER+="|<Z>|<w>Press any key...<N>";;
			M) MSG_FOOTER+="|<Z>|<w>More? (y/n)<N>";;
			N) MSG_FOOTER+="|<Z>|<w>(y)es,(s)kip,(a)ll?";;
			O) MSG_FOOTER+="|<Z>|<w>Overwrite? (y/n)<N>";;
			P) MSG_FOOTER+="|<Z>|<w>Proceed? (y/n)<N>";;
			S) MSG_FOOTER+="|<Z>|<w>Select Option...<N>";;
			Q) MSG_FOOTER+="|<Z>|<w>Queue? (y/n)<N>";;
			V) MSG_FOOTER+="|<Z>|<w>View? (y/n)<N>";;
			Y) MSG_FOOTER+="|<Z>|<w>Yes/No? (y/n)<N>";;
			X) MSG_FOOTER+="|<Z>|<w>Kill? (y/n)<N>";;
			*) MSG_FOOTER+="|<Z>|<w>${PROMPT_ARG}<N>";;
		esac
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ADDED PROMPT:${PROMPT_ARG}"
	fi

	# Get message delimiter
	[[ ${DELIM_ARG} != 'false' ]] && _DELIM=${DELIM_ARG} # Assign delimiter

	if [[ ${#DELIM} -gt 1 ]];then
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Invalid delimiter:${DELIM}. Resetting to '|'"
		DELIM='|' # Set to rational default
	fi

	# Flash progress msg if requested
	[[ ${_PROC_MSG} == 'true' ]] && msg_proc

	MSGS=("${(f)$(msg_box_parse ${MAX_LINE_WIDTH} ${MSG})}")
	[[ -n ${MSG_FOOTER} ]] && MSG_FOOTER=("${(f)$(msg_box_parse ${MAX_LINE_WIDTH} ${MSG_FOOTER})}")

	# Separate headers and footers from body
	if [[ ${HDR_LINES} -ne 0 ]];then
		MSG_HEADER=(${MSGS[1,$(( HDR_LINES ))]})
		MSG_BODY=(${MSGS[HDR_LINES+1,-1]})
		MSG_ROWS=$(( ${#MSG_HEADER} + ${#MSG_BODY} + ${#MSG_FOOTER} ))
	else
		MSG_BODY=(${MSGS})
		MSG_ROWS=$(( ${#MSG_BODY} + ${#MSG_FOOTER} ))
	fi

	# --- BEGIN COORDS SETUP ---
	if [[ -n ${COORD_ARGS} ]];then
		[[ -n ${COORD_ARGS[W]} ]] && MSG_W_COORD_ARG=${COORD_ARGS[W]}
		[[ -n ${COORD_ARGS[H]} ]] && MSG_H_COORD_ARG=${COORD_ARGS[H]}
		[[ -n ${COORD_ARGS[X]} ]] && MSG_X_COORD_ARG=${COORD_ARGS[X]}
		[[ -n ${COORD_ARGS[Y]} ]] && MSG_Y_COORD_ARG=${COORD_ARGS[Y]}
	fi

	HDR_FTR_LINES=$(( ${#MSG_HEADER} + ${#MSG_FOOTER} + 2 )) # Allowance for vertical header and footer space

	if [[ ${MSG_H_COORD_ARG:=0} -ne 0 ]];then
		if [[ ${MSG_ROWS} -gt ${MSG_H_COORD_ARG} ]];then
			MSG_PAGING=true
			PG_LINES=$(( MSG_H_COORD_ARG - HDR_FTR_LINES ))
		fi
	elif [[ ${MSG_ROWS} -gt ${USABLE_ROWS} ]];then
		MSG_PAGING=true
		PG_LINES=$(( USABLE_ROWS - HDR_FTR_LINES ))
	else
		PG_LINES=${#MSG_BODY}
	fi

	HDR_MAX=$(arr_long_elem ${MSG_HEADER})
	BODY_MAX=$(arr_long_elem ${MSG_BODY})
	FOOTER_MAX=$(arr_long_elem ${MSG_FOOTER})

	MAX_ELEM=$(max ${#HDR_MAX} ${#BODY_MAX})
	MAX_ELEM=$(max ${MAX_ELEM} ${#FOOTER_MAX})

	MSG_COLS=$(( MAX_ELEM + 2 ))
	MSG_SEP="<SEP>"

	# Process various message types
	if [[ ${MSG_PAGING}  == 'true' ]];then # Multi page message
		MSG_STR=$(msg_nomarkup ${NAV_BAR}) # Strip markup
		[[ ${_OFF_SCREEN_ROWS} == 'true' ]] && MSG_HEADER+="(<r><B><I>There are <w>marked rows <r>on other pages<N>)"

		[[ -n ${MSG_HEADER} ]] && (( PG_LINES-=2 )) || (( PG_LINES--))

		MSG_PAGES=$(( ${#MSG_BODY} / PG_LINES ))
		PARTIAL=$((${#MSG_BODY} % PG_LINES ))
		[[ ${PARTIAL} -ne 0 ]] && (( MSG_PAGES++))
		NAV_BAR=$(sed "s/_MSG_PG/${MSG_PAGES}/" <<< ${NAV_BAR})

		if [[ -n ${MSG_HEADER} ]];then
			MSG_HEADER=(${MSG_HEADER} ${NAV_BAR} ${MSG_SEP})
		else
			MSG_HEADER=(${NAV_BAR} ${MSG_SEP})
		fi
		MSG_COLS=$(( ${#MSG_STR} + 1 ))
	elif [[ -n ${MSG_HEADER} ]];then
		MSG_HEADER=(${MSG_HEADER} ${MSG_SEP})
	fi

	(( MSG_COLS += 2 )) # Add gutter

	if [[ ${SAFE} == 'true' ]];then
		[[ ${MSG_X_COORD} -lt ${MIN_X_COORD} ]] && MSG_X_COORD=${MIN_X_COORD}
		[[ ${MSG_X_COORD} -gt ${USABLE_ROWS} ]] && MSG_X_COORD=${USABLE_ROWS}
		[[ ${MSG_Y_COORD} -lt ${MIN_Y_COORD} ]] && MSG_Y_COORD=${MIN_Y_COORD}
		[[ ${MSG_Y_COORD} -gt ${USABLE_COLS} ]] && MSG_Y_COORD=${USABLE_COLS}
	fi

	# Set default coords or apply passed coords
	[[ ${MSG_W_COORD_ARG} -eq 0 ]] && BOX_WIDTH=$(( MSG_COLS + 4 )) || BOX_WIDTH=${MSG_W_COORD_ARG}
	[[ ${MSG_H_COORD_ARG} -eq 0 ]] && BOX_HEIGHT=$(( PG_LINES + ${#MSG_HEADER} + ${#MSG_FOOTER} + 2 )) || BOX_HEIGHT=${MSG_H_COORD_ARG}

	# Safety: Ensure box width fits content
	local MIN_REQUIRED_WIDTH=$(( MSG_COLS + 2 ))
	if [[ ${MSG_W_COORD_ARG} -ne 0 && ${BOX_WIDTH} -lt ${MIN_REQUIRED_WIDTH} ]]; then
		BOX_WIDTH=${MIN_REQUIRED_WIDTH}
	fi

	if [[ ${RELATIVE} == 'true' ]];then
		if [[ -n ${_REL_COORDS} ]];then
			MSG_X_COORD=${_REL_COORDS[X]}
			MSG_Y_COORD=${_REL_COORDS[Y]}
			BOX_WIDTH=${_REL_COORDS[W]}
			BOX_HEIGHT=${_REL_COORDS[H]}
		fi
	else
		[[ ${MSG_X_COORD_ARG} -eq -1 ]] && MSG_X_COORD=$(center -V -h${BOX_HEIGHT}) || MSG_X_COORD=${MSG_X_COORD_ARG}
		[[ ${MSG_Y_COORD_ARG} -eq -1 ]] && MSG_Y_COORD=$(center -H -w${BOX_WIDTH}) || MSG_Y_COORD=${MSG_Y_COORD_ARG}
	fi

	BOX_X_COORD=${MSG_X_COORD}
	BOX_Y_COORD=${MSG_Y_COORD}
	BOX_TEXT_CSR=$(( BOX_Y_COORD + 1 )) # Initialize inside frame
	# --- END COORDS SETUP ---

	box_coords_set ${TAG} X ${BOX_X_COORD} Y ${BOX_Y_COORD} H ${BOX_HEIGHT} W ${BOX_WIDTH} S ${TEXT_STYLE}

	stty -echo

	# Call once for CONTINUOUS messages
	if [[ ${CONTINUOUS} == 'true' ]];then
		if [[ ${_CONT_DATA[BOX]} == 'false' ]];then
			msg_unicode_box ${BOX_X_COORD} ${BOX_Y_COORD} ${BOX_WIDTH} ${BOX_HEIGHT} ${FRAME_COLOR}
			TAG=${_CONT_BOX_TAG}
			box_coords_set ${_CONT_BOX_TAG} X ${BOX_X_COORD} Y ${BOX_Y_COORD} H ${BOX_HEIGHT} W ${BOX_WIDTH} S ${TEXT_STYLE}
			_CONT_DATA[W]=${BOX_WIDTH}
			_CONT_DATA[HEADER]=${HDR_LINES}
			_CONT_DATA[OUT]=0
			_CONT_BUFFER=()
			_CONT_DATA[BOX]=true
		fi
	else
		msg_unicode_box ${BOX_X_COORD} ${BOX_Y_COORD} ${BOX_WIDTH} ${BOX_HEIGHT} ${FRAME_COLOR}

		if [[ ${MSG_PAGING} == 'true' ]];then
			GAP=$(msg_calc_gap ${#MSG_BODY} ${PG_LINES})
			for (( GAP_NDX=1;GAP_NDX<=${GAP};GAP_NDX++));do
				MSG_BODY+=" "
			done
		fi
	fi

	# Output MSG lines
	if [[ ${CONTINUOUS} == 'true' ]];then
		CONT_COORDS=($(box_coords_get ${_CONT_BOX_TAG}))
		_CONT_DATA[TOP]=${CONT_COORDS[X]} && (( _CONT_DATA[TOP]++ ))
		_CONT_DATA[Y]=${CONT_COORDS[Y]} && (( _CONT_DATA[Y]++ ))
		_CONT_DATA[MAX]=${CONT_COORDS[H]} && (( _CONT_DATA[MAX]-=2 ))
		_CONT_DATA[COLS]=${CONT_COORDS[W]} && (( _CONT_DATA[COLS]-=4 ))

		[[ ${_CONT_DATA[OUT]} -eq 0 ]] && _CONT_DATA[SCR]=${_CONT_DATA[TOP]}
		[[ ${_CONT_DATA[HEADER]} -gt 0 ]] && (( _CONT_DATA[TOP] += _CONT_DATA[HEADER] ))

		BUFFER_FULL=false
		if [[ ${_CONT_DATA[OUT]} -ge ${_CONT_DATA[MAX]} ]];then
			BUFFER_FULL=true
			shift _CONT_BUFFER
			_CONT_DATA[SCR]=${_CONT_DATA[TOP]}
			for M in ${_CONT_BUFFER};do
				tcup ${_CONT_DATA[SCR]} ${_CONT_DATA[Y]}
				echo -n ${M}
				(( _CONT_DATA[SCR]++))
			done
		fi
		
		box_coords_upd ${_CONT_BOX_TAG} S ${TEXT_STYLE}
		MSG_OUT=$(msg_box_align ${_CONT_BOX_TAG} ${MSGS[1]})
		MSG_OUT=$(str_trim ${MSG_OUT})

		[[ -n ${_MSG_BOX_DISPLAY_AREA} ]] && DISPLAY_AREA=${_MSG_BOX_DISPLAY_AREA} || DISPLAY_AREA=$(( BOX_WIDTH - 2 ))

		tcup ${_CONT_DATA[SCR]} ${_CONT_DATA[Y]}
		tput ech $(( BOX_WIDTH - 2 ))
		[[ ${BUFFER_FULL} == 'true' ]] && MSG_OUT="${BOLD}${MSG_OUT}${RESET}"
		echo -n "${MSG_OUT}"

		if [[ ${_CONT_DATA[OUT]} -ge ${_CONT_DATA[HEADER]} ]];then
			_CONT_BUFFER+="${FAINT}${MSG_OUT}${RESET}"
		fi

		(( _CONT_DATA[SCR]++))
		(( _CONT_DATA[OUT]++))
	else
		# Headers
		if [[ -n ${MSG_HEADER} ]];then
			SCR_NDX=${BOX_X_COORD} 
			DTL_NDX=0
			_HDR_SECTION=true
			for H in ${MSG_HEADER};do
				(( SCR_NDX++))
				(( DTL_NDX++))
				MSG_OUT=$(msg_box_align ${TAG} ${H})
				tcup ${SCR_NDX} ${BOX_TEXT_CSR}
				tput ech $(( BOX_WIDTH - 2 ))
				echo -n "${MSG_OUT}"
			done
			_HDR_SECTION=false
		fi

		# Body
		SCR_NDX=$(( BOX_X_COORD + ${#MSG_HEADER} ))
		DTL_NDX=0

		for (( MSG_NDX=1;MSG_NDX<=${#MSG_BODY};MSG_NDX++));do
			(( SCR_NDX++ ))
			(( DTL_NDX++ ))
			MSG_OUT=$(msg_box_align ${TAG} ${MSG_BODY[${MSG_NDX}]})
			tcup ${SCR_NDX} ${BOX_TEXT_CSR}
			tput ech $(( BOX_WIDTH - 2 ))
			echo -n "${MSG_OUT}"

			[[ ${SO} == 'true' ]] && tput smso

			if [[ ${MSG_PAGING} == 'true' ]];then
				[[ ${XDG_SESSION_TYPE:l} == 'x11' ]] && eval "xset ${_XSET_MENU_RATE}"

				if [[ $(( DTL_NDX % PG_LINES )) -eq 0 ]];then
					[[ ${MSG_NDX} -le ${PG_LINES} ]] && PG_INIT=true || PG_INIT=false
					MSG_PAGE=$(msg_paging_page ${MSG_PAGE} ${_MSG_KEY} ${PG_INIT})
					MSG_OUT=$(msg_box_align ${TAG} "<w>Page ${MSG_PAGE} of ${MSG_PAGES}<N>")
					PAGING_BOT=${SCR_NDX}
					(( SCR_NDX+=2 ))
					tcup ${SCR_NDX} ${BOX_TEXT_CSR}
					tput ech $(( BOX_WIDTH - 2 ))
					echo -n "${MSG_OUT}"
					_MSG_KEY=$(get_keys)
					case ${_MSG_KEY} in
						27) return;;
						c) break;;
						q) exit_request $(msg_box_ebox_coords ${BOX_X_COORD} ${BOX_Y_COORD} ${BOX_WIDTH} ${#MSG_HEADER});(( MSG_NDX-=PG_LINES ));;
					esac
					MSG_NDX=$(msg_paging ${_MSG_KEY} ${MSG_NDX} ${#MSG_BODY} ${PG_LINES})
					DTL_NDX=0 && SCR_NDX=$(( BOX_X_COORD + ${#MSG_HEADER} ))
				fi
			fi
		done

		# Footer
		[[ ${MSG_PAGING} == 'true' ]] && SCR_NDX=${PAGING_BOT}

		for (( MSG_NDX=1;MSG_NDX<=${#MSG_FOOTER};MSG_NDX++));do
			(( SCR_NDX++))
			(( DTL_NDX++))
			MSG_OUT=$(msg_box_align ${TAG} ${MSG_FOOTER[${MSG_NDX}]})
			tcup ${SCR_NDX} ${BOX_TEXT_CSR}
			tput ech $(( BOX_WIDTH - 2 ))
			echo -n "${MSG_OUT}"
		done

		if [[ ${PROMPT_USER} == "true" ]];then
			_MSG_KEY=$(get_keys)
		fi
	fi

	_LAST_MSG_TAG=${TAG}

	[[ ${TIMEOUT} -gt 0 ]] && sleep ${TIMEOUT} && msg_box_clear ${TAG}
	[[ ${SO} == 'true' ]] && tput rmso

	# Restore display
	tput rc
	tcup ${_MAX_ROWS} ${_MAX_COLS}
	stty echo
}

msg_box_align () {
	local TAG=${1};shift
	local MSG=${@}
	local -A BOX_COORDS=($(box_coords_get ${TAG}))
	local BOX_WIDTH=${BOX_COORDS[W]}
	local BOX_STYLE=${BOX_COORDS[S]}
	local BOX_SPAN=$(( BOX_WIDTH - 2 ))
	[[ ${BOX_SPAN} -lt 1 ]] && BOX_SPAN=1

	local PAD_L=''
	local PAD_R=''
	local MSG_OUT=''
	local OFFSET=3
	local PADDING=''
	local TEXT=''
	local LBL=''
	local VAL=''

	[[ ${_HDR_SECTION} == 'true' ]] && BOX_STYLE=c

	if [[ ${MSG} =~ '<Z>' ]];then
		MSG_OUT=" "
	elif [[ ${MSG} =~ '<SEP>' ]];then
		MSG_OUT=$(str_unicode_line ${BOX_SPAN})
	elif [[ ${MSG} =~ '<L>' ]];then
		MSG=$(sed -e 's/^.*<L>/\\u2022 /' <<<${MSG})
		TEXT=$(msg_nomarkup ${MSG})
		TEXT=$(str_trim ${TEXT})
		PAD_L=' '
		PAD_R=$(str_rep_char ' ' $(( BOX_WIDTH - (${#PAD_L} + ${#TEXT}) - OFFSET - 1 )))
		MSG_OUT="${PAD_L}${MSG}${PAD_R}"
	elif [[ ${MSG} =~ '<X>' ]];then
		MSG=$(sed -e 's/^.*<X>//' <<<${MSG})
		TEXT=$(msg_nomarkup ${MSG})
		TEXT=$(str_trim ${TEXT})
		PAD_L=' '
		PAD_R=$(str_rep_char ' ' $(( BOX_WIDTH - (${#PAD_L} + ${#TEXT}) - OFFSET - 1 )))
		MSG_OUT="${PAD_L}${MSG}${PAD_R}"
	elif [[ ${MSG} =~ '<D>' ]];then
		MSG=$(sed -e 's/^.*<D>//' <<<${MSG})
		LBL=${${(s/:/)MSG}[1]}
		LBL=${LBL:gs/#/ /}
		VAL=${${(s/:/)MSG}[2]}
		MSG="<c>${LBL}<N>:<w>${VAL}<N>"
		TEXT=$(msg_nomarkup ${MSG})
		PAD_L=' '
		PAD_R=$(str_rep_char ' ' $(( BOX_WIDTH - (${#PAD_L} + ${#TEXT}) - OFFSET )) )
		MSG_OUT="${PAD_L}${MSG}${PAD_R}"
	elif [[ ${BOX_STYLE:l} == 'l' ]];then
		TEXT=$(msg_nomarkup ${MSG})
		TEXT=$(str_trim ${TEXT})
		PAD_L=' '
		PAD_R=$(str_rep_char ' ' $(( BOX_WIDTH - (${#PAD_L} + ${#TEXT}) - OFFSET )) )
		MSG_OUT="${PAD_L}${MSG}${PAD_R}"
	elif [[ ${BOX_STYLE:l} == 'c' ]];then
		TEXT=$(msg_nomarkup ${MSG})
		TEXT=$(str_trim ${TEXT})
		PADDING=$(str_center_pad ${BOX_WIDTH} ${TEXT})
		PAD_L=$(printf ' %.0s' {1..${PADDING}})
		PAD_R=$(str_rep_char ' ' $(( BOX_WIDTH - (${#PAD_L} + ${#TEXT}) - ( OFFSET + 1 ) )) )
		MSG_OUT="${PAD_L}${MSG}${PAD_R}"
	else
		TEXT=$(msg_nomarkup ${MSG})
		MSG_OUT=$(str_trim ${TEXT})
	fi

	MSG_OUT=$(msg_markup ${MSG_OUT})
	echo ${MSG_OUT}
}

msg_box_clear () {
	local TAG=${1}
	local -A BOX_COORDS=()
	local X_COORD_ARG=''
	local Y_COORD_ARG=''
	local H_COORD_ARG=''
	local W_COORD_ARG=''
	local X

	if [[ ${#} -eq 1 ]];then
		TAG=${1}
		[[ -z ${TAG} ]] && return 1
		BOX_COORDS=($(box_coords_get ${TAG}))
		[[ -z ${BOX_COORDS} ]] && return 1
	elif [[ ${#} -eq 4 ]];then
		BOX_COORDS=($(box_coords_get ${_LAST_MSG_TAG}))
		[[ -z ${BOX_COORDS} ]] && return 1

		X_COORD_ARG=${1}
		Y_COORD_ARG=${2}
		H_COORD_ARG=${3}
		W_COORD_ARG=${4}

		[[ ${X_COORD_ARG} != 'X' ]] && BOX_COORDS[X]=${X_COORD_ARG}
		[[ ${Y_COORD_ARG} != 'Y' ]] && BOX_COORDS[Y]=${Y_COORD_ARG}
		[[ ${H_COORD_ARG} != 'H' ]] && BOX_COORDS[H]=${H_COORD_ARG}
		[[ ${W_COORD_ARG} != 'W' ]] && BOX_COORDS[W]=${W_COORD_ARG}
	else
		BOX_COORDS=($(box_coords_get ${_LAST_MSG_TAG}))
		[[ -z ${BOX_COORDS} ]] && return 1
	fi

	for (( X=${BOX_COORDS[X]}; X <= ( ${BOX_COORDS[X]} + ${BOX_COORDS[H]} - 1 ); X++));do
		tcup ${X} ${BOX_COORDS[Y]}
		tput ech ${BOX_COORDS[W]}
	done

	[[ ${_REPAINT} == 'true' ]] && box_coords_repaint ${TAG}
	return 0
}

msg_box_ebox_coords () {
	local X=${1}
	local Y=${2}
	local W=${3}
	local HEADER=${4}

	echo $(( X + ${HEADER} + 2 )) $(( Y + W / 2 ))
}

msg_box_parse () {
	local MAX_WIDTH=${1};shift
	local MSGS_IN=${@}
	local -a MSGS_OUT=()
	local DELIM_COUNT=0
	local MSG=''
	local K L T 

	MSGS_IN=$(tr -d "\n" <<<${MSGS_IN})
	MSGS_IN=$(sed -E "s/[\\\][${_DELIM}]/_DELIM_/g" <<<${MSGS_IN})

	DELIM_COUNT=$(grep --color=never -o "[${_DELIM}]" <<<${MSGS_IN} | wc -l)

	for (( X=1; X <= $(( ${DELIM_COUNT} + 1 )); X++ ));do
		[[ ${DELIM_COUNT} -ne 0 ]] && MSG=$(cut -d"${_DELIM}" -f${X} <<<${MSGS_IN}) || MSG=${MSGS_IN}
	 	MSG=$(sed "s/_DELIM_/${_DELIM}/g" <<<${MSG})
		L=$(tr -d '[:space:]' <<<${MSG})
		[[ -z ${L} ]] && continue
		if [[ ${#MSG} -gt ${MAX_WIDTH} ]];then
			MSG_FOLD=("${(f)$(fold -s -w${MAX_WIDTH} <<<${MSG})}")
			for T in ${MSG_FOLD};do
				MSGS_OUT+=$(str_trim ${T})
			done
		else
			MSGS_OUT+=${MSG}
		fi
	done

	for M in ${MSGS_OUT};do
		echo ${M}
	done
}

msg_calc_gap () {
	local MSG_ROWS=${1}
	local DISP_ROWS=${2}
	local DTL_LINES=0
	local TL_PAGES=0
	local PARTIAL
	local GAP=0

	TL_PAGES=$(( MSG_ROWS / DISP_ROWS ))
	PARTIAL=$(( MSG_ROWS % DISP_ROWS ))

	[[ ${PARTIAL} -ne 0 ]] && (( TL_PAGES++))

	GAP=$(( (TL_PAGES * DISP_ROWS) - MSG_ROWS ))
	echo ${GAP}
}

msg_line_weight () {
	_BOX_LINE_WEIGHT=${1}
}

msg_list_bullet () {
	local -a MSG=(${@})
	local DELIM='|'
	local NDX=0
	local L

	for L in ${MSG};do
		(( NDX++))
		echo -n "<L>${L}"
		[[ ${NDX} -lt ${#MSG} ]] && echo ${DELIM}
	done
}

msg_list_number () {
	local -a MSG=(${@})
	local DELIM='|'
	local NDX=0
	local L

	for L in ${MSG};do
		(( NDX++))
		echo -n "<X>${NDX}) ${L}"
		[[ ${NDX} -lt ${#MSG} ]] && echo ${DELIM}
	done
}

msg_list_data () {
	local -a MSG=(${@})
	local DELIM='|'
	local LBL
	local LINE=''
	local MARK=0
	local MAX=0
	NDX=0
	local PAD=0
	local VAL
	local L 

	MAX=0
	for L in ${MSG};do
		NDX=${L[(i)[:]]}
		[[ ${NDX} -gt ${MAX} ]] && MAX=${NDX}
	done

	NDX=0
	for L in ${MSG};do
		((NDX++))
		MARK=${L[(i)[:]]}
		[[ ${MARK} -lt ${MAX} ]] && PAD=$(( MAX - MARK )) || PAD=0
		PAD=$(( PAD + ${#L} ))
		VAL=${${(s/:/)L}[2]}
		LINE="<D> ${(l(${PAD})(#))L}:${VAL}"
		[[ ${NDX} -lt ${#MSG} ]] && echo -n ${LINE}${DELIM} || echo -n ${LINE}
	done
}

msg_markup () {
	local MSG=${@}

	perl -pe 'BEGIN { 
	%ES=(
	"B"=>"[1m",
	"I"=>"[3m",
	"N"=>"[m",
	"O"=>"[9m",
	"R"=>"[7m",
	"S"=>"[9m",
	"U"=>"[4m",
	"b"=>"[34m",
	"c"=>"[36m",
	"f"=>"[2m",
	"g"=>"[32m",
	"h"=>"[0m\e[0;1;37;100m",
	"m"=>"[35m",
	"r"=>"[31m",
	"u"=>"[4m",
	"w"=>"[37m",
	"y"=>"[33m"
	) }; 
	{ s/<([BINORSUrughybmcfw])>/\e$ES{$1}/g; }' <<<${MSG}
}

msg_nomarkup () {
	local MSG=${@}
	local MSG_OUT

	MSG_OUT=$(perl -pe 's/(<B>|<I>|<L>|<N>|<O>|<R>|<U>|<b>|<c>|<g>|<h>|<m>|<r>|<w>|<y>)//g' <<<${MSG})
	echo ${MSG_OUT}
}

msg_paging () {
	local KEY=${1}
	local NDX=${2}
	local LIST_ROWS=${3}
	local PG_LINES=${4}
	local PARTIAL=0
	local TL_PAGES=0
	local TOP=0
	local BOT=0
	local PGUP=0
	local PGDN=0

	TL_PAGES=$(( LIST_ROWS / PG_LINES ))
	PARTIAL=$(( LIST_ROWS % PG_LINES ))
	[[ ${PARTIAL} -ne 0 ]] && (( TL_PAGES++))

	TOP=0
	BOT=$(( (TL_PAGES - 1) * PG_LINES ))
	PGUP=$(( NDX - (PG_LINES * 2) )); [[ ${PGUP} -lt 1 ]] && PGUP=0
	PGDN=${NDX}

	case ${KEY} in
		t|h) echo ${TOP};;
		b|l) echo ${BOT};;
		u|k|p) echo ${PGUP};;
		d|j|n) echo ${PGDN};;
	esac
}

msg_paging_page () {
	local PAGE=${1}
	local KEY=${2}
	local INIT=${3}

	case ${KEY} in
		j|d|n) [[ ${PG_INIT} == 'false' ]] && (( PAGE++));;
		k|u|p) [[ ${PAGE} -gt 1 ]] && (( PAGE--));;
	esac

	echo ${PAGE}
}

msg_proc () {
	local BOX_W=20
	local BOX_H=3
	local H_POS=$(center -H -w${BOX_W})
	local V_POS=$(center -V -h${BOX_H})
	local X R C

	msg_unicode_box ${V_POS} ${H_POS} ${BOX_W} ${BOX_H}
	tcup $(( V_POS + 1 )) $(( H_POS + 2 ));echo -n "${GREEN_FG}Processing...${RESET}"
	TAG=${_PROC_BOX_TAG}
	box_coords_set ${TAG} X ${V_POS} Y ${H_POS} W ${BOX_W} H ${BOX_H}
	_PROC_MSG=false

	sleep .5

	R=${V_POS}
	C=${H_POS}
	for (( X=${V_POS}; X<BOX_H+V_POS; X++ ));do
		tcup ${R} ${C} 
		tput ech ${BOX_W}
		((R++))
	done
}

msg_stream () {
	local -a CMD
	local -a MSG_LINES
	local DELIM='|'
	local STYLE=l
	local FOLD_WIDTH=105
	local FOLD=''
	local MSG=''
	local LINE_CNT=0
	local PAD=''
	local NDX=0

	local OPTION
	local OPTSTR=":f:lcn"
	OPTIND=0

	while getopts ${OPTSTR} OPTION;do
		case ${OPTION} in
			f) FOLD_WIDTH=${OPTARG};;
			l) STYLE=l;;
			c) STYLE=c;;
			n) STYLE=n;;
			:) print -u2 " ${_SCRIPT}: ${0}: option: -${OPTARG} requires an argument" >&2;read ;;
			\?) print -u2 " ${_SCRIPT}: ${0}: unknown option -${OPTARG}" >&2; read;;
		esac
	done
	shift $(( OPTIND - 1 ))

	FOLD="| fold -s -w ${FOLD_WIDTH}"
	CMD=(${@})

	coproc { eval ${CMD} | \
		sed -e 's// /g'  \
		-e 's/  */ /g'  \
		-e 's/</\xe2\x98\x87/g'  \
		-e 's/|/or/g'  \
		-e 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
		fold -s -w ${FOLD_WIDTH}  \
	}

	LINE_CNT=0
	while read -p ${COPROC[0]} MSG;do
		MSG_LINES+="<w>${MSG}<N>${DELIM}"
		(( LINE_CNT++))
	done

	while true;do
		[[ ${MSG_LINES[-1]} == "<w><N>|" ]] && MSG_LINES[-1]=() || break
	done

	MSG_LINES[-1]=$(sed 's/|//g' <<< ${MSG_LINES[-1]})

	[[ -z ${#MSG_LINES[1]} || ${MSG_LINES[1]:l} =~ 'unable to locate' ]] && return

	FOLD_WIDTH=$(( FOLD_WIDTH + 4 ))
	msg_box -y20 -w${FOLD_WIDTH} -P"<m>Last Page<N>" -pc -s${DELIM} -j${STYLE} ${MSG_LINES}
}

msg_unicode_box () {
	local BOX_X_COORD=${1}
	local BOX_Y_COORD=${2}
	local BOX_WIDTH=${3}
	local BOX_HEIGHT=${4}
	local BOX_COLOR=${5:=${RESET}}
	local TOP_LEFT 
	local TOP_RIGHT
	local BOT_LEFT 
	local BOT_RIGHT
	local HORIZ_BAR 
	local VERT_BAR
	local HEAVY=false
	local L_SPAN=0
	local R_SPAN=0
	local T_SPAN=0
	local B_SPAN=0
	local X Y

	[[ $(( BOX_WIDTH - 2 )) -gt 0 ]] && BOX_WIDTH=$(( BOX_WIDTH - 2 ))
	[[ $(( BOX_HEIGHT - 2 )) -gt 0 ]] && BOX_HEIGHT=$(( BOX_HEIGHT - 2 ))

	L_SPAN=$(( BOX_Y_COORD + 1 ))
	R_SPAN=$(( BOX_Y_COORD + BOX_WIDTH ))
	T_SPAN=$(( BOX_X_COORD + 1 ))
	B_SPAN=$(( BOX_X_COORD + BOX_HEIGHT ))

	[[ ${_BOX_LINE_WEIGHT} == 'heavy' ]] && HEAVY=true && shift

	if [[ ${HEAVY} == 'false' ]];then
		BOT_LEFT="\\u2514%.0s"
		BOT_RIGHT="\\u2518%.0s"
		HORIZ_BAR="\\u2500%.0s"
		TOP_LEFT="\\u250C%.0s"
		TOP_RIGHT="\\u2510%.0s"
		VERT_BAR="\\u2502%.0s"
	else
		BOT_LEFT="\\u2517%.0s"
		BOT_RIGHT="\\u251B%.0s"
		HORIZ_BAR="\\u2501%.0s"
		TOP_LEFT="\\u250F%.0s"
		TOP_RIGHT="\\u2513%.0s"
		VERT_BAR="\\u2503%.0s"
	fi

	tput rmso
	echo -n ${BOX_COLOR}

	# Top left corner
	tcup ${BOX_X_COORD} ${BOX_Y_COORD}
	printf ${TOP_LEFT}

	# Top border
	for (( Y=${L_SPAN}; Y<=${R_SPAN}; Y++ ));do
		tcup ${BOX_X_COORD} ${Y}
		printf ${HORIZ_BAR}
	done

	# Top right corner
	printf ${TOP_RIGHT}

	# Sides
	for (( X=${T_SPAN}; X<=${B_SPAN}; X++ ));do
		tcup ${X} ${BOX_Y_COORD}
		printf ${VERT_BAR}
		tcup ${X} $(( BOX_Y_COORD + 1 ))
		tput ech ${BOX_WIDTH}
		tcup ${X} $(( R_SPAN + 1 ))
		printf ${VERT_BAR}
	done

	# Bottom left corner
	tcup ${X} ${BOX_Y_COORD}
	printf ${BOT_LEFT}

	# Bottom border
	for (( Y=${L_SPAN}; Y<=${R_SPAN}; Y++ ));do
		tcup ${X} ${Y}
		printf ${HORIZ_BAR}
	done

	# Bottom right corner
	tcup ${X} ${Y}
	printf ${BOT_RIGHT}

	echo -n ${RESET}
}

msg_warn () {
	local MSG=${@}
	local LABEL='Warning'

	grep -q '|' <<<${MSG}
	[[ ${?} -eq 0 ]] && LABEL${${(s/|/)MSG}[1]} && MSG${${(s/|/)MSG}[2]}

	if [[ -n ${MSG} ]];then
		[[ ${MSG} =~ ":" ]] && MSG=$(perl -p -e 's/:(.*)/\e[m:\e[3;37m$1\e[m/g' <<<${MSG})
		printf "[${WHITE_FG}%s${RESET}]:[${RED_FG}${LABEL}${RESET}] %s" ${_SCRIPT} "${MSG}"
	fi
}
