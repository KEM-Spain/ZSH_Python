err_msg_error () {
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

err_msg_exit () {
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
		[[ ${MSG} =~ ":" ]] && MSG=$(perl -p -e 's/:(\w+\.?\w+)(.*)$/\e[m:\e[3;37m$1\e[m\2/' <<<${MSG})
		printf "[${WHITE_FG}%s${RESET}]:[${LCOLOR}${LABEL}${RESET}] %s" ${_SCRIPT} "${MSG}"
	fi
}

err_msg_info () {
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

