# LIB Dependencies
_DEPS_+=(DBG.zsh)

# LIB functions
err_msg_exit () {
	if [[ ${#} -eq 2 ]];then
		local E_TYPE=${1}
		local MSG=${2}
	else
		return 1
	fi

	local LABEL=''
	local LCOLOR=''

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -z ${@} ]] && (echo "${0}: missing argument" && return 1)

	case ${E_TYPE} in 
		W) LABEL="Warning";LCOLOR=${ITALIC}${BOLD}${MAGENTA_FG};;
		E) LABEL="Error";LCOLOR=${ITALIC}${BOLD}${RED_FG};;
		I) LABEL="Info";LCOLOR=${ITALIC}${CYAN_FG};;
		*) LABEL="Unknown E_TYPE:${E_TYPE}";;
	esac

	if [[ ${MSG} != 'null' ]];then
		[[ ${MSG} =~ ":" ]] && MSG=$(perl -pe "s/^(.*:)(.*)$/\1\e[37m\2\e[m/" <<<${MSG})
		printf "[${WHITE_FG}%s${RESET}]:[${LCOLOR}${LABEL}${RESET}] %s" ${_SCRIPT} "$(echo ${MSG})" >&2
	fi
	return 0
}
