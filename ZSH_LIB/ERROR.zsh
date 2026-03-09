# LIB Dependencies
_DEPS_+=(DBG.zsh)

# LIB functions
err_msg_exit () {
	local E_MSG=''
	local E_TYPE=''
	local LABEL=''
	local LCOLOR=''
	local IS_FILE=''

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
		IS_FILE=$(rev <<<$(cut -d: -f1 <<<$(rev <<<${E_MSG})))
		if [[ -f ${IS_FILE} || ${IS_FILE} =~ ".\.." ]];then
			E_MSG="$(cut -d: -f1 <<<${E_MSG}):${WHITE_FG}${IS_FILE}${RESET}"
		else
			[[ ${E_MSG} =~ ":" ]] && E_MSG=$(perl -pe 's/(.*:)(.*?\s+)(.*)/\1\e[37m\2\e[m\3/g' <<<${E_MSG})
		fi
		printf "[${WHITE_FG}%s${RESET}]:[${LCOLOR}${LABEL}${RESET}] %s" ${_SCRIPT} "$(echo ${E_MSG})"
	fi
}
