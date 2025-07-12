# LIB Dependencies
_DEPS_+="ARRAY.zsh DBG.zsh STR.zsh TPUT.zsh UTILS.zsh"

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
_REPAINT=true

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
	local MIN_X_COORD=$(( (_MAX_ROWS - MAX_X_COORD)-1 )) # Vertical limit
	local MIN_Y_COORD=$(( _MAX_COLS - MAX_Y_COORD )) # Horiz limit
	local USABLE_COLS=$(( MAX_Y_COORD - MIN_Y_COORD )) # Horizontal space boundary
	local USABLE_ROWS=$(( MAX_X_COORD - MIN_X_COORD )) # Vertical space boundary
	local MAX_LINE_WIDTH=$(( USABLE_COLS - 20 ))

	local BOX_HEIGHT=0
	local BOX_WIDTH=0
	local BODY_MAX=0
	local BOX_X_COORD=0
	local BOX_Y_COORD=0
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
	local NAV_BAR="<c>Navigation keys<N>: <w>t<N>,<w>h<N>=top <w>b<N>,<w>l<N>=bottom <w>p<N>,<w>k<N>=up <w>n<N>,<w>j<N>=down, <w>Esc<N>=close<N>"
	local OPTION=''
	local PAGING_BOT=0
	local PARTIAL=0
	local PG_LINES=0
	local PG_INIT=''
	local SCR_NDX=0
	local TAG=''
	local H K M T X 

	# OPTIONS
	local -a MSG=()
	local CLEAR_MSG=false
	local CONTINUOUS=false
	local DELIM_ARG=false
	local DISPLAY_AREA=0
	local FOLD_WIDTH=${MAX_LINE_WIDTH}
	local FRAME_COLOR=''
	local HDR_LINES=0
	local HDR_FTR_LINES=0
	local HEIGHT_ARG=0
	local LEN=0
	local MSG_X_COORD_ARG=-1
	local MSG_Y_COORD_ARG=-1
	local PROMPT_ARG=''
	local PROMPT_USER=false
	local QUIET=false
	local RELATIVE=false
	local SAFE=true
	local SCROLLING=false
	local SO=false
	local TAG_ARG=''
	local TEXT_STYLE=c # Default is center - Accepted Values:[(l)eft,(c)enter]
	local TIMEOUT=0
	local WIDTH_ARG=0

	local OPTSTR=":H:P:O:CIRT:cf:h:j:pqrs:t:uw:x:y:z"
	OPTIND=0

	while getopts ${OPTSTR} OPTION;do
		case ${OPTION} in
			H) HDR_LINES=${OPTARG};; # Number of msg lines that comprise header
			C) CONTINUOUS=true;; # Message is added to the existing continuous msg
			O) FRAME_COLOR=${OPTARG};; # Set color for message frame
			P) PROMPT_ARG=${OPTARG};; # Text for message prompt
			I) _CONT_DATA[BOX]=false;; # Trigger initialization of continuous message
			R) RELATIVE=true;; # Use this tag to retreive a alternative placement coord
			T) TAG_ARG=${OPTARG};; # TAG name to use when saving message coordinates
			c) CLEAR_MSG=true;; # Clear the previous message before displaying the current message
			f) FOLD_WIDTH=${OPTARG};; # Fold the message text using this line width
			h) HEIGHT_ARG=${OPTARG};; # Specify a message box height other than the default
			j) TEXT_STYLE=${OPTARG};; # Specify desired text justification (center, left)
			p) PROMPT_USER=true;; # Request user input following message display
			q) QUIET=true;; # Suppress progress messages
			r) SO=true;; # Request standout mode
			s) DELIM_ARG="${OPTARG}";; # Use this delimiter to break message parts
			t) TIMEOUT="${OPTARG}";; # Display message only for this time limit
			u) SAFE=false;; # Ensure no coordinates violate available screen dimensions
			w) WIDTH_ARG=${OPTARG};; # Specify a message box width other than the default
			x) MSG_X_COORD_ARG=${OPTARG};; # Specify a message display row other than the default
			y) MSG_Y_COORD_ARG=${OPTARG};; # Specify a message display col other than the default
			z) _REPAINT=false;; # Override repaints
			:) print -u2 " ${_SCRIPT}: ${0}: option: -${OPTARG} requires an argument" >&2;read ;;
			\?) print -u2 " ${_SCRIPT}: ${0}: unknown option -${OPTARG}" >&2; read;;
		esac
	done
	shift $(( OPTIND -1 ))

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

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
	MSG_LEN=${*}
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
			Q) MSG_FOOTER+="|<Z>|<w>Queue? (y/n)<N>";;
			V) MSG_FOOTER+="|<Z>|<w>View? (y/n)<N>";;
			X) MSG_FOOTER+="|<Z>|<w>Kill? (y/n)<N>";;
			*) MSG_FOOTER+="|<Z>|<w>${PROMPT_ARG}<N>";;
		esac
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ADDED PROMPT:${PROMPT_ARG}"
	fi

	# Get message delimiter
	[[ ${DELIM_ARG} != 'false' ]] && _DELIM=${DELIM_ARG} # Assign delimiter
	[[ ${#DELIM} -gt 1 ]] && exit_leave $(msg_err "${functrace[1]} called ${0}:${LINENO}: Invalid delimiter:${DELIM}")

	# Flash progress msg if requested
	[[ ${_PROC_MSG} == 'true' ]] && msg_proc

	MSGS=("${(f)$(msg_box_parse ${MAX_LINE_WIDTH} ${MSG})}")
	[[ -n ${MSG_FOOTER} ]] && MSG_FOOTER=("${(f)$(msg_box_parse ${MAX_LINE_WIDTH} ${MSG_FOOTER})}")

	# Separate headers and footers from body
	if [[ ${HDR_LINES} -ne 0 ]];then
		MSG_HEADER=(${MSGS[1,$(( HDR_LINES ))]})
		MSG_BODY=(${MSGS[HDR_LINES+1,-1]})
		MSG_ROWS=$(( ${#MSG_HEADER} + ${#MSG_BODY} + ${#MSG_FOOTER} ))
		if [[ ${_DEBUG} -ge ${_HIGH_DBG} ]];then
			dbg "${0}: HAS HEADERS"
			dbg "${0}: HEADER CONTAINS ${#MSG_HEADER} lines"
			dbg "${0}: MSG_HEADER FOLLOWS:\n>>>\n$(for M in ${MSG_HEADER};do echo ${M};done)\n<<<\n"
			dbg "${0}: BODY CONTAINS ${#MSG_BODY} lines"
			dbg "${0}: MSG_FOOTER: ${MSG_FOOTER:-null}"
			dbg "${0}: FOOTER CONTAINS ${#MSG_FOOTER} lines"
			dbg "${0}: TOTAL LINES:${MSG_ROWS}"
		fi
	else
		MSG_BODY=(${MSGS})
		MSG_ROWS=$(( ${#MSG_BODY} + ${#MSG_FOOTER} ))
		if [[ ${_DEBUG} -ge ${_HIGH_DBG} ]];then
			dbg "${0}: HAS ${RED_FG}NO${RESET} HEADERS"
			dbg "${0}: BODY CONTAINS ${#MSG_BODY} lines"
			dbg "${0}: MSG_BODY FOLLOWS:\n>>>\n$(for M in ${MSG_BODY};do echo ${M};done)\n<<<\n"
			dbg "${0}: MSG_FOOTER: ${MSG_FOOTER:-null}"
			dbg "${0}: FOOTER CONTAINS ${#MSG_FOOTER} lines"
			dbg "${0}: TOTAL LINES:${MSG_ROWS}"
		fi
	fi

	# --- BEGIN COORDS SETUP ---
	HDR_FTR_LINES=$(( ${#MSG_HEADER} + ${#MSG_FOOTER} + 2 )) # Allowance for vertical header and footer space

	if [[ ${HEIGHT_ARG} -ne 0 ]];then
		if [[ ${MSG_ROWS} -gt ${HEIGHT_ARG} ]];then
			MSG_PAGING=true
			PG_LINES=$(( HEIGHT_ARG - HDR_FTR_LINES ))
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${CYAN_FG}MESSAGE PAGING TRIGGERED${RESET} PG_LINES:${PG_LINES} HEIGHT_ARG:${HEIGHT_ARG}"
		fi
	elif [[ ${MSG_ROWS} -gt ${USABLE_ROWS} ]];then
		MSG_PAGING=true
		PG_LINES=$(( USABLE_ROWS - HDR_FTR_LINES ))
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${CYAN_FG}MESSAGE PAGING TRIGGERED${RESET} PG_LINES:${PG_LINES} USABLE_ROWS:${USABLE_ROWS}"
	else
		PG_LINES=${#MSG_BODY}
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ${CYAN_FG}MESSAGE ${RED_FG}NOT ${CYAN_FG}PAGED${RESET} PG_LINES:${PG_LINES}"
	fi

	if [[ ${_DEBUG} -ge ${_HIGH_DBG} ]];then
		dbg "${0}:  --- DISPLAY LIMITS ---"
		dbg "${0}:     MAX ROWS:${WHITE_FG}${_MAX_ROWS}${RESET} MAX COLS:${WHITE_FG}${_MAX_COLS}${RESET}"
		dbg "${0}:  USABLE_ROWS:${WHITE_FG}${USABLE_ROWS}${RESET} USABLE_COLS:${WHITE_FG}${USABLE_COLS}${RESET}"
		dbg "${0}: MIN_XY_COORD:${WHITE_FG}(X:${MIN_X_COORD},Y:${MIN_Y_COORD})${RESET}"
		dbg "${0}: MAX_XY_COORD:${WHITE_FG}(X:${MAX_X_COORD},Y:${MAX_Y_COORD})${RESET}"
	fi
	
	HDR_MAX=$(arr_long_elem ${MSG_HEADER})
	BODY_MAX=$(arr_long_elem ${MSG_BODY})
	FOOTER_MAX=$(arr_long_elem ${MSG_FOOTER})

	MAX_ELEM=$(max ${#HDR_MAX} ${#BODY_MAX})
	MAX_ELEM=$(max ${MAX_ELEM} ${#FOOTER_MAX})

	MSG_COLS=$(( MAX_ELEM + 1 ))
	MSG_SEP="<SEP>"

	# Process various message types
	if [[ ${MSG_PAGING}  == 'true' ]];then
		MSG_STR=$(msg_nomarkup ${NAV_BAR}) # Strip markup

		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: MSG_STR:${MSG_STR} MSG_COLS:${MSG_COLS}"

		# Adding header lines reduces paging area (PG_LINES)
		[[ -n ${MSG_HEADER} ]] && (( PG_LINES-=2 )) || (( PG_LINES--)) # With headers add BAR,HDR,SEP else add BAR,SEP only

		# Replace page count token in NAV_BAR
		MSG_PAGES=$(( ${#MSG_BODY} / PG_LINES ))
		PARTIAL=$((${#MSG_BODY} % PG_LINES ))
		[[ ${PARTIAL} -ne 0 ]] && (( MSG_PAGES++))
		NAV_BAR=$(sed "s/_MSG_PG/${MSG_PAGES}/" <<< ${NAV_BAR})

		if [[ -n ${MSG_HEADER} ]];then # Has headers
			MSG_HEADER=(${MSG_HEADER} ${NAV_BAR} ${MSG_SEP}) # Add BAR,HDR,SEP
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: FORMAT PAGING HEADER w/BAR,HDR,SEP"
		else # No headers
			MSG_HEADER=(${NAV_BAR} ${MSG_SEP}) # Add BAR,SEP
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: FORMAT PAGING HEADER w/BAR,SEP"
		fi
		MSG_COLS=$(( ${#MSG_STR} + 1 )) # Clean NAV_BAR
	elif [[ -n ${MSG_HEADER} ]];then # Non-paged w/headers
		MSG_HEADER=(${MSG_HEADER} ${MSG_SEP}) # Add separator
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: FORMAT NORMAL HEADER W/ HEADER and SEP"
	fi

	(( MSG_COLS+=2 )) # Add gutter

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: FINAL MSG_COLS:${MSG_COLS}"

	if [[ ${SAFE} == 'true' ]];then
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: CATCHING ANY DISPLAY OVERRUNS"
		[[ ${MSG_X_COORD} -lt ${MIN_X_COORD} ]] && MSG_X_COORD=${MIN_X_COORD}
		[[ ${MSG_X_COORD} -gt ${USABLE_ROWS} ]] && MSG_X_COORD=${USABLE_ROWS}
		[[ ${MSG_Y_COORD} -lt ${MIN_Y_COORD} ]] && MSG_Y_COORD=${MIN_Y_COORD}
		[[ ${MSG_Y_COORD} -gt ${USABLE_COLS} ]] && MSG_Y_COORD=${USABLE_COLS}
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: MSG_X_COORD:${MSG_X_COORD} MSG_Y_COORD:${MSG_Y_COORD}"
	fi

	# Set box coords
	if [[ ${RELATIVE} == 'true' ]];then
		if [[ -n ${_REL_COORDS} ]];then
			MSG_X_COORD=${_REL_COORDS[X]}
			MSG_Y_COORD=${_REL_COORDS[Y]}
			BOX_WIDTH=${_REL_COORDS[W]}
			BOX_HEIGHT=${_REL_COORDS[H]}
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: RELATIVE COORDS: MSG_X_COORD:${_REL_COORDS[X]} MSG_Y_COORD:${_REL_COORDS[Y]} BOX_WIDTH:${_REL_COORDS[W]} BOX_HEIGHT:${_REL_COORDS[H]}"
		fi
	else
		[[ ${WIDTH_ARG} -eq 0 ]] && BOX_WIDTH=$(( MSG_COLS + 4 )) || BOX_WIDTH=${WIDTH_ARG}
		[[ ${HEIGHT_ARG} -eq 0 ]] && BOX_HEIGHT=$(( PG_LINES + ${#MSG_HEADER} + ${#MSG_FOOTER} +2 )) || BOX_HEIGHT=${HEIGHT_ARG}
		[[ ${MSG_X_COORD_ARG} -eq -1 ]] && MSG_X_COORD=$((  (_MAX_ROWS-BOX_HEIGHT) / 2 + 1 )) || MSG_X_COORD=${MSG_X_COORD_ARG}
		[[ ${MSG_Y_COORD_ARG} -eq -1 ]] && MSG_Y_COORD=$(coord_center $(( _MAX_COLS - 3 )) BOX_WIDTH) || MSG_Y_COORD=${MSG_Y_COORD_ARG}
	fi

	# Box coords - compensate for frame
	BOX_X_COORD=${$(( MSG_X_COORD - 1 )):=1}
	BOX_Y_COORD=${$(( MSG_Y_COORD - 1 )):=1}
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: FRAME COMPENSATION: BOX_X_COORD:${BOX_X_COORD} BOX_Y_COORD:${BOX_Y_COORD}"
	# --- END COORDS SETUP ---

	# Save box coords
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "$(for L in ${(Oa)funcstack};do echo TAG:${TAG} FUNCSTACK:${L};done)"

	box_coords_set ${TAG} X ${BOX_X_COORD} Y ${BOX_Y_COORD} H ${BOX_HEIGHT} W ${BOX_WIDTH} S ${TEXT_STYLE}
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SAVED TAG:${TAG} _BOX_COORDS: $(box_coords_get ${TAG})"

	if [[ ${_DEBUG} -ge ${_HIGH_DBG} ]];then
		dbg "${0}: --- BOX COORDS ---"
		dbg "${0}: TAG:${TAG}"
		dbg "${0}: BOX_X,Y:${WHITE_FG}(${BOX_X_COORD},${BOX_Y_COORD})${RESET}"
		dbg "${0}: BOX_HEIGHT:${WHITE_FG}${BOX_HEIGHT}${RESET}"
		dbg "${0}: BOX_WIDTH:${WHITE_FG}${BOX_WIDTH}${RESET}"
	fi

	# Prepare display
	[[ ${SO} == 'true' ]] && tput smso # Standout mode

	# Call once for CONTINUOUS messages
	if [[ ${CONTINUOUS} == 'true' ]];then
		if [[ ${_CONT_DATA[BOX]} == 'false' ]];then # Trigger initial box generation
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
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CREATED BOX FOR TAG:${TAG} _BOX_COORDS: $(box_coords_get ${TAG})"

		# Handle last page gap
		if [[ ${MSG_PAGING} == 'true' ]];then
			# Get the amount of padding necessary to break the page on even boundaries
			GAP=$(msg_calc_gap ${#MSG_BODY} ${PG_LINES})
			[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: LAST PAGE GAP:${WHITE_FG}${GAP}${RESET}"

			# Pad messages to break evenly across pages
			for (( GAP_NDX=1;GAP_NDX<=${GAP};GAP_NDX++));do
				MSG_BODY+=" "
			done
			[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ADDED GAP PADDING: MSG_BODY LINES:${#MSG_BODY}"
		fi
	fi

	# Output MSG lines
	if [[ ${CONTINUOUS} == 'true' ]];then
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:${CYAN_FG}MSG is CONTINUOUS${RESET}"
		CONT_COORDS=($(box_coords_get ${_CONT_BOX_TAG}))
		_CONT_DATA[TOP]=${CONT_COORDS[X]} && (( _CONT_DATA[TOP]++ )) # Initialize TOP and move past border
		_CONT_DATA[Y]=${CONT_COORDS[Y]} && (( _CONT_DATA[Y]++ )) # Initialize Y and move past border
		_CONT_DATA[MAX]=${CONT_COORDS[H]} && (( _CONT_DATA[MAX]-=2 )) # Initialize MAX and move past border
		_CONT_DATA[COLS]=${CONT_COORDS[W]} && (( _CONT_DATA[COLS]-=4 )) # Initialize COLS and compensate for border

		[[ ${_CONT_DATA[OUT]} -eq 0 ]] && _CONT_DATA[SCR]=${_CONT_DATA[TOP]} # Nothing yet output - initialize cursor to output region
		[[ ${_CONT_DATA[HEADER]} -gt 0 ]] && (( _CONT_DATA[TOP] += _CONT_DATA[HEADER] )) # HEADER is present - cursor through header lines

		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:\n_CONT_DATA[OUT]:${_CONT_DATA[OUT]}\n_CONT_DATA[MAX]:${_CONT_DATA[MAX]}\n_CONT_DATA[TOP]:${_CONT_DATA[TOP]}\n#_CONT_BUFFER:${#_CONT_BUFFER}"

		if [[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]];then
			[[ ${_CONT_DATA[OUT]} -lt ${_CONT_DATA[HEADER]} ]] && dbg "${0}:${CYAN_FG}HEADER IS PRINTING${RESET}"
			[[ ${_CONT_DATA[OUT]} -eq ${_CONT_DATA[HEADER]} ]] && dbg "${0}:${GREEN_FG}HEADER IS COMPLETE${RESET}"
		fi

		SCROLLING=false
		if [[ ${_CONT_DATA[OUT]} -ge ${_CONT_DATA[MAX]} ]];then # Usable display area consumed - shift data lines up
			SCROLLING=true
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:${RED_FG}BUFFER SHIFT${RESET}"
			shift _CONT_BUFFER # Discard top line
			_CONT_DATA[SCR]=${_CONT_DATA[TOP]} # Set cursor to header offset
			for M in ${_CONT_BUFFER};do
				tput cup ${_CONT_DATA[SCR]} ${_CONT_DATA[Y]} # Place cursor
				[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:Dumping buffer line:${M}"
				echo -n ${M} # Output buffered line
				(( _CONT_DATA[SCR]++)) # Increment cursor
			done
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:CURSOR value following buffer dump:${_CONT_DATA[SCR]}"
		fi
		
		box_coords_upd ${_CONT_BOX_TAG} S ${TEXT_STYLE}
		MSG_OUT=$(msg_box_align ${_CONT_BOX_TAG} ${MSGS[1]}) # Apply markup, padding 
		MSG_OUT=$(str_trim ${MSG_OUT})

		[[ -n ${_MSG_BOX_DISPLAY_AREA} ]] && DISPLAY_AREA=${_MSG_BOX_DISPLAY_AREA} || DISPLAY_AREA=${BOX_WIDTH} # If value is present limit horiz clearing
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: DISPLAY_AREA:${DISPLAY_AREA}"

		tput cup ${_CONT_DATA[SCR]} ${_CONT_DATA[Y]} # Cursor is filling display area or on last line of display area if full
		tput ech ${DISPLAY_AREA} # Clear the display area
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:Printing pending MSG line:${MSG}"
		[[ ${SCROLLING} == 'true' ]] && MSG_OUT="${BOLD}${MSG_OUT}${RESET}"
		echo -n "${MSG_OUT}" # Output line

		if [[ ${_CONT_DATA[OUT]} -ge ${_CONT_DATA[HEADER]} ]];then # If header is out, add data line to buffer
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:Buffering line:${MSG}"
			MSG_OUT="${FAINT}${MSG_OUT}${RESET}"
			_CONT_BUFFER+=${MSG_OUT}
		fi

		(( _CONT_DATA[SCR]++))
		(( _CONT_DATA[OUT]++))
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:\n    CURRENT CURSOR: ${_CONT_DATA[SCR]}\nCURRENT LINES OUT: ${_CONT_DATA[OUT]}"
	else
		# Headers
		if [[ -n ${MSG_HEADER} ]];then
			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${CYAN_FG}GENERATING HEADERS${RESET}"
			SCR_NDX=${BOX_X_COORD} 
			DTL_NDX=0
			for H in ${MSG_HEADER};do
				(( SCR_NDX++))
				(( DTL_NDX++))
				MSG_OUT=$(msg_box_align ${TAG} ${H}) # Apply justification
				tput cup ${SCR_NDX} ${MSG_Y_COORD} # Place cursor
				tput ech ${MSG_COLS} # Clear line
				echo -n "${MSG_OUT}"
				[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ${WHITE_FG}HEADER SCR_NDX${RESET}:${SCR_NDX}"
			done
		fi

		# Body
		SCR_NDX=$(( BOX_X_COORD + ${#MSG_HEADER} )) # Move past headers
		DTL_NDX=0
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${CYAN_FG}GENERATING BODY${RESET}"

		for (( MSG_NDX=1;MSG_NDX<=${#MSG_BODY};MSG_NDX++));do
			(( SCR_NDX++))
			(( DTL_NDX++))
			MSG_OUT=$(msg_box_align ${TAG} ${MSG_BODY[${MSG_NDX}]}) # Apply padding to both sides of msg
			tput cup ${SCR_NDX} ${MSG_Y_COORD} # Place cursor
			tput ech ${MSG_COLS} # Clear line
			echo -n "${MSG_OUT}"

			[[ ${SO} == 'true' ]] && tput smso # Invoke standout

			if [[ ${MSG_PAGING} == 'true' ]];then
				[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ${WHITE_FG}PAGING${RESET}: SCR_NDX:${SCR_NDX} DTL_NDX:${DTL_NDX} MSG_NDX:${MSG_NDX}"
				[[ ${XDG_SESSION_TYPE:l} == 'x11' ]] && eval "xset ${_XSET_MENU_RATE}"

				if [[ $(( DTL_NDX % PG_LINES )) -eq 0 ]];then # Page break - pause
					[[ ${MSG_NDX} -le ${PG_LINES} ]] && PG_INIT=true || PG_INIT=false
					MSG_PAGE=$(msg_paging_page ${MSG_PAGE} ${_MSG_KEY} ${PG_INIT})
					MSG_OUT=$(msg_box_align ${TAG} "<w>Page ${MSG_PAGE} of ${MSG_PAGES}<N>")
					PAGING_BOT=${SCR_NDX}
					(( SCR_NDX+=2 )) # Last row
					tput cup ${SCR_NDX} ${MSG_Y_COORD} # Place cursor
					tput ech ${MSG_COLS} # Clear line
					echo -n "${MSG_OUT}"
					_MSG_KEY=$(get_keys)
					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}_MSG_KEY:${_MSG_KEY}"
					case ${_MSG_KEY} in
						27) return;;
						q) exit_request $(msg_box_ebox_coords ${BOX_X_COORD} ${BOX_Y_COORD} ${BOX_WIDTH} ${#MSG_HEADER});(( MSG_NDX-=PG_LINES ));; # No advance if declined
					esac
					MSG_NDX=$(msg_paging ${_MSG_KEY} ${MSG_NDX} ${#MSG_BODY} ${PG_LINES})
					DTL_NDX=0 && SCR_NDX=$(( BOX_X_COORD + ${#MSG_HEADER} ))
				fi
			fi
		done

		# Footer
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${CYAN_FG}GENERATING FOOTER${RESET} SCR_NDX:${SCR_NDX}"

		[[ ${MSG_PAGING} == 'true' ]] && SCR_NDX=${PAGING_BOT}

		for (( MSG_NDX=1;MSG_NDX<=${#MSG_FOOTER};MSG_NDX++));do
			(( SCR_NDX++))
			(( DTL_NDX++))
			MSG_OUT=$(msg_box_align ${TAG} ${MSG_FOOTER[${MSG_NDX}]}) # Apply padding to both sides of msg
			tput cup ${SCR_NDX} ${MSG_Y_COORD} # Place cursor
			tput ech ${MSG_COLS} # Clear line
			echo -n "${MSG_OUT}"
			[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ${WHITE_FG}FOOTER SCR_NDX${RESET}:${SCR_NDX}"
		done

		if [[ ${PROMPT_USER} == "true" ]];then
			_MSG_KEY=$(get_keys)
		fi
	fi

	_LAST_MSG_TAG=${TAG}

	[[ ${TIMEOUT} -gt 0 ]] && sleep ${TIMEOUT} && msg_box_clear ${TAG} # Display MSG for limited time
	[[ ${SO} == 'true' ]] && tput rmso # Kill standout

	# Restore display
	tput rc # Restore cursor position
	tput cup ${_MAX_ROWS} ${_MAX_COLS} # Drop cursor to bottom right corner
}

msg_box_align () {
	local TAG=${1};shift
	local MSG=${@}
	local -A BOX_COORDS=($(box_coords_get ${TAG}))
	local BOX_WIDTH=${BOX_COORDS[W]}
	local BOX_STYLE=${BOX_COORDS[S]}
	local TEXT_PAD_L=''
	local TEXT_PAD_R=''
	local MSG_OUT=''
	local OFFSET=3
	local PADDED=''
	local TEXT=''
	local LBL=''
	local VAL=''

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO} TAG:${TAG} COORDS:${BOX_COORDS} MSG LEN:${#MSG}"

	if [[ ${MSG} =~ '<Z>' ]];then # Handle embed:<Z> Blank line
		MSG=" "
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Added blank line"
	elif [[ ${MSG} =~ '<SEP>' ]];then # Handle embed:<SEP> Message separator
		MSG=$(str_unicode_line $(( BOX_WIDTH-4 )) )
		TEXT_PAD_L=$(str_center_pad $(( BOX_WIDTH+1 )) ${MSG} )
		TEXT_PAD_R=$(str_rep_char ' ' $(( ${#TEXT_PAD_L} - 1 )) )
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Added heading separator: SEP:${MSG} BOX_WIDTH:${BOX_WIDTH} TEXT_PAD_L:\"${TEXT_PAD_L}\" TEXT_PAD_R:\"${TEXT_PAD_R}\""
	elif [[ ${MSG} =~ '<L>' ]];then # Handle embed: <L> Bullet List item
		MSG=$(sed -e 's/^.*<L>/\\u2022 /' <<<${MSG}) # Swap marker with bullet and space
		TEXT=$(msg_nomarkup ${MSG})
		TEXT=$(str_trim ${TEXT})
		TEXT_PAD_L=' '
		TEXT_PAD_R=$(str_rep_char ' ' $(( BOX_WIDTH - ( ${#TEXT_PAD_L}+${#TEXT} ) - OFFSET -1 ))) # compensate for bullet/space
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: List item bullets"
	elif [[ ${MSG} =~ '<X>' ]];then # Handle embed: <X> Numbered List item
		MSG=$(sed -e 's/^.*<X>//' <<<${MSG})
		TEXT=$(msg_nomarkup ${MSG})
		TEXT=$(str_trim ${TEXT})
		TEXT_PAD_L=' '
		TEXT_PAD_R=$(str_rep_char ' ' $(( BOX_WIDTH - ( ${#TEXT_PAD_L}+${#TEXT} ) - OFFSET -1 ))) # compensate for number/space
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: List item numbers"
	elif [[ ${MSG} =~ '<D>' ]];then # Handle embed: <D> Data Field List item
		MSG=$(sed -e 's/^.*<D>//' <<<${MSG})
		LBL=$(cut -d':' -f1 <<<${MSG})
		LBL=${LBL:gs/#/ /} # Swap alignment placeholders w/spaces
		VAL=$(cut -d':' -f2 <<<${MSG})
		MSG="<c>${LBL}<N>:<w>${VAL}<N>" # Colorize
		TEXT=$(msg_nomarkup ${MSG})
		TEXT_PAD_L=' '
		TEXT_PAD_R=$(str_rep_char ' ' $(( BOX_WIDTH - (${#TEXT_PAD_L}+${#TEXT}) - OFFSET )) )
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Data item"
	elif [[ ${BOX_STYLE:l} == 'l' ]];then # Justification: Left
		TEXT=$(msg_nomarkup ${MSG})
		TEXT=$(str_trim ${TEXT})
		TEXT_PAD_L=' '
		TEXT_PAD_R=$(str_rep_char ' ' $(( BOX_WIDTH - (${#TEXT_PAD_L}+${#TEXT}) - OFFSET )) )
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Left justifed text"
	elif [[ ${BOX_STYLE:l} == 'c' ]];then # Justification: Center
		TEXT=$(msg_nomarkup ${MSG})
		TEXT=$(str_trim ${TEXT})
		TEXT_PAD_L=$(str_center_pad $(( BOX_WIDTH-2 )) $(msg_nomarkup ${TEXT} ))
		TEXT_PAD_R=$(str_rep_char ' ' $(( ${#TEXT_PAD_L}-1 )) )
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Centered text"
	else # Unpadded
		TEXT=$(msg_nomarkup ${MSG})
		TEXT=$(str_trim ${TEXT})
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: UNPADDED text"
	fi

	MSG_OUT=$(msg_markup ${MSG}) # Apply markup
	PADDED="${TEXT_PAD_L}${MSG_OUT}${TEXT_PAD_R}"

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: PADDING: |${PADDED}|"

	echo ${PADDED}
}

msg_box_clear () {
	local TAG=${1}
	local -A BOX_COORDS=()
	local X_COORD_ARG=''
	local Y_COORD_ARG=''
	local H_COORD_ARG=''
	local W_COORD_ARG=''
	local X

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO} PARAMS:${#} TAG:${TAG}"

	# Process arguments
	if [[ ${#} -eq 1 ]];then
		TAG=${1}
		BOX_COORDS=($(box_coords_get ${TAG})) # Tag passed
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TAG:${TAG} BOX_COORDS:${(kv)BOX_COORDS}"
		[[ -z ${BOX_COORDS} ]] && return 1
	elif [[ ${#} -eq 4 ]];then
		BOX_COORDS=($(box_coords_get ${_LAST_MSG_TAG})) # overrides passed - apply to last msg
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TAG:${TAG} BOX_COORDS:${(kv)BOX_COORDS}"
		[[ -z ${BOX_COORDS} ]] && return 1

		X_COORD_ARG=${1}
		Y_COORD_ARG=${2}
		H_COORD_ARG=${3}
		W_COORD_ARG=${4}

		# Handle any overrides
		[[ ${X_COORD_ARG} != 'X' ]] && BOX_COORDS[X]=${X_COORD_ARG}
		[[ ${Y_COORD_ARG} != 'Y' ]] && BOX_COORDS[Y]=${Y_COORD_ARG}
		[[ ${H_COORD_ARG} != 'H' ]] && BOX_COORDS[H]=${H_COORD_ARG}
		[[ ${W_COORD_ARG} != 'W' ]] && BOX_COORDS[W]=${W_COORD_ARG}
	else
		BOX_COORDS=($(box_coords_get ${_LAST_MSG_TAG})) # No args passed - use last msg
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TAG:${TAG} BOX_COORDS:${(kv)BOX_COORDS}"
		[[ -z ${BOX_COORDS} ]] && return 1
	fi

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Starting on ROW ${BOX_COORDS[X]:=null} and clearing from COL ${BOX_COORDS[Y]:=null} for ${BOX_COORDS[W]:=null} COLS for ${BOX_COORDS[H]:=null} LINES"

	for (( X=${BOX_COORDS[X]}; X <= ( ${BOX_COORDS[X]} + ${BOX_COORDS[H]} - 1 ); X++));do
		tput cup ${X} ${BOX_COORDS[Y]}
		tput ech ${BOX_COORDS[W]}
	done

	[[ ${_REPAINT} == 'true' ]] && box_coords_repaint ${TAG}

	_REPAINT=true # Reset until subsequent override

	return 0
}

msg_box_ebox_coords () {
	local X=${1}
	local Y=${2}
	local W=${3}
	local HEADER=${4}

	echo $(( X+${HEADER} + 2 )) $(( Y+W/2 ))
}

msg_box_parse () {
	local MAX_WIDTH=${1};shift
	local MSGS_IN=${@}
	local -a MSGS_OUT=()
	local DELIM_COUNT=0
	local MSG=''
	local K L T 

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	[[ -n ${MSGS_IN} ]] && dbg "${0}: Incoming messages:\n>>>\n$(for M in ${MSGS_IN};do echo ${M};done)\n<<<\n"

	MSGS_IN=$(tr -d "\n" <<<${MSGS_IN}) # Convert to string - setup for cut
	MSGS_IN=$(sed -E "s/[\\\][${_DELIM}]/_DELIM_/g" <<<${MSGS_IN}) # Skip any escaped delimiters

	DELIM_COUNT=$(grep --color=never -o "[${_DELIM}]" <<<${MSGS_IN} | wc -l) # Slice MSG into fields and count

	# Extract item by delim and fold any lines that exceed display
	for (( X=1; X <= $((${DELIM_COUNT}+1 )); X++ ));do
		[[ ${DELIM_COUNT} -ne 0 ]] && MSG=$(cut -d"${_DELIM}" -f${X} <<<${MSGS_IN}) || MSG=${MSGS_IN}
	 	MSG=$(sed "s/_DELIM_/${_DELIM}/g" <<<${MSG}) # Restore escaped delimiters
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

	[[ -n ${MSGS_OUT} ]] && dbg "${0}: Outgoing messages:\n>>>\n$(for M in ${MSGS_OUT};do echo ${M};done)\n<<<\n"

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
	local NEED

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ARGS: MSG_ROWS:${MSG_ROWS},DISP_ROWS:${DISP_ROWS}"

	TL_PAGES=$(( MSG_ROWS / DISP_ROWS ))
	PARTIAL=$(( MSG_ROWS % DISP_ROWS ))

	[[ ${PARTIAL} -ne 0 ]] && (( TL_PAGES++))
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: TL_PAGES:${TL_PAGES}, PARTIAL:${PARTIAL}"

	GAP=$(( (TL_PAGES * DISP_ROWS) - MSG_ROWS ))
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: GAP:${GAP}"

	echo ${GAP}
}

msg_err () {
	local MSG=${@}
	local LABEL='Error'

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -z ${MSG} ]] && return

	grep -q '|' <<<${MSG}
	[[ ${?} -eq 0 ]] && LABEL=$(cut -d '|' -f1 <<<${MSG}) && MSG=$(cut -d '|' -f2 <<<${MSG})

	if [[ -n ${MSG} ]];then
		[[ ${MSG} =~ ":" ]] && MSG=$(perl -p -e 's/:(.*)\s/\e[m:\e[3;37m$1\e[m /g' <<<${MSG})
		printf "[${WHITE_FG}%s${RESET}]:[${BOLD}${RED_FG}${LABEL}${RESET}] %s" ${_SCRIPT} "${MSG}"
	fi
}

msg_exit () {
	local LEVEL=${1}
	local MSG=${2}
	local LABEL=''
	local LCOLOR=''

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -z ${@} ]] && return

	case ${LEVEL} in 
		W) LABEL="Warning";LCOLOR=${ITALIC}${BOLD}${MAGENTA_FG};;
		E) LABEL="Error";LCOLOR=${ITALIC}${BOLD}${RED_FG};;
		I) LABEL="Info";LCOLOR=${ITALIC}${CYAN_FG};;
		*) LABEL="Error";LCOLOR=${ITALIC}${BOLD}${RED_FG};;
	esac

	if [[ -n ${MSG} ]];then
		[[ ${MSG} =~ ":" ]] && MSG=$(perl -p -e 's/:(\w+\.?\w+)(.*$)/\e[m:\e[3;37m$1\e[m\2/' <<<${MSG})
		printf "[${WHITE_FG}%s${RESET}]:[${LCOLOR}${LABEL}${RESET}] %s" ${_SCRIPT} "${MSG}"
	fi
}

msg_info () {
	local MSG=${@}
	local LABEL='Info'

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -z ${MSG} ]] && return

	grep -q '|' <<<${MSG}
	[[ ${?} -eq 0 ]] && LABEL=$(cut -d '|' -f1 <<<${MSG}) && MSG=$(cut -d '|' -f2 <<<${MSG})

	if [[ -n ${MSG} ]];then
		#[[ ${MSG} =~ ":" ]] && MSG=$(perl -p -e 's/:([[:print:]]+?\s)(\w+.*)?$/\e[m:\e[3;37m$1\e[m\2/' <<<${MSG})
		[[ ${MSG} =~ ":" ]] && MSG=$(perl -p -e 's/:(.*)\s/\e[m:\e[3;37m$1\e[m /g' <<<${MSG})
		printf "[${WHITE_FG}%s${RESET}]:[${BOLD}${CYAN_FG}${LABEL}${RESET}] %s" ${_SCRIPT} "${MSG}"
	fi
}

msg_line_weight () {
	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	_BOX_LINE_WEIGHT=${1}
}

msg_list_bullet () {
	local -a MSG=(${@})
	local L
	local DELIM='|'
	local NDX=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: MSG COUNT:${#MSG}"

	for L in ${MSG};do
		(( NDX++))
		echo -n "<L>${L}"
		[[ ${NDX} -lt ${#MSG} ]] && echo ${DELIM}
	done

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Generated ${NDX} lines"
}

msg_list_number () {
	local -a MSG=(${@})
	local L
	local DELIM='|'
	local NDX=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: MSG COUNT:${#MSG}"

	for L in ${MSG};do
		(( NDX++))
		echo -n "<X>${NDX}) ${L}"
		[[ ${NDX} -lt ${#MSG} ]] && echo ${DELIM}
	done

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Generated ${NDX} lines"
}

msg_list_data () {
	local -a MSG=(${@})
	local L
	local DELIM='|'
	local NDX=0
	local LINE=''
	local MAX=0
	local MARK=0
	local PAD=0
	local LBL
	local VAL

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: MSG COUNT:${#MSG}"

	MAX=0

	for K in ${MSG};do
		NDX=${K[(i)[:]]} # Find separator
		[[ ${NDX} -gt ${MAX} ]] && MAX=${NDX}
	done

	NDX=0
	for K in ${MSG};do
		((NDX++))
		MARK=${K[(i)[:]]}
		[[ ${MARK} -lt ${MAX} ]] && PAD=$((MAX - MARK)) || PAD=0 # Align fields at separator
		PAD=$((PAD+${#K}))
		VAL=$(cut -d':' -f2 <<<${K})
		LINE="<D> ${(l(${PAD})(#))K}:${VAL}"
		[[ ${NDX} -lt ${#MSG} ]] && echo -n ${LINE}${DELIM} || echo -n ${LINE}
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ITEM:${LINE}"
	done

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Generated ${NDX} lines"
}

msg_markup () {
	local MSG=${@}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	# Apply markup
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
	"g"=>"[32m",
	"h"=>"[0m\e[0;1;37;100m",
	"m"=>"[35m",
	"r"=>"[31m",
	"u"=>"[4m",
	"w"=>"[37m",
	"y"=>"[33m"
	) }; 
	{ s/<([BINORSUrughybmcw])>/\e$ES{$1}/g; }' <<<${MSG}
}

msg_nomarkup () {
	local MSG=${@}
	local MSG_OUT

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"

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

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"

	TL_PAGES=$(( LIST_ROWS / PG_LINES ))
	PARTIAL=$(( LIST_ROWS % PG_LINES ))
	[[ ${PARTIAL} -ne 0 ]] && (( TL_PAGES++))
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: TL_PAGES:${TL_PAGES}, PARTIAL:${PARTIAL}"

	TOP=0
	BOT=$(( (TL_PAGES-1) * PG_LINES ))
	PGUP=$(( NDX - (PG_LINES*2) )); [[ ${PGUP} -lt 1 ]] && PGUP=0
	PGDN=${NDX}

	if [[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]];then
		dbg "${0}: TOP RETURNS:${TOP}"
		dbg "${0}: BOT RETURNS:${BOT}"
		dbg "${0}: PGUP RETURNS:${PGUP}"
		dbg "${0}: PGDN RETURNS:${PGDN}"
	fi

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

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"

	case ${KEY} in
		j|d|n) [[ ${PG_INIT} == 'false' ]] && (( PAGE++));;
		k|u|p) [[ ${PAGE} -gt 1 ]] && (( PAGE--));;
	esac

	echo ${PAGE}
}

msg_proc () {
	local BOX_W=20
	local BOX_H=3
	local H_POS=$(coord_center $(( _MAX_COLS - 3 )) BOX_W) # Horiz center
	local V_POS=$(( _MAX_ROWS/2 - BOX_H ))
	local X R C

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"

	msg_unicode_box ${V_POS} ${H_POS} ${BOX_W} ${BOX_H}
	tput cup $(( V_POS+1 )) $(( H_POS+2 ));echo -n "${GREEN_FG}Processing...${RESET}"
	TAG=${_PROC_BOX_TAG}
	box_coords_set ${TAG} X ${V_POS} Y ${H_POS} W ${BOX_W} H ${BOX_H}
	_PROC_MSG=false

	sleep .5

	R=${V_POS}
	C=${H_POS}
	for (( X=${V_POS}; X<BOX_H+V_POS; X++ ));do
		tput cup ${R} ${C} 
		tput ech ${BOX_W}
		((R++))
	done
}

msg_stream () {
	local -a CMD
	local -a MSG_LINES
	local DELIM='|'
	local STYLE=l
	local FOLD_WIDTH=110
	local FOLD
	local MSG
	local LINE_CNT
	local PAD
	local NDX

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
	shift $(( OPTIND -1 ))

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	FOLD="| fold -s -w ${FOLD_WIDTH}"

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: OPTIONS:FOLD:${FOLD} STYLE:${STYLE}"

	CMD=(${@})
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CMD:${CMD}"

	# Convert carriage returns to newlines, kill excess spaces, any '<' to unicode, '|' to 'or' and trim, and fold
	coproc { eval ${CMD} | \
		sed -e 's// /g'  \
		-e 's/  */ /g'  \
		-e 's/</\xe2\x98\x87/g'  \
		-e 's/|/or/g'  \
		-e 's/^[[:blank:]]*//;s/[[:blank:]]*$//' | \
		fold -s -w ${FOLD_WIDTH}  \
	}

	LINE_CNT=0
	while read -p ${COPROC[0]} MSG;do
		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: COPROC READ MSG:${LINE_CNT}: [${MSG}] $(xxd <<<${MSG})"
		MSG_LINES+="<w>${MSG}<N>${DELIM}"
		(( LINE_CNT++))
	done
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: TOTAL MSGS FROM COPROC:${LINE_CNT}"

	while true;do
		[[ ${MSG_LINES[-1]} == "<w><N>|" ]] && MSG_LINES[-1]=() || break
	done

	MSG_LINES[-1]=$(sed 's/|//g' <<< ${MSG_LINES[-1]}) # Remove DELIM on prompt

	[[ -z ${#MSG_LINES[1]} || ${MSG_LINES[1]:l} =~ 'unable to locate' ]] && return
	
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: MSG COUNT with BLANK LINES REMOVED:${#MSG_LINES}"

	msg_box -y20 -w$(( FOLD_WIDTH+4 )) -P"<m>Last Page<N>" -pc -s${DELIM} -j${STYLE} ${MSG_LINES} # Display window
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

	[[ $(( BOX_WIDTH - 2 )) -gt 0 ]] && BOX_WIDTH=$(( BOX_WIDTH - 2 )) # Dont go negative
	[[ $(( BOX_HEIGHT - 2 )) -gt 0 ]] && BOX_HEIGHT=$(( BOX_HEIGHT - 2 )) # Dont go negative

	L_SPAN=$(( BOX_Y_COORD+1 ))
	R_SPAN=$(( BOX_Y_COORD+BOX_WIDTH ))
	T_SPAN=$(( BOX_X_COORD+1 ))
	B_SPAN=$(( BOX_X_COORD+BOX_HEIGHT ))

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

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

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TOP LEFT: BOX_X_COORD:${BOX_X_COORD} BOX_Y_COORD:${BOX_Y_COORD}"

	# Reset standout (if set)
	tput rmso

	# Color
	echo -n ${BOX_COLOR}

	# Top left corner
	tput cup ${BOX_X_COORD} ${BOX_Y_COORD}
	printf ${TOP_LEFT}

	# Top border
	for (( Y=${L_SPAN}; Y<=${R_SPAN}; Y++ ));do
		tput cup ${BOX_X_COORD} ${Y}
		printf ${HORIZ_BAR}
	done

	# Top right corner
	printf ${TOP_RIGHT}

	# Sides
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: BOX_WIDTH:${BOX_WIDTH}"
	for (( X=${T_SPAN}; X<=${B_SPAN}; X++ ));do
		tput cup ${X} ${BOX_Y_COORD}
		printf ${VERT_BAR}
		tput ech ${BOX_WIDTH} # Clear box area
		tput cup ${X} $(( R_SPAN + 1 ))
		printf ${VERT_BAR}
	done

	# Bottom left corner
	tput cup ${X} ${BOX_Y_COORD}
	printf ${BOT_LEFT}

	# Bottom border
	for (( Y=${L_SPAN}; Y<=${R_SPAN}; Y++ ));do
		tput cup ${X} ${Y}
		printf ${HORIZ_BAR}
	done

	# Bottom right corner
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: BOX_HEIGHT:${BOX_HEIGHT}"
	tput cup ${X} ${Y}
	printf ${BOT_RIGHT}

	echo -n ${RESET}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: BOTTOM RIGHT: BOX_X_COORD:${X} BOX_Y_COORD:${Y}"
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: BOX DIMENSIONS:$(( X-BOX_X_COORD+1 )) x $(( Y-BOX_Y_COORD+1 ))"
}

msg_warn () {
	local MSG=${@}
	local LABEL='Warning'

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	grep -q '|' <<<${MSG}
	[[ ${?} -eq 0 ]] && LABEL=$(cut -d '|' -f1 <<<${MSG}) && MSG=$(cut -d '|' -f2 <<<${MSG})

	if [[ -n ${MSG} ]];then
		[[ ${MSG} =~ ":" ]] && MSG=$(perl -p -e 's/:(.*)/\e[m:\e[3;37m$1\e[m/g' <<<${MSG})
		printf "[${WHITE_FG}%s${RESET}]:[${RED_FG}${LABEL}${RESET}] %s" ${_SCRIPT} "${MSG}"
	fi
}

