# LIB Dependencies
_DEPS_+="DBG.zsh MSG.zsh STR.zsh"

# LIB Functions
arr_get_nonzero_count () {
	local -a A=(${@})
	local CNT=0
	local E

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for E in ${A};do
		[[ ${E} -ne 0 ]] && ((CNT++))
	done

	echo ${CNT}
}

arr_get_populated_count () {
	local -a A=(${@})
	local CNT=0
	local E

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for E in ${A};do
		[[ -n ${E} ]] && ((CNT++))
	done

	echo ${CNT}
}

arr_is_populated () {
	local -a ARR=(${@})
	local RC
	
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}, ARR:${#ARR}"

	[[ ${#} -eq 0 ]] && echo "${0}: ${RED_FG}requires an argument${RESET} of type <ARRAY> ${#}" >&2

	[[ ${ARR[@]} =~ "^ *$" ]] && RC=1 || RC=0
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Returning:${RC}"

	return ${RC}
}

arr_long_elem () {
	local LIST=(${@})
	local LONGEST=0
	local LONGEST_STR
	local STR
	local L

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for L in ${LIST};do
		STR=$(msg_nomarkup ${L})
		STR=$(str_strip_ansi <<<${STR})
		STR=$(str_trim ${STR})
		[[ ${#STR} -ge ${LONGEST} ]] && LONGEST=${#STR} && LONGEST_STR=${STR}
	done

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: LONGEST ELEMENT:${LONGEST} STR:${STR}"

	echo ${LONGEST_STR} # Trimmed/no markup
}

arr_long_elem_len () {
	local LIST=(${@})
	local LONGEST=0
	local STR
	local L

	for L in ${LIST};do
		STR=$(msg_nomarkup ${L})
		STR=$(str_strip_ansi <<<${STR})
		STR=$(str_trim ${STR})
		[[ ${#STR} -ge ${LONGEST} ]] && LONGEST=${#STR}
	done

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: LONGEST ELEMENT LEN:${LONGEST}"

	echo ${LONGEST} # Trimmed/no markup
}

in_array () {
	local ARRAY_NAME=${1}
	local ELEMENT=${2}

	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ARRAY_NAME:${ARRAY_NAME}"
	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ELEMENT:${ELEMENT}"

	[[ ${${(P)ARRAY_NAME}[(i)${ELEMENT}]} -le ${#${(P)ARRAY_NAME}} ]] && return 0
	return 1
}

