# LIB Dependencies
_DEPS_+=(DBG.zsh)

# LIB functions
err_msg_exit () {
	local E_MSG
	local E_TYPE
	local LABEL=''
	local LCOLOR=''

	if [[ ${#} -eq 1 ]];then
		E_TYPE=E
		E_MSG=${1}
	elif [[ ${#} -eq 2 ]];then
		E_TYPE=${1}
		E_MSG=${2}
	else
		echo "${0}: Insufficient args" >&2
	fi

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	case ${E_TYPE} in 
		W) LABEL="Warning";LCOLOR=${ITALIC}${BOLD}${MAGENTA_FG};;
		E) LABEL="Error";LCOLOR=${ITALIC}${BOLD}${RED_FG};;
		I) LABEL="Info";LCOLOR=${ITALIC}${CYAN_FG};;
		*) LABEL="Unknown E_TYPE:${E_TYPE}";;
	esac

	if [[ ${E_MSG} != 'null' ]];then
		[[ ${E_MSG} =~ ":" ]] && E_MSG=$(perl -pe "s/^(.*:)(.*)$/\1\e[37m\2\e[m/" <<<${E_MSG})
		printf "[${WHITE_FG}%s${RESET}]:[${LCOLOR}${LABEL}${RESET}] %s" ${_SCRIPT} "$(echo ${E_MSG})" >&2
	fi
}
