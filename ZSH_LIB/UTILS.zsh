# LIB Dependencies
_DEPS_+="DBG.zsh MSG.zsh TPUT.zsh"

# LIB Declarations
typeset -a _DELIMS=('#' '|' ':' ',' '	') # Recognized field delimiters
typeset -a _POS_ARGS=()
typeset -A _KWD_ARGS=()

# LIB Vars
_EXIT_VALUE=0
_FUNC_TRAP=false
_BAREWORD_IS_FILE=false
_BOX_TAG="/tmp/$$.box_tag"

arg_parse () {
	local KWD=false
	local A
	local NDX
	local KEY

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	NDX=0
	for A in ${@};do
		if [[ ${KWD} == 'true' ]];then
			_KWD_ARGS[${KEY}]=${A}
			KWD=false
			continue
		fi
		if [[ ${A} =~ ^(-|--) ]];then
			KEY=$(sed -e 's/^-*//' <<<${A})
			KWD=true
			continue
		fi
		((NDX++))
		_POS_ARGS[${NDX}]=${A}
	done
}

assoc_del_key () {
	emulate -LR zsh
	setopt extended_glob

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if [[ -${(Pt)1}- != *-association-* ]]; then
		return 120 # Fail early if $1 is not the name of an associative array
	fi

	set -- "$1" "${(j:|:)${(@b)@[2,$#]}}"

	# Copy all entries except the specified ones
	: "${(AAP)1::=${(@kv)${(P)1}[(I)^($~2)]}}"
}

boolean_color () {
	local STATE=${1}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	case ${STATE} in
		0) echo ${GREEN_FG};;
		active) echo -n ${GREEN_FG};;
		connected) echo -n ${GREEN_FG};;
		current) echo -n ${GREEN_FG};;
		stale) echo -n ${RED_FG};;
		on) echo -n ${GREEN_FG};;
		pass) echo -n ${GREEN_FG};;
		running) echo -n ${GREEN_FG};;
		true) echo -n ${GREEN_FG};;
		valid) echo -n ${GREEN_FG};;
		*) echo -n ${RED_FG};;
	esac
}

boolean_color_word () {
	local STATE=${1}
	local ANSI_ECHO=false

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${#} -eq 2 ]] && ANSI_ECHO=true
	
	case ${STATE} in
		0) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${GREEN_FG}true${RESET}" || echo -n "${E_GREEN_FG}true${E_RESET}";;
		1) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${RED_FG}false${RESET}" || echo -n "${E_RED_FG}false${E_RESET}";;
		active) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${GREEN_FG}${STATE}${RESET}" || echo -n "${E_GREEN_FG}${STATE}${E_RESET}";;
		current) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${GREEN_FG}${STATE}${RESET}" || echo -n "${E_GREEN_FG}${STATE}${E_RESET}";;
		stale) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${RED_FG}${STATE}${RESET}" || echo -n "${E_RED_FG}${STATE}${E_RESET}";;
		fail) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${RED_FG}${STATE}${RESET}" || echo -n "${E_RED_FG}${STATE}${E_RESET}";;
		pass) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${GREEN_FG}${STATE}${RESET}" || echo -n "${E_GREEN_FG}${STATE}${E_RESET}";;
		true) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${GREEN_FG}${STATE}${RESET}" || echo -n "${E_GREEN_FG}${STATE}${E_RESET}";;
		valid) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${GREEN_FG}${STATE}${RESET}" || echo -n "${E_GREEN_FG}${STATE}${E_RESET}";;
		*) [[ ${ANSI_ECHO} == "false" ]] && echo -n "${RED_FG}${STATE}${RESET}" || echo -n "${E_RED_FG}${STATE}${E_RESET}";;
	esac
}

box_coords_del () {
	local TAG=${1}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TAG:${TAG}"

	assoc_del_key _BOX_COORDS ${TAG}
}

box_coords_dump () {
	local K

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo "\n--- COORDS ---"
	for K in ${(k)_BOX_COORDS};do
		printf "${WHITE_FG}TAG${RESET}:%s ${WHITE_FG}COORDS${RESET}:%s\n" ${K} ${_BOX_COORDS[${K}]}
	done
	echo "--- End COORDS ---"
}

