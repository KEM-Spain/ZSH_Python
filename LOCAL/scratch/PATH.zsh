# LIB Vars
typeset _RAW_CMD_LINE=""

# LIB Functions
_path_read_cmdline () {
	local CMD=""
	local PIPE_PATTERN=""

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	if [[ ${_DURABLE[TESTMODE]} == 'true' ]];then
		CMD="${_RAW_CMD_LINE}"
	else
		CMD="$(fc -lnr -1 2>/dev/null)"
		CMD="${CMD#"${CMD%%[![:space:]]*}"}"
	fi

	PIPE_PATTERN='\|[[:space:]]*'"${_SCRIPT}"
	if [[ -n "${_SCRIPT}" && "${CMD}" =~ "${PIPE_PATTERN}" ]];then
		print -u2 "Input is piped"
		return 1
	fi

	if [[ "${CMD}" == *[[:space:]]* ]];then
		CMD="${CMD#*[[:space:]]}"
		CMD="${CMD#"${CMD%%[![:space:]]*}"}"
	else
		CMD=""
	fi

	print -r -- "${CMD}"
	return 0
}

path_abbv () {
	local MAX_LEN=""
	local OPTION=""
	local LINE=""
	local OPTSTR="l:"
	local -i OPTIND=0
	local -i LEN_LIMIT=60

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	while getopts ${OPTSTR} OPTION;do
		case ${OPTION} in
		  l) MAX_LEN="${OPTARG}";;
		  :) print -u2 "${_SCRIPT}: option: -${OPTARG} requires an argument"; usage; return 1;;
		 \?) print -u2 "${_SCRIPT}: ${BOLD}${RED_FG}Unknown option${RESET} -${OPTARG}"; usage; return 1;;
		esac
	done
	shift $(( OPTIND - 1 ))

	[[ -n "${MAX_LEN}" && "${MAX_LEN}" != 'false' ]] && LEN_LIMIT=${MAX_LEN}

	LINE="${1}"

	if [[ -z "${LINE}" ]];then
		printf '%s' ""
		return 0
	fi

	if [[ ${#LINE} -le ${LEN_LIMIT} ]];then
		printf '%s' "${LINE}"
		return 0
	fi

	print -r -- "${LINE}" | perl -wane'
		foreach $w (@F) {
			$w =~ s#/$(?=^/.*)##g;
			$w =~ s#([^/])([^/]*(?=.*/))#$1#g;
			$w =~ s/%//g;
			push (@line,$w);
		}
		printf("%-s\n", "@line");
	;'
}

path_expand_token () {
	local ARG="${1}"
	local ARG_TST=""
	local PATH_TST=""
	local -i RC=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	if [[ -z "${ARG}" ]];then
		print -r -- "${ARG}"
		return 1
	fi

	if [[ "${ARG}" =~ '^[\.~]' ]];then
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Expanding tilde or dot"
		ARG_TST="${ARG}"

		[[ "${ARG_TST}" =~ '\*$' ]] && ARG_TST="${ARG_TST:h}"

		if [[ "${ARG_TST}" == '~' ]];then
			ARG_TST="${HOME}"
		elif [[ "${ARG_TST}" == '~/'* ]];then
			ARG_TST="${HOME}/${ARG_TST#~/}"
		fi

		PATH_TST="$(command realpath -- "${ARG_TST}" 2>/dev/null)"
		RC=${?}
		[[ ${RC} -ne 0 || -z "${PATH_TST}" ]] && PATH_TST="${ARG_TST}"

		if [[ -f "${PATH_TST}" ]];then
			[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Expansion:${PATH_TST:h}"
			print -r -- "${PATH_TST:h}"
		else
			[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Expansion:${PATH_TST}"
			print -r -- "${PATH_TST}"
		fi
		return 0
	fi

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Nothing to expand"
	print -r -- "${ARG}"
	return 1
}

path_get_inode () {
	local FN="${1}"
	local INODE=""
	local -i RC=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	[[ -z "${FN}" ]] && return 1

	INODE="$(command stat -c '%i' -- "${FN}" 2>/dev/null)"
	RC=${?}

	if [[ ${RC} -eq 0 && -n "${INODE}" ]];then
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: returning true with:${INODE}"
		print -r -- "${INODE}"
		return 0
	fi

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: returning false"
	return 1
}

path_get_label () {
	local MAX_LEN="${1}"
	local LABEL=""
	local TAIL=""
	local RAW_PATH=""
	local PATH_EXPANDED=""

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	RAW_PATH="$(path_get_tokens)"

	[[ ! -d "${RAW_PATH:h}" ]] && return 1

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: calling path_expand_token with: ${RAW_PATH}"
	PATH_EXPANDED="$(path_expand_token "${RAW_PATH:h}")"
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: path_expand_token returned: ${PATH_EXPANDED}"

	if [[ -n "${MAX_LEN}" ]];then
		LABEL="$(path_abbv -l "${MAX_LEN}" "${PATH_EXPANDED}")"
	else
		LABEL="$(path_abbv "${PATH_EXPANDED}")"
	fi
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: Abbreviated ${PATH_EXPANDED} added to label"

	if [[ "${RAW_PATH:t}" =~ '^[\.~]$' ]];then
		TAIL=""
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TAIL is symbolic path - omitted from label"
	elif is_glob "${RAW_PATH:t}";then
		TAIL="/${RAW_PATH:t}"
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: TAIL is glob - added to label"
	fi

	LABEL="${LABEL}${TAIL}"

	printf '%s' "${LABEL}"
}

path_get_raw () {
	local RAW_CMD_LINE=""
	local RAW_PATH=""
	local PATH_HEAD="."
	local PATH_TAIL="-name '*'"
	local T=""
	local I=""
	local -i WORDS=0
	local -i RC=0
	local -a TOKENIZED=()
	local -a TOKENS=()

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	RAW_CMD_LINE="$(_path_read_cmdline)"
	RC=${?}
	[[ ${RC} -ne 0 ]] && return ${RC}

	RAW_PATH="$(path_strip_options "${RAW_CMD_LINE}")"

	if [[ -z "${RAW_PATH}" ]];then
		RAW_PATH="."
		PATH_HEAD="."
	else
		TOKENIZED=("${(f)$(path_parse_cmd "${RAW_PATH}")}")
		for T in "${TOKENIZED[@]}";do
			[[ -z "${T}" ]] && continue
			if is_bare_word "${T}";then
				((WORDS++))
				continue
			fi
			TOKENS+=("${T}")
		done

		RAW_PATH="${TOKENS[1]:-.}"
		PATH_HEAD="$(path_expand_token "${RAW_PATH}")"
		[[ -z "${PATH_HEAD}" ]] && PATH_HEAD="."
		[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ${WORDS} bare words stripped; RAW_PATH=[${RAW_PATH}] PATH_HEAD=[${PATH_HEAD}]"
	fi

	case "${RAW_PATH:t}" in
		'*'|""|"~"|".")
			PATH_TAIL="-name '*'"
			;;
		*)
			if is_dir "${RAW_PATH}";then
				PATH_TAIL="-name '*'"
			elif is_file "${PATH_HEAD}/${RAW_PATH:t}";then
				I="$(path_get_inode "${PATH_HEAD}/${RAW_PATH:t}")"
				RC=${?}
				[[ ${RC} -eq 0 && -n "${I}" ]] && PATH_TAIL="-inum ${I}" || PATH_TAIL="-name '*'"
			elif is_dir "${PATH_HEAD}/${RAW_PATH:t}" || is_glob "${RAW_PATH:t}";then
				PATH_TAIL="-name '${RAW_PATH:t}'"
			else
				PATH_TAIL="-name '*'"
			fi
			;;
	esac

	PATH_HEAD="$(command realpath -- "${PATH_HEAD}" 2>/dev/null || print -r -- "${PATH_HEAD}")"
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ${CYAN_FG}PATH_HEAD:${PATH_HEAD} PATH_TAIL:${PATH_TAIL}${RESET}"

	printf '%s' "${PATH_HEAD}|${PATH_TAIL}"
	return 0
}

path_get_raw_cmdline () {
	local RAW_CMD_LINE=""
	local -i RC=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	if [[ ${_DURABLE[TESTMODE]} == 'true' ]];then
		RAW_CMD_LINE="${_RAW_CMD_LINE}"
	else
		RAW_CMD_LINE="$(fc -lnr -1 2>/dev/null)"
		RAW_CMD_LINE="${RAW_CMD_LINE#"${RAW_CMD_LINE%%[![:space:]]*}"}"
	fi

	print -r -- "${RAW_CMD_LINE}"
	return ${RC}
}

path_get_raw_args () {
	local RAW_CMD_LINE=""
	local RAW_PATH=""
	local -i RC=0

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	RAW_CMD_LINE="$(_path_read_cmdline)"
	RC=${?}
	[[ ${RC} -ne 0 ]] && return ${RC}

	RAW_PATH="$(path_strip_options "${RAW_CMD_LINE}")"
	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${0}: ${CYAN_FG}RAW_PATH:${RAW_PATH} (removed script name & options)${RESET}"

	printf '%s' "${RAW_PATH}"
	return 0
}

path_get_tokens () {
	local RAW_CMD_LINE=""
	local RAW_PATH=""
	local A=""
	local -i RC=0
	local -a TOKENIZED=()
	local -a TOKENS=()

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	RAW_CMD_LINE="$(_path_read_cmdline)"
	RC=${?}
	[[ ${RC} -ne 0 ]] && return ${RC}

	RAW_PATH="$(path_strip_options "${RAW_CMD_LINE}")"
	TOKENIZED=("${(f)$(path_parse_cmd "${RAW_PATH}")}")

	for A in "${TOKENIZED[@]}";do
		[[ -z "${A}" ]] && continue
		if is_bare_word "${A}";then
			continue
		fi
		TOKENS+=("${A}")
	done

	RAW_PATH="${TOKENS[1]:-.}"
	printf '%s' "${RAW_PATH}"
	return 0
}

path_has_wildcard () {
	local RARGS=""

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	RARGS="$(path_get_raw_args)"
	[[ "${RARGS}" == *'*'* ]] && return 0 || return 1
}

path_parse_cmd () {
	local RAWCMD="${*}"
	local LINE=""
	local -a TEXT=()

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	while IFS= read -r LINE;do
		TEXT+=("${LINE}")
	done < <(path_split_cmd "${RAWCMD}")

	for LINE in "${TEXT[@]}";do
		print -r -- "${LINE}"
	done
}

path_split_cmd () {
	local RAWCMD="${*}"

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	if [[ -f "${RAWCMD}" ]];then
		print -r -- "${RAWCMD}"
	else
		perl -pe 's/(?<![\\])[ ]/\n/g' <<< "${RAWCMD}"
	fi
}

path_strip_options () {
	local CMD="${1}"
	local O=""
	local -i RC=0
	local -a OPTS=()

	[[ ${_DEBUG} -ge ${_HIGH_DBG} ]] && dbg "${_SCRIPT:t}->${0}:" "$(dbg_arglist "${@}")"

	OPTS=("${(f)$(grep -Po -- '\-+[A-Za-z0-9]+' <<< "${CMD}")}")
	RC=${?}

	for O in "${OPTS[@]}";do
		CMD="${CMD//"${O}"/}"
	done

	print -r -- "${CMD}"
	[[ ${RC} -eq 0 || ${RC} -eq 1 ]] && return 0 || return ${RC}
}