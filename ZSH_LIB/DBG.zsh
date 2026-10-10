# LIB Dependencies
_DEPS+=(STR.zsh)

# LIB Declarations
typeset -a _DEBUG_LINES=()

# LIB Functions
dbg_arglist () {
	local A
	local NDX=0
	local TEXT=''

	[[ ${#} -eq 0 ]] && echo "${functrace[1]}:${YELLOW_FG}no args passed${RESET}" && return

	TEXT=${@}
	echo "${BOLD}${ITALIC}${WHITE_FG}${functrace[1]}${RESET} [${WHITE_FG}ARGUMENTS${RESET}:${WHITE_FG}${#}${RESET}]"
	if [[ ${#TEXT} -lt 100 ]];then
		for A in "${@}";do
			((NDX++))
			echo -n " Arg:${GREEN_FG}${NDX}${RESET}:${WHITE_FG}${A}${RESET}"
		done
		echo ''
	else
		for A in "${@}";do
			((NDX++))
			echo "Arg:${GREEN_FG}${NDX}${RESET}:${WHITE_FG}${A}${RESET}"
		done
	fi
}

dbg_functrace () {
	local -a COMPOSITE_TRACE=()
	local -a FIELDS=()
	local INDENT=''
	local FUNC_NAME=''
	local FILE_PATH=''
	local LINE_NUM=0
	local ENTRY=''
	local I

	# 1. Build the composite array directly from the built-in arrays
	for (( I = 1; I <= ${#functrace}; I++ )); do
		FUNC_NAME="${functrace[I]%:*}"
		FILE_PATH="${funcfiletrace[I]%:*}"
		LINE_NUM="${funcfiletrace[I]##*:}"

		# Format: "function_name|file_path|line_number"
		COMPOSITE_TRACE+=("${FUNC_NAME}|${FILE_PATH}|${LINE_NUM}")
	done

	echo "\n${WHITE_FG}Functrace Call List${RESET}"

	# 2. Iterate through the composite array (reversed order)
	for I in "${(Oa)COMPOSITE_TRACE[@]}"; do
		FIELDS=(${(s:|:)I})
		FUNC_NAME="${FIELDS[1]:t}"
		FILE_PATH="${FIELDS[2]:t}"
		LINE_NUM="${FIELDS[3]}"

		[[ ${file_path} =~ ${_SCRIPT} ]] && continue

		echo "Caller:${INDENT}-> ${CYAN_FG}${FUNC_NAME}${RESET} in ${FILE_PATH}:${WHITE_FG}${RESET} from line ${WHITE_FG}${LINE_NUM}${RESET}"
		INDENT+=" "
	done
}

dbg () {
	local -a ARGS=("${@}")
	local LINE
	local A

	if [[ ${_DEBUG_INIT} == 'true' ]];then
		echo "\n${WHITE_FG}DEBUG Level ${_DEBUG}${RESET}: ${BOLD}${MAGENTA_FG}${_DEBUG_LEVELS[${_DEBUG}]}${RESET}" >> ${_DEBUG_FILE}
		_DEBUG_INIT=false
	fi

	if [[ ${#} -ne 0 ]];then
		dbg_to_file ${ARGS} # With arguments
	else
		for A in ${ARGS};do
			echo ${A}
		done
		echo ${ARGS} | dbg_record # Piped to array
	fi
}

dbg_msg () {
	local D
	local LINE

	echo 

	for D in ${_DEBUG_LINES};do
		echo ${D:s/called/${ITALIC}${WHITE_FG}called${RESET}/}
	done

	if [[ -f ${_DEBUG_FILE} ]];then
		while read LINE;do
			echo ${LINE:s/called/${ITALIC}${WHITE_FG}called${RESET}/}
		done <${_DEBUG_FILE}
	fi

	dbg_trace
}

dbg_parse () {
	local FN=${${(s/:/)@}[1]}
	local LN=${${(s/:/)@}[2]}

	(
	sed -n ${LN}p ${FN} | tr -d '[(){}]' | tr -s '[:space:]' | str_trim
	) 2>/dev/null
}

dbg_record () {
	local LINE

	#_DEBUG_LINES+="-- msgs --"

	while read LINE;do
		_DEBUG_LINES+=${LINE}
	done

	_DEBUG_LINES+=$(dbg_trace)
}

dbg_set_level () {
	((_DEBUG++))
}

dbg_to_file () {
	local -a ARGS=(${@})
	local A

	#[[ -n ${ARGS} ]] && echo "-- msgs --" >>${_DEBUG_FILE}
	for A in ${ARGS};do
		echo ${A} >>${_DEBUG_FILE}
	done
}

dbg_trace () {
	local CALLER
	local CALLER_SOURCE
	local CALLER_LINE
	local L
	local FIRST_TIME=true
	local DD=false

	for L in ${(on)funcfiletrace};do
		[[ ${L} =~ "dbg" ]] && continue # Omit calls to any dbg func
		CALLER=$(realpath ${${(s/:/)L}[1]})
		CALLER_LINE=${${(s/:/)L}[2]}
		CALLER_SOURCE=$(dbg_parse ${L})
		[[ ${CALLER_SOURCE} =~ "dbg" ]] && continue # Omit calls to all dbg_* funcs
		[[ ${DD} == 'true' ]] && echo "Debugging DEBUG: L:${L} CALLER:${CALLER}"
		[[ ${FIRST_TIME} == 'true' ]] && echo "\nFunc File\n---------" && FIRST_TIME=false
		printf "%30s called: %s on line %d\n" ${CALLER} ${CALLER_SOURCE} ${CALLER_LINE}
	done

	FIRST_TIME=true
	for L in ${(Oa)funcstack};do
		[[ ${L} =~ "dbg" ]] && continue # Omit calls to any dbg func
		[[ ${FIRST_TIME} == 'true' ]] && echo "\nFunc Stack\n----------" && FIRST_TIME=false
		echo ${L}
	done

	FIRST_TIME=true
	for L in ${(Oa)functrace};do
		[[ ${L} =~ "dbg" ]] && continue # Omit calls to any dbg func
		[[ ${FIRST_TIME} == 'true' ]] && echo "\nFunc Trace\n----------" && FIRST_TIME=false
		echo ${L}
	done
}

dbg_args () {
	local ARGS=${@}
	if [[ ${#ARGS} -gt 1 ]];then
		echo "ARGC:${#ARGS}" >>${_DEBUG_FILE}
		echo "ARGV:${ARGS}" >>${_DEBUG_FILE}
	fi
}