box_coords_get () {
	local TAG=${1}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TAG:${TAG}"

	[[ -z ${_BOX_COORDS[${TAG}]} ]] && return 1

	echo ${(kv)_BOX_COORDS[${TAG}]}
}

box_coords_overlap () {
	local TAG_1=${1}
	local TAG_2=${2}

	local -A BOX_1_COORDS=($(box_coords_get ${TAG_1}))
	local -A BOX_2_COORDS=($(box_coords_get ${TAG_2}))

	local X1_MIN=${BOX_1_COORDS[X]}
	local X1_MAX=$(( BOX_1_COORDS[X] + BOX_1_COORDS[H] - 1 )) # Add the height
	local Y1_MIN=${BOX_1_COORDS[Y]}
	local Y1_MAX=$(( BOX_1_COORDS[Y] + BOX_1_COORDS[W] - 1 )) # Add the width

	local X2_MIN=${BOX_2_COORDS[X]}
	local X2_MAX=$(( BOX_2_COORDS[X] + BOX_2_COORDS[H] - 1 )) # Add the height
	local Y2_MIN=${BOX_2_COORDS[Y]}
	local Y2_MAX=$(( BOX_2_COORDS[Y] + BOX_2_COORDS[W] - 1 )) # Add the width

	# isOverlapping = (x1min < x2max) && (x2min < x1max) && (y1min < y2max) && (y2min < y1max)
	
	local OVERLAP=1

	[[ ${X1_MIN} -lt ${X2_MAX} && ${X2_MIN} -lt ${X1_MAX} && ${Y1_MIN} -lt ${Y2_MAX} && ${Y2_MIN} -lt ${Y1_MAX} ]] && OVERLAP=0

	return ${OVERLAP} # Return true - is overlap
}

box_coords_relative () {
	local BASE_TAG=${1};shift
	local -A OFFSETS=(${@})
	local -A BASE_COORDS=()

	# OFFSETS are in the form [+-]INT or INT

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	BASE_COORDS=($(box_coords_get ${BASE_TAG}))
	[[ -z ${BASE_COORDS} ]] && return 1

	if [[ -n ${OFFSETS[X]} ]];then
		[[ ${OFFSETS[X]} =~ '[+-]' ]] && BASE_COORDS[X]=$(( ${BASE_COORDS[X]}${OFFSETS[X]} )) || BASE_COORDS[X]=${OFFSETS[X]}
	fi
	if [[ -n ${OFFSETS[Y]} ]];then
		[[ ${OFFSETS[Y]} =~ '[+-]' ]] && BASE_COORDS[Y]=$(( ${BASE_COORDS[Y]}${OFFSETS[Y]} )) || BASE_COORDS[Y]=${OFFSETS[Y]}
	fi
	if [[ -n ${OFFSETS[W]} ]];then
		[[ ${OFFSETS[W]} =~ '[+-]' ]] && BASE_COORDS[W]=$(( ${BASE_COORDS[W]}${OFFSETS[W]} )) || BASE_COORDS[W]=${OFFSETS[W]}
	fi
	if [[ -n ${OFFSETS[H]} ]];then
		[[ ${OFFSETS[H]} =~ '[+-]' ]] && BASE_COORDS[H]=$(( ${BASE_COORDS[H]}${OFFSETS[H]} )) || BASE_COORDS[H]=${OFFSETS[H]}
	fi

	echo ${(kv)BASE_COORDS}
}

box_coords_repaint () {
	local TAG=${1}
	local -A COORDS=($(box_coords_get ${TAG}))
	local LIST_ROW=0
	local LNDX=0
	local ROW_LIMIT=0
	local SNDX=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -z ${_SCREEN} ]] && return # Screen cache is empty

	if [[ -z ${TAG} && -e ${LAST_COORDS} ]];then
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: No TAG, getting LAST_COORDS TAG"
		read TAG < ${LAST_COORDS}
		/bin/rm -f ${LAST_COORDS}
		if [[ -n ${TAG} ]];then
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Got LAST_COORDS TAG:${TAG}"
			COORDS=($(box_coords_get ${TAG}))
		fi
	fi

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: TAG:${TAG} COORDS:${(kv)COORDS}"

	LIST_ROW=$(( COORDS[X] - _LIST_HEADER_LINES + 1 ))
	ROW_LIMIT=$(( LIST_ROW + COORDS[H] - 1 ))

	for (( LNDX=LIST_ROW; LNDX <= ROW_LIMIT; LNDX++ ));do
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _SCREEN[LNDX]: ${_SCREEN[${LNDX}]}"
		[[ -n ${_SCREEN[${LNDX}]} ]] && tput cup $(( COORDS[X] + SNDX )) 0 && echo -n ${_SCREEN[${LNDX}]}
		((SNDX++))
	done
}

