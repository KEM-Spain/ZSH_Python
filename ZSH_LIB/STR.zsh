# LIB Dependencies
_DEPS_+="TPUT.zsh DBG.zsh"

str_array_to_num () {
	local -a STR=(${@})
	local MAX=${#STR}
	local NUM=0
	local MAG=0
	local S

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	((MAX--))
	for S in ${STR};do
		((MAG=10**MAX))
		NUM=$(( NUM + (S * MAG) ))
		((MAX--))
	done

	echo ${NUM}
}

str_center () {
	local -i PAD
	local -i REM
	local BORDER
	local MSG 
	local TEXT 
	local TEXT_WIDTH
	local WIDTH

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	WIDTH=${1};shift
	TEXT="${@}"
	TEXT_WIDTH=${#TEXT}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: WIDTH:${WIDTH} TEXT:${TEXT} TEXT_WIDTH:${TEXT_WIDTH}"

	REM=$(( WIDTH - ${TEXT_WIDTH} ))
	BORDER=' ' # Minimum border
	if [[ ${REM} -ne 0 ]];then
		PAD=$(( REM / 2 ))
		BORDER=$(printf ' %.0s' {1..${PAD}})
	fi

	MSG="${BORDER}${TEXT}${BORDER}" # Pad

	[[ ${#MSG} -lt ${WIDTH} ]] && MSG=$(str_pad_string ${WIDTH} ${MSG})
	[[ ${#MSG} -gt ${WIDTH} ]] && MSG=${MSG[1,${WIDTH}]} # Do not exceed width

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ${WHITE_FG}\nReturning${RESET}:${0} with [${MSG}] Length:${#MSG}" >&2 

	echo "${MSG}"
}

str_center_pad () {
	local -A PAD=()
	local -i GAP=0
	local -i L_GAP=0
	local -i R_GAP=0
	local SPAN=0
	local S_LEN
	local TEXT_IN=''
	local TEXT_WIDTH=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	SPAN=${1};shift
	TEXT_IN=${@}

	(( SPAN -= 2 )) # Minimum 1 space border surrounding text
	TEXT_WIDTH=$(str_clean_line_len ${TEXT_IN})

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TEXT_IN:${TEXT_IN} TEXT_WIDTH:${TEXT_WIDTH}"

	GAP=$(( SPAN - TEXT_WIDTH ))
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: SPAN:${SPAN} GAP:${GAP}"

	if [[ ${GAP} -gt 0 ]];then
		L_GAP=$(( GAP / 2 ))
		S_LEN=$(( L_GAP + TEXT_WIDTH ))
		R_GAP=$(( SPAN - S_LEN ))
	fi
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: RETURNING: ${L_GAP}:${R_GAP}"

	echo "${L_GAP}:${R_GAP}"
}

str_clean_line_len () {
	local TEXT_IN=${@}
	local LEN

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	LEN=$(echo ${TEXT_IN} | sed -e 's/\x1b\[[0-9;]*m//g' -e 's/ *$//g' | tr -d '\011\012\015') # Ansi/space/newlines/etc
	echo ${#LEN}
}

str_clean_path () {
	local DIR=${1}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo "${DIR}" | perl -pe 's#/+#/# G'
}

str_expanded_length () {
	local STR=${@}
	local LEN

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	LEN=$(expand <<<${STR} | wc -m)
	echo $(( --LEN ))
}

str_from_hex () {
	local HEX=${@}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -n ${HEX} ]] && printf $HEX
}

str_pad_digit () {
	local NDX=${1}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${NDX} -lt 10 ]] && echo "  ${NDX}" && return
	[[ ${NDX} -lt 100 ]] && echo " ${NDX}" && return
	[[ ${NDX} -lt 1000 ]] && echo "${NDX}" && return
}

str_pad_string () {
	local WIDTH
	local STR

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	WIDTH=${1};shift
	STR=${@}
	STR="${STR}$(str_rep_char ' ' $(( WIDTH - ${#STR} )))"

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Returning with:${WHITE_FG}[${STR}]${RESET}" >&2 

	echo ${STR}
}

str_pluralize () {
	local WORD=${1}
	local CNT=${2}
	local RETURN_BOTH=${3:=false} # Any 3rd arg triggers 
	local RETURN_WORD

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} WORD:${WORD}"

	if [[ ${CNT} -eq 1 ]];then
		[[ ${RETURN_BOTH} == 'false' ]] && echo "${WORD}" || echo "${CNT} ${WORD}"
		return
	fi

	case ${WORD:l} in
		app) RETURN_WORD="apps";;
		candidate) RETURN_WORD="candidates";;
		choice) RETURN_WORD="choices";;
		command) RETURN_WORD="commands";;
		commit) RETURN_WORD="commits";;
		config) RETURN_WORD="configs";;
		country) RETURN_WORD="countries";;
		cup) RETURN_WORD="cups";;
		day) RETURN_WORD="days";;
		degree) RETURN_WORD="degrees";;
		device) RETURN_WORD="devices";;
		dir) RETURN_WORD="dirs";;
		directory) RETURN_WORD="directories";;
		download) RETURN_WORD="downloads";;
		duplicate) RETURN_WORD="duplicates";;
		entry) RETURN_WORD="entries";;
		file) RETURN_WORD="files";;
		foot) RETURN_WORD="feet";;
		function) RETURN_WORD="functions";;
		gram) RETURN_WORD="grams";;
		inch) RETURN_WORD="inches";;
		item) RETURN_WORD="items";;
		kilo) RETURN_WORD="kilos";;
		kilometer) RETURN_WORD="kilometers";;
		library) RETURN_WORD="libraries";;
		link) RETURN_WORD="links";;
		line) RETURN_WORD="lines";;
		level) RETURN_WORD="levels";;
		log) RETURN_WORD="logs";;
		match) RETURN_WORD="matches";;
		meter) RETURN_WORD="meters";;
		mile) RETURN_WORD="miles";;
		milliliter) RETURN_WORD="milliliters";;
		object) RETURN_WORD="objects";;
		option) RETURN_WORD="options";;
		ounce) RETURN_WORD="ounces";;
		package) RETURN_WORD="packages";;
		pound) RETURN_WORD="pounds";;
		process) RETURN_WORD="processes";;
		reminder) RETURN_WORD="reminders";;
		row) RETURN_WORD="rows";;
		title) RETURN_WORD="titles";;
		torrent) RETURN_WORD="torrents";;
		track) RETURN_WORD="tracks";;
		video) RETURN_WORD="videos";;
		was) RETURN_WORD="were";;
		*) RETURN_WORD=${WORD};;
	esac

	[[ ${WORD} == ${(C)WORD} ]] && RETURN_WORD=${(C)RETURN_WORD} || RETURN_WORD=${RETURN_WORD}

	if [[ ${WORD} == ${WORD:u} ]];then # Assume uppercase
		RETURN_WORD=${RETURN_WORD:u}
	else # Assume mixed or lowercase
		RETURN_WORD=${RETURN_WORD}
	fi

	[[ ${RETURN_BOTH} == 'false' ]] && echo "${RETURN_WORD}" || echo "${CNT} ${RETURN_WORD}"
}

