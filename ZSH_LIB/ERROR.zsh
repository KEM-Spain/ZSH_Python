# LIB Dependencies
_DEPS_+=(DBG.zsh)

# LIB functions
err_msg_exit () {
	local E_MSG=''
	local E_TYPE=''
	local LABEL=''
	local LCOLOR=''

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	if [[ ! -t 0 ]];then
		read E_MSG
		E_TYPE=E
	else
		if [[ ${#} -eq 0 ]];then
			return 1 # No args
		elif [[ ${#} -eq 1 ]];then
			E_MSG=${1}
			E_TYPE=E # Default type
		elif [[ ${#} -eq 2 ]];then
			E_TYPE=${1}
			E_MSG=${2}
		fi
	fi

	case ${E_TYPE} in 
		W) LABEL="Warning";LCOLOR=${ITALIC}${BOLD}${MAGENTA_FG};;
		E) LABEL="Error";LCOLOR=${ITALIC}${BOLD}${RED_FG};;
		I) LABEL="Info";LCOLOR=${ITALIC}${CYAN_FG};;
	esac

	if [[ -n ${E_MSG} ]];then
		[[ ${E_MSG} =~ ":" ]] && E_MSG=$(perl -pe "s/^(.*:)(\w+)(.*)$/\1\e[37m\2\e[m\3/" <<<${E_MSG})
		printf "[${WHITE_FG}%s${RESET}]:[${LCOLOR}${LABEL}${RESET}] %s" ${_SCRIPT} "$(echo ${E_MSG})"
	fi
}