box_coords_set () {
	local -a ARGS=(${@})
	local TAG=${ARGS[1]}
	local COORDS=${ARGS[2,-1]}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TAG:${TAG}"

	_BOX_COORDS[${TAG}]="${COORDS}"

	echo ${TAG} > ${_BOX_TAG}
}

box_coords_upd () {
	local -a ARGS=(${@})
	local TAG=${ARGS[1]}
	local -A UPD=(${ARGS[2,-1]})
	local -A ORIG=($(box_coords_get ${TAG}))
	local K V

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for K in ${(k)UPD};do
		ORIG[${K}]=${UPD[${K}]}
	done

	box_coords_set ${TAG} ${(kv)ORIG}
}

center_wdw () {
	local WIN_NAME=${1}
	local WIN_PXH=${2}
	local WIN_PXW=${3}
	local DIMS=$(xdpyinfo | grep dimension | perl -pe 's/^(.*:\s+)(.*)( pix.*$)/$2/g')
	local RES_W=$(cut -d'x' -f1 <<<${DIMS})
	local RES_H=$(cut -d'x' -f2 <<<${DIMS})
	local NDX WID WIN_W WIN_H PX PY
	local -a WIDS=()
	local MAX_IDS=3 # Testing shows as many as 3 id's generated per execution
	local X

	logit ${LOG} "${0}:${LINENO} DIMS:${DIMS}"
	logit ${LOG} "${0}:${LINENO} RES_W:${RES_W} RES_H:${RES_H}"

	for (( X=0; X<10; X++ ));do
		[[ ${#WIDS} -eq ${MAX_IDS} ]] && break
		WIDS=("${(f)$(xdotool search --name ${WIN_NAME})}")
		sleep .5
	done

	WID=${WIDS[${#WIDS}]} # Most recent id
	[[ -z ${WID} ]] && echo "${0}:${RED_FG}Unable to locate window${RESET}:${WHITE_FG}${WIN_NAME}${RESET}" && return 1
	logit ${LOG} "${0}:${LINENO} Got WID:${WID}"

	logit ${LOG} "${0}:${LINENO} Calling: xdotool windowsize ${WID} ${WIN_PXH} ${WIN_PXW}"
	xdotool windowsize ${WID} ${WIN_PXH} ${WIN_PXW}

	logit ${LOG} "${0}:${LINENO} Calling: xdotool getwindowgeometry --shell ${WID}"
	WIN_W=$(xdotool getwindowgeometry --shell ${WID} | head -4 | tail -1 | sed 's/[^0-9]*//')
	WIN_H=$(xdotool getwindowgeometry --shell ${WID} | head -5 | tail -1 | sed 's/[^0-9]*//')

	PX=$(( RES_W / 2 - WIN_W / 2 ))
	PY=$(( RES_H / 2 - WIN_H / 2 ))

	logit ${LOG} "${0}:${LINENO} Calling: xdotool windowmove ${WID} $PX $PY"
	xdotool windowmove ${WID} $PX $PY
}

cmd_get_raw () {
	local CMD_LINE

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	fc -R
	CMD_LINE=("${(f)$(fc -lnr | head -1)}") # Parse raw cmdline
	echo ${CMD_LINE}
}

format_pct () {
	local ARG=${1}
	local -F1 P1
	local -F2 P2
	local -F3 P3
	local -F4 P4
	local -F5 P5
	local -F6 P6
	local -F7 P7
	local -F8 P8
	local PCT

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	# Decrease decimal places based on intensity
	P8=${ARG}
	PCT=${P8}

	if [[ ${P8} -ge .1 ]];then
		P1=${P8} && PCT=${P1}
	elif [[ ${P8} -ge .01 ]];then
		P2=${P8} && PCT=${P2}
	elif [[ ${P8} -ge .001 ]];then
		P3=${P8} && PCT=${P3}
	elif [[ ${P8} -ge .0001 ]];then
		P4=${P8} && PCT=${P4}
	elif [[ ${P8} -ge .00001 ]];then
		P5=${P8} && PCT=${P5}
	elif [[ ${P8} -ge .000001 ]];then
		P6=${P8} && PCT=${P6}
	elif [[ ${P8} -ge .0000001 ]];then
		P7=${P8} && PCT=${P7}
	else
		PCT=0
	fi

	echo ${PCT}
}

func_delete () {
	local FUNC=${1}
	local FN=${2}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	sed -i "/${FUNC}.*() {/,/^}/d" ${FN}
}

func_list () {
	local FN=${1}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	grep --color=never -P "^\S.*() {\s*$" < ${FN} | cut -d'(' -f1 | sed -e 's/^[[:space:]]*//'
}

func_normalize () {
	local FN=${1}
	local NEXT_PASS=''

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	perl -pe 's/^(function\s+)(.*) (\{.*)/${2} () ${3}/g' < ${FN} > ${FN}_.pass_1

	perl -pe 's/([a-z])(\(\))/${1} ${2}/g' < ${FN}_.pass_1 > ${FN}_.pass_2

	perl -pe 's/\(\) \(\)/\(\)/g' < ${FN}_.pass_2 > ${FN}_.pass_3

	perl -pe 's/(^})(.*)/${1}/g' < ${FN}_.pass_3 > ${FN}.normalized
}

func_print () {
	local FN=${1}
	local FUNC=$(str_trim ${2})
	
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	perl -ne "print if /^${FUNC}\s+\(\) {/ .. /^}$/" ${FN} | perl -pe 's/^}$/}\n/g'
	#perl -ne "print if /^${FUNC}\s+\(\) {/ .. /^}$/" ${FN}
}

get_delim_field_cnt () {
	local DELIM_ROW=${@}
	local FCNT=0
	local DELIM=$(parse_find_valid_delim ${DELIM_ROW})

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if [[ -n ${DELIM} ]];then
		FCNT=$(echo ${DELIM_ROW} | grep -o ${DELIM} | wc -l)
		((FCNT++))
		echo ${FCNT}
		return 0
	else
		return 1
	fi
}

get_keys () {
	local PROMPT=${@}
	local -a NUM
	local IDLE_TIME=0
	local K1=''
	local K2=''
	local K3=''
	local KEY=''
	local MY_PPID=${PPID}
	local RESP=?;
	local XSET_RATE=''

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	(tcup $(( _MAX_ROWS - 2 )) 0;printf "${PROMPT}")>&2 # Position cursor and display prompt to STDERR

	trap reset_rate INT

	while true;do
		if [[ ${IDLE_TIME} -le 1000 ]];then
			if [[ ${XSET_RATE} != ${_XSET_MENU_RATE} ]];then
				eval "xset ${_XSET_MENU_RATE}" # Keyboard Active
				XSET_RATE="${_XSET_MENU_RATE}"
			fi
		else
			if [[ ${XSET_RATE} != ${_XSET_DEFAULT_RATE} ]];then
				eval "xset ${_XSET_DEFAULT_RATE}" # Keyboard Inactive
				XSET_RATE="${_XSET_DEFAULT_RATE}"
			fi
		fi

		KEY=''; K1=''; K2=''; K3=''

		while read -t1 -sk1 KEY;do
			# Slurp input buffer
			read -sk1 -t 0.0001 K1 >/dev/null 2>&1
			read -sk1 -t 0.0001 K2 >/dev/null 2>&1
			read -sk1 -t 0.0001 K3 >/dev/null 2>&1
			KEY+=${K1}${K2}${K3}

			case "${KEY}" in 
				$'\x0A') RESP=0;; # Return
				$'\e[A') RESP=1;; # Up
				$'\e[B') RESP=2;; # Down
				$'\e[D') RESP=3;; # Left
				$'\e[C') RESP=4;; # Right
				$'\e[5~') RESP=5;; # PgUp
				$'\e[6~') RESP=6;; # PgDn
				$'\e[H') RESP=7;; # Home
				$'\e[F') RESP=8;; # End
				$'\x7F') if [[ ${#NUM} -gt 0 ]];then # BackSpace
								NUM[${#NUM}]=()
								echo -n " ">&2
							fi;;
				*) RESP=$(printf '%d' "'${KEY}");; # Ascii letter value
			esac

			if [[ ${RESP} != "?" ]];then
				if [[ -z ${NUM} ]];then
					case ${RESP} in
						<48-57>) RESP=${KEY};; # Numeric
						<65-122>) RESP=${KEY};; # Alpha
					esac
					echo ${RESP}
				else
					echo "K${(j::)NUM}"
				fi
				if [[ -n ${KEY} ]];then
					eval "xset ${_XSET_DEFAULT_RATE}" # Restore default rate
					break 2
				else
					continue
				fi
			fi
		done
		IDLE_TIME=$(xprintidle)
	done
	trap - INT # key processed; cancel trap
}

inline_vi_edit () {

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	cursor_on

	# Requires xdotool
	
	local PERL_SCRIPT

	read -r -d '' PERL_SCRIPT <<'___EOF'
	use warnings;
	use strict;
	use Term::ReadLine;

	my $term = new Term::ReadLine 'list_search';
	$term->parse_and_bind("set editing-mode vi");

	system('xdotool key Home End &');
	
	while ( defined ($_ = $term->readline($ARGV[0],$ARGV[1])) ) {
		print $_;
		exit;
	}
___EOF

	perl -e "$PERL_SCRIPT" ${PROMPT} ${CUR_VALUE}

	cursor_off
}

is_bare_word () {
	local TEXT="${@}"

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${TEXT} =~ '\*' || ${TEXT} =~ '\~' || ${TEXT} =~ '^/.*' ]] && return 1

	if [[ ${_BAREWORD_IS_FILE} == 'false' ]];then # Bare words should be tested as possible file and dir names
		[[ -f ${TEXT:Q} || -d ${TEXT:Q} ]] && return 1 || return 0
	fi
}

