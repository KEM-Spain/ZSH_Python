# LIB Dependencies
_DEPS_+="STR.zsh"

# Declarations
typeset -a _DEBUG_LINES=()

# LIB Functions
dbg () {
	local -a ARGS=(${@})
	local LINE
	local A

	if [[ ${_DEBUG_INIT} == 'true' ]];then
		echo "${WHITE_FG}DEBUG Level ${_DEBUG}${RESET}: ${BOLD}${MAGENTA_FG}${_DEBUG_LEVELS[${_DEBUG}]}${RESET}" >> ${_DEBUG_FILE}
		_DEBUG_INIT=false
	fi

	if [[ ${#} -ne 0 ]];then
		dbg_to_file ${ARGS} # With arguments
	else
		while read LINE;do
			ARGS+="${LINE}\n"
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
	local FN=$(cut -d: -f1 <<<${@})
	local LN=$(cut -d: -f2 <<<${@})

	(
	sed -n ${LN}p ${FN} | tr -d '[(){}]' | tr -s '[:space:]' | str_trim
	) 2>/dev/null
}

dbg_record () {
	local LINE

	_DEBUG_LINES+="-- msgs --"

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

	[[ -n ${ARGS} ]] && echo "-- msgs --" >>${_DEBUG_FILE}
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
		CALLER=$(realpath $(cut -d: -f1 <<<${L}))
		CALLER_LINE=$(cut -d: -f2 <<<${L})
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