str_rep_char () {
	local CHAR=${1}
	local LENGTH=${2}
	local LINE
	local X

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	LINE=''
	for ((X=0;X < ${LENGTH};X++));do
		LINE=${LINE}''${CHAR}
	done

	echo ${LINE}
}

str_no_ansi () {
	perl -pe 's/\x1B\[+[\d;]*[mK]//g' <<<${@}
}

str_strip_ansi () {
	local LINE_IN
	local LINE_OUT

	local OPTION
	local OPTSTR=":l"
	local REPLY
	local RETURN_LEN=false

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	OPTIND=0

	while getopts ${OPTSTR} OPTION;do
		case ${OPTION} in
			l) RETURN_LEN=true;;
			:) print -u2 " ${_SCRIPT}: option: -${OPTARG} requires an argument" >&2;read ;;
			\?) print -u2 " ${_SCRIPT}: ${0}: unknown option -${OPTARG}" >&2; read;;
		esac
	done
	shift $(( OPTIND - 1 ))

	IFS='' # Preserve white space
	while read -r LINE_IN;do
		# Strip ansi escape chars
		LINE_OUT+=$(perl -pe 's/\x1B\[+[\d;]*[mK]//g' <<<${LINE_IN})
	done

	[[ ${RETURN_LEN} == 'true' ]] && echo ${#LINE_OUT} || echo ${LINE_OUT}
}