is_dir () {
	local TEXT="${@}"

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	TEXT=$(eval "echo ${TEXT}")
	[[ -d ${TEXT} ]] && return 0 || return 1
}

is_empty_dir () {
	local DIR=${1}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -d ${DIR} ]] && return $(ls -A ${DIR} | wc -l)
}

is_file () {
	local TEXT="${@}"

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -f ${TEXT:Q} ]] && return 0 || return 1
}

is_glob () {
	local TEXT="${@}"

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${TEXT:Q} =~ '\*' ]] && return 0 || return 1
}

is_singleton () {
	local EXEC_NAME=${1}
	local INSTANCES=$(pgrep -fc ${EXEC_NAME})

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${INSTANCES} -eq 0 ]] && return 0 || return 1
}

is_symbol_dir () {
	local ARG=${1}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${ARG} =~ '^[\.~]$' ]] && return 0 || return 1
}

kbd_activate () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${XDG_SESSION_TYPE:l} != 'x11' ]] && return 0

	local KEYBOARD_DEV=$(kbd_get_keyboard_id)

	xinput reattach ${KEYBOARD_DEV} 3
}

kbd_get_keyboard_id () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${XDG_SESSION_TYPE:l} != 'x11' ]] && return 0

	local KEYBOARD_DEV=$(xinput list | grep  "AT Translated" | cut -f2 | cut -d= -f2)

	echo ${KEYBOARD_DEV}
}

