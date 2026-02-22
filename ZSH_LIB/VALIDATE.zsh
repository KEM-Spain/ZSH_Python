# LIB Dependencies
_DEPS_+=(DBG.zsh)

# LIB functions
validate_is_integer () {
	local VAL=${1}
	local RET

	[[ ${#} -eq 0 ]] && return 1

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	RET=$(echo "${VAL}" | sed 's/^[-+]*[0-9]*//g')
	[[ -z ${RET} ]] && return 0 || return 1
}

validate_is_list_item () {
	local ITEM_NDX=${1}
	local MAX_ITEM=${2}

	[[ ${#} -lt 2 ]] && return 1

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ ${ITEM_NDX} -gt 0 && ${ITEM_NDX} -le ${MAX_ITEM} ]] && return 0 || return 1
}

validate_is_number () {
	local ARG=${1}
	local LEFT=0
	local RIGHT=0

	[[ ${#} -eq 0 ]] && return 1

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARG:${ARG}"

	[[ ${ARG} =~ '^[-]' || ${ARG} =~ '^[+]' ]] && ARG=${ARG[2,-1]}

	if [[ ${ARG} =~ '[.]' ]];then
		LEFT=$(cut -d'.' -f1 <<<${ARG})
		RIGHT=$(cut -d'.' -f2 <<<${ARG})
		if [[ ${LEFT} == ${LEFT%%[!0-9]*} && ${RIGHT} == ${RIGHT%%[!0-9]*} ]];then
			return 0
		else
			return 1
		fi
	else
		if [[ ${ARG} == ${ARG%%[!0-9]*} ]];then
			return 0
		else
			return 1
		fi
	fi
}