str_to_hex () {
	local TXT=${@}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo $TXT | od -An -tx1 | tr -d '[\n]' | sed 's/ /\\x/g' 
}

str_trim () {
	local TEXT_IN=${@}
	local TEXT

		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TEXT_IN:\"${TEXT_IN}\""

		if [[ -z ${TEXT_IN} && ! -t 0 ]];then
			read TEXT
			[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TEXT_IN:\"${TEXT}\""
			TEXT=$(sed 's/\t/ /g' <<<${TEXT}) # Tabs distort output
			TEXT=$(sed 's/^ *//' <<<${TEXT}) # Leading spaces
			TEXT=$(sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//' <<<${TEXT})
			[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TEXT_OUT:\"${TEXT}\""
			echo ${TEXT}
		else
			TEXT_IN=$(sed 's/\t/ /g' <<<${TEXT_IN}) # Tabs distort output
			TEXT_IN=$(sed 's/^ *//' <<<${TEXT_IN}) # Leading spaces
			TEXT_IN=$(sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//' <<<${TEXT_IN})
			[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TEXT_OUT:\"${TEXT_IN}\""
		echo ${TEXT_IN}
	fi
}

str_truncate () {
	local LENGTH=${1} && shift
	local TEXT=${@}

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} LENGTH:${LENGTH}"

	echo ${TEXT[1,${LENGTH}]}
}

str_unicode_line () {
	local LENGTH=${1}
	local HORIZ_BAR="\\u2500%.0s"

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} LENGTH:${LENGTH}"

	do_rmso
	printf "\\u2500%.0s" {1..$(( ${LENGTH} ))}
}

str_unpipe () {
	local FIELD
	local CUT_PARAM
	local PIPE_DATA

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${#} -gt 1 ]] && FIELD=${1} && shift
	PIPE_DATA=${@}

	[[ -n ${FIELD} ]] && CUT_PARAM="-f${FIELD}" || CUT_PARAM="-f1-" 
	cut --output-delimiter=' ' -d'|' ${CUT_PARAM} <<<${PIPE_DATA}
}

str_word_clip () {
	local TEXT=${1}
	local LEN=${2}
	local -a BREAKS=()
	local LAST_BREAK
	local LINE=''
	local B P

	[[ ${LEN} -ge ${#TEXT} ]] && LINE=${TEXT} # No length restriction

	if [[ -z ${LINE} ]];then
		for (( P=1; P <= ${#TEXT}; P++ ));do # Mark all word boundaries
			[[ ${TEXT[${P}]} =~ "[[:space:]]" ]] && BREAKS+=${P}
		done

		LINE=${TEXT} # Default is entire line
		LAST_BREAK=${BREAKS[1]} # First pass has rational length

		for B in ${BREAKS};do
			[[ ${B} -gt ${LEN} ]] && LINE="${TEXT[1,${LAST_BREAK}]}" && break # Hit max length
			LAST_BREAK=${B}
		done
	fi

	LINE=$(sed -E -e 's/[[:punct:]]*\s+?$//' -e 's/ *$//' <<<${LINE}) # Clean the tail of dangling punctuation

	echo ${LINE}
}