kbd_suspend () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${XDG_SESSION_TYPE:l} != 'x11' ]] && return 0

	local KEYBOARD_DEV=$(kbd_get_keyboard_id)

	xinput float ${KEYBOARD_DEV}
}

key_wait () {
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo -n "Press any key..." && read -sk1
}

logit () {
	local LOG=''
	local MSG=''
	local STAMP=$(date +'%Y-%m-%d_%H:%M:')

	# Collect args
	[[ ${#} -gt 1 ]] && LOG=${1} && shift
	MSG=${@}

	if [[ -z ${LOG} ]];then # No log passed
		[[ -n ${_LOG} ]] && LOG=${_LOG} || LOG=/tmp/${0}.log} # Assign log
	fi

	echo "${STAMP} ${MSG}" >> ${LOG}
}

ls_color () {
	local FN=${1}
	local -A C_TAB=()
	local CODE=''
	local EXT=''
	local F1=''
	local F2=''
	local OBJ=''

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	# Load LS_COLORS into table
	IFS='='
	while read OBJ CODE;do
		C_TAB[${OBJ}]=${CODE}
	done<<<$(sed -e 's/:/\n/g' -e 's/\*\.//g'<<<${LS_COLORS})
	IFS=''

	EXT=${FN:e}
	if [[ -z ${EXT} ]];then
		[[ -x ${1} ]] && EXT=ex || EXT=fi # Minimal differentiation
	fi

	CODE=${C_TAB[${EXT}]}
	if [[ -n ${CODE} ]];then
		F1=$(cut -d';' -f1 <<<${CODE})
		F2=$(cut -d';' -f2 <<<${CODE})
		echo "\033[${F1};${F2}m"
	else
		echo "${RESET}"
	fi
}

max () {
	local -a NUMLIST=(${@})
	local MAX=0
	local N

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for N in ${NUMLIST};do
		[[ ${N} -gt ${MAX} ]] && MAX=${N}
	done

	echo ${MAX}
}

min () {
	local -a NUMLIST=(${@})
	local N
	local MIN=${NUMLIST[1]}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for N in ${NUMLIST};do
		[[ ${N} -lt ${MIN} ]] && MIN=${N}
	done

	echo ${MIN}
}

num_byte_conv () {
	local BYTES=${1}
	local WANTED=${2}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	case ${WANTED} in
		KB) echo $(( ${BYTES} / 1024 ));;
		MB) echo $(( ${BYTES} / 1024^2 ));;
		GB) echo $(( ${BYTES} / 1024^3 ));;
	esac
}

num_human () {
	local BYTES=${1}
	local GIG_D=1073741824
	local MEG_D=1048576
	local KIL_D=1024

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	(
	if [[ ${BYTES} -gt ${GIG_D} ]];then printf "%10.2fGB" $(( ${BYTES}.0 / ${GIG_D}.0 ))
	elif [[ ${BYTES} -gt ${MEG_D} ]];then printf "%10.2fMB" $(( ${BYTES}.0 / ${MEG_D}.0 ))
	elif [[ ${BYTES} -gt ${KIL_D} ]];then printf "%10.2fKB" $(( ${BYTES}.0 / ${KIL_D}.0 ))
	else printf "%10dB" ${BYTES} 
	fi
	) | sed 's/^[ \t]*//g' 
}

overwrite_file () {
	local FN=${1}

	if [[ -e ${FN} ]];then
		msg_box -p -PO -H1 "<r>Warning<N>|File:<w>${FN}<N> exists"
		[[ ${_MSG_KEY} == 'y' ]] && return 0 || return 1
	fi
}

parse_find_valid_delim () {
	local LINE=${1}
	local DELIM=''
	local D

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for D in ${_DELIMS};do
		grep -q ${D} <<<${LINE}
		[[ $? -eq 0 ]] && DELIM=${D} && break
	done

	[[ -n ${DELIM} ]] && echo ${DELIM} && return 0
	return 1
}

parse_get_last_field () {
	local DELIM=${1};shift
	local LINE=${@}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo -n ${LINE} | rev | cut -d"${DELIM}" -f1 | rev
}

reset_rate () {
	eval "xset ${_XSET_DEFAULT_RATE}"
}

respond () {
	local PROMPT=${1}
	local TIMEOUT=${2}
	local RESPONSE

	[[ -n ${TIMEOUT} ]] && TIMEOUT="-t ${TIMEOUT}"

	echo -n "${PROMPT}${WHITE_FG}?${RESET} ${WHITE_FG}(${RESET}${BOLD}${ITALIC}y${BOLD}${WHITE_FG}/${RESET}${BOLD}${ITALIC}n${RESET}${WHITE_FG})${RESET}:"
	eval "read -q ${TIMEOUT} RESPONSE" && echo >&2
	[[ ${RESPONSE} == 'y' ]] && return 0 || return 1
}
