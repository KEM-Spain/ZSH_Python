# LIB Dependencies
_DEPS_+=(DBG.zsh MSG.zsh TPUT.zsh VALIDATE.zsh UTILS.zsh)

# LIB functions
center () {
	#--Begin GetOpts--
	local -a OPTIONS
	local OPTION
	local DESC
	local OPTSTR=":ADR:Th:rt:v:x:y:"
	local OPTIND=0

	local ABSOLUTE=false
	local CONTAINER_HEIGHT
	local CONTAINER_WIDTH
	local HORZ=false
	local REGION=false
	local REG_COORDS=''
	local REG_OVERRIDE=false
	local TEST_MODE=false
	local TEXT=false
	local VERT=false
	local _X_OFFSET=0
	local _Y_OFFSET=0

	while getopts ${OPTSTR} OPTION;do
		case $OPTION in
		  A) ABSOLUTE=true;;
		  D) dbg_set_level;;
		  R) REG_OVERRIDE=true;REG_COORDS=${OPTARG};;
		  T) TEST_MODE=true;;
		  h) HORZ=true;CONTAINER_WIDTH=${OPTARG};;
		  r) REGION=true;;
		  t) TEXT=true;CONTAINER_WIDTH=${OPTARG};;
		  v) VERT=true;CONTAINER_HEIGHT=${OPTARG};;
		  x) _X_OFFSET=${OPTARG};;
		  y) _Y_OFFSET=${OPTARG};;
		  :) print -u2 "${RED_FG}${_SCRIPT}${RESET}: option: -${OPTARG} requires an argument"; exit_leave;;
		 \?) print -u2 "${RED_FG}${_SCRIPT}${RESET}: unknown option -${OPTARG}"; exit_leave;;
		esac
		[[ ${OPTION} != 'D' ]] && OPTIONS+=${OPTION}
	done
	shift $((OPTIND -1))
	#--End GetOpts--

	local CONT_HORZ_CTR
	local CONT_HORZ_REF
	local CONT_VERT_CTR
	local CONT_VERT_REF
	local TEXT_CTR=0
	local TEXT_REF=0
	local TEXT_ARG=''
	local REG_HORZ_CTR=0
	local REG_VERT_CTR=0
	local _REG_X=0
	local _REG_Y=0
	local _REG_HEIGHT=0
	local _REG_WIDTH=0
	local _TERM_HEIGHT=$(tput lines)
	local _TERM_WIDTH=$(tput cols)
	local _X_OFFSET=0
	local _Y_OFFSET=0
	
	[[ ${#} -eq 0 && ${#OPTIONS} -eq 0 ]] && exit_leave $(err_msg_exit E "Missing arguments or options")

	[[ ${TEST_MODE} == 'true' && -n ${CONTAINER_WIDTH} && ${CONTAINER_WIDTH} -lt 3 ]] && exit_leave $(err_msg_exit E "Invalid argument - test mode requires >= 3:<CONTAINER_WIDTH>")
	[[ ${TEST_MODE} == 'true' && -n ${CONTAINER_HEIGHT} && ${CONTAINER_HEIGHT} -lt 3 ]] && exit_leave $(err_msg_exit E "Invalid argument - test mode requires >= 3:<CONTAINER_HEIGHT>")

	if [[ ${TEXT} == 'true' ]];then
		if validate_is_integer ${CONTAINER_WIDTH};then
			[[ -n ${1} ]] && TEXT_ARG=${1} || exit_leave $(err_msg_exit E "Missing argument:<TEXT>")
		else
			exit_leave $(err_msg_exit E "Invalid argument:<CONTAINER_WIDTH>:non integer")
		fi
		[[ $(( CONTAINER_WIDTH - 2 )) -lt ${#TEXT_ARG} ]] && exit_leave $(err_msg_exit E "Invalid argument:<CONTAINER_WIDTH> must exceed TEXT length (${#TEXT_ARG}) by 2 chars")
	fi

	if [[ ${REG_OVERRIDE} == 'false' ]];then
		_REG_X=0
		_REG_Y=0
		_REG_WIDTH=${_TERM_WIDTH}
		_REG_HEIGHT=${_TERM_HEIGHT}
	else
		[[ ! ${REG_COORDS} =~ "\d\d:\d\d:\d\d:\d\d" ]] && exit_leave "${_SCRIPT_TAG} ${RED_FG}Invalid argument${RESET}:<REG_COORDS> has incorrect format. Format:'X:Y:W:H'"
		_REG_X=$(cut -d: -f1 <<<${REG_COORDS})
		_REG_Y=$(cut -d: -f2 <<<${REG_COORDS})
		_REG_WIDTH=$(cut -d: -f3 <<<${REG_COORDS})
		_REG_HEIGHT=$(cut -d: -f4 <<<${REG_COORDS})
	fi

	[[ ${CONTAINER_HEIGHT} -gt ${_REG_HEIGHT} ]] && exit_leave $(err_msg_exit E "Invalid argument:<CONTAINER_HEIGHT>:exceeds region height (${_REG_HEIGHT})")
	[[ ${CONTAINER_WIDTH} -gt ${_REG_WIDTH} ]] && exit_leave $(err_msg_exit E "Invalid argument:<CONTAINER_WIDTH>:exceeds region width (${_REG_WIDTH})")

	REG_HORZ_CTR=$(center_get_center ${_REG_WIDTH})
	REG_HORZ_CTR=$(( REG_HORZ_CTR + _Y_OFFSET ))
	REG_VERT_CTR=$(center_get_center ${_REG_HEIGHT})
	REG_VERT_CTR=$(( REG_VERT_CTR + _X_OFFSET ))

	if [[ ${REGION} == 'true' ]];then
		[[ ${TEST_MODE} == 'true' ]] && center_test_region ${REG_HORZ_CTR} ${REG_VERT_CTR} && return
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CALLER:${functrace[-1]}:${functrace[1]} LINE:${LINENO} returned REGION:${_REG_X}:${_REG_Y}:${REG_HORZ_CTR}:${REG_VERT_CTR}"
		echo ${_REG_X}:${_REG_Y}:${REG_HORZ_CTR}:${REG_VERT_CTR}
		return
	fi

	CONT_HORZ_CTR=$(center_get_center ${CONTAINER_WIDTH})
	CONT_HORZ_REF=$(( REG_HORZ_CTR - CONT_HORZ_CTR ))
	CONT_HORZ_REF=$(( CONT_HORZ_REF + _Y_OFFSET ))
	if [[ ${HORZ} == 'true' ]];then
		[[ ${TEST_MODE} == 'true' ]] && center_test_horz ${CONT_HORZ_REF} ${CONTAINER_WIDTH} && return
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CALLER:${functrace[-1]}:${functrace[1]} LINE:${LINENO} returned CONT_HORZ_REF:${CONT_HORZ_REF}"
		[[ ${ABSOLUTE} == 'true' ]] && echo $(( _REG_Y + CONT_HORZ_REF )) || echo ${CONT_HORZ_REF}
		return
	fi

	CONT_VERT_CTR=$(center_get_center ${CONTAINER_HEIGHT})
	CONT_VERT_REF=$(( REG_VERT_CTR - CONT_VERT_CTR ))
	CONT_VERT_REF=$(( CONT_VERT_REF + _X_OFFSET ))
	if [[ ${VERT} == 'true' ]];then
		[[ ${TEST_MODE} == 'true' ]] && center_test_vert ${CONT_VERT_REF} ${CONTAINER_HEIGHT} && return
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CALLER:${functrace[-1]}:${functrace[1]} LINE:${LINENO} returned CONT_VERT_REF:${CONT_VERT_REF}"
		[[ ${ABSOLUTE} == 'true' ]] && echo $(( _REG_X + CONT_VERT_REF )) || echo ${CONT_VERT_REF}
		return
	fi

	if [[ ${TEXT} == 'true' ]];then
		TEXT_CTR=$(center_get_center ${#TEXT_ARG})
		TEXT_REF=$(( CONT_HORZ_CTR - TEXT_CTR ))
		TEXT_REF=$(( CONT_HORZ_REF + TEXT_REF ))
		[[ ${TEST_MODE} == 'true' ]] && center_test_text ${CONT_HORZ_REF} ${CONTAINER_WIDTH} ${TEXT_REF} ${TEXT_ARG} && return
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CALLER:${functrace[-1]}:${functrace[1]} LINE:${LINENO} returned TEXT_REF:${TEXT_REF}"
		[[ ${ABSOLUTE} == 'true' ]] && echo $(( _REG_Y + TEXT_REF )) || echo ${TEXT_REF}
		return
	fi
}

center_get_center () {
	local WIDTH=${1}
	local CENTER=0
	local REM=0

	CENTER=$(( WIDTH / 2 ))
	REM=$(( WIDTH % 2 ))
	[[ ${REM} -ne 0 ]] && (( CENTER++ ))

	echo ${CENTER}
}

center_test_horz () {
	local CONT_REF=${1}
	local CONT_WIDTH=${2}
	local MARK=0
	local X

	clear
	cursor_off
	msg_unicode_box ${_REG_X} ${_REG_Y} ${_REG_WIDTH} ${_REG_HEIGHT}
	MARK=1
	tcup $(( _REG_X + 1 )) $(( _REG_Y + CONT_REF )) && echo -n "|"
	for X in {1..$(( CONT_WIDTH - 2 ))};do
		[[ ${MARK} -ge 9 ]] && MARK=0 || ((MARK++))
		echo -n ${MARK}
	done
	tcup $(( _REG_X + 1 )) $(( _REG_Y + CONT_REF + CONT_WIDTH - 1 )) && echo -n "|"
	msg_box -x0 -y0 -p -PK -jl -H1 "Horizontal Container Test|REGION_X/Y:(${_REG_X},${_REG_Y})|REGION_W/H:(${_REG_WIDTH},${_REG_HEIGHT})|CONTAINER WIDTH:${CONT_WIDTH}|CONTAINER REF:${CONT_REF}|HORZ OFFSET:${_Y_OFFSET}|ABSOLUTE:$(( _REG_Y + CONT_REF ))"
	cursor_on
	clear
}

center_test_region () {
	local HORZ_CTR=${1}
	local VERT_CTR=${2}

	clear
	cursor_off
	msg_unicode_box ${_REG_X} ${_REG_Y} ${_REG_WIDTH} ${_REG_HEIGHT}
	tcup $(( _REG_X )) $(( _REG_Y + HORZ_CTR ));echo -n "|"
	tcup $(( _REG_X + VERT_CTR )) $(( _REG_Y + HORZ_CTR ));echo -n "+"
	msg_box -x0 -y0 -p -PK -jl -H1 "Region Test|REGION_X/Y:(${_REG_X},${_REG_Y})|REGION_W/H:(${_REG_WIDTH},${_REG_HEIGHT})|VERT_CTR:${VERT_CTR}|HORZ_CTR:${HORZ_CTR}|ABSOLUTE: VERT:$(( _REG_X + VERT_CTR )) HORZ:$(( _REG_Y + HORZ_CTR ))"
	cursor_on
	clear
}

center_test_text () {
	local CONT_REF=${1}
	local CONT_WIDTH=${2}
	local TEXT_REF=${3}
	local TEXT=${4}

	clear
	cursor_off
	msg_unicode_box ${_REG_X} ${_REG_Y} ${_REG_WIDTH} ${_REG_HEIGHT}
	tcup $(( _REG_X + _X_OFFSET + 1 )) $(( _REG_Y + CONT_REF ));echo -n "|"
	tcup $(( _REG_X + _X_OFFSET + 1 )) $(( _REG_Y + CONT_REF + CONT_WIDTH - 1 ));echo -n "|"
	tcup $(( _REG_X + _X_OFFSET + 1 )) $(( _REG_Y + TEXT_REF ));echo -n ${TEXT}
	msg_box -x0 -y0 -p -PK -jl -H1 "Text Placement Test|REGION_X/Y:(${_REG_X},${_REG_Y})|REGION_W/H:(${_REG_WIDTH},${_REG_HEIGHT})|CONTAINER WIDTH:${NDX}|CONTAINER REF:${CONT_REF}|TEXT WIDTH:${#TEXT}|TEXT REF:${TEXT_REF}|OFFSETS: HORZ:${_Y_OFFSET}, VERT:${_X_OFFSET}"
	cursor_on
	clear
}

center_test_vert () {
	local CONT_REF=${1}
	local CONT_HEIGHT=${2}
	local NDX=0
	local MARK=0
	local CSR=$(( _REG_X + CONT_REF ))
	local V_REF=0
	local X

	clear
	cursor_off
	MARK=1
	msg_unicode_box ${_REG_X} ${_REG_Y} ${_REG_WIDTH} ${_REG_HEIGHT}
	tcup ${CSR} $(( _REG_Y + $(center_get_center _REG_WIDTH) - 2 ));echo -n "---"
	for X in {1..$(( CONT_HEIGHT - 2 ))};do
		((CSR++))
		[[ ${MARK} -ge 9 ]] && MARK=0 || ((MARK++))
		tcup ${CSR} $(( _REG_Y + $(center_get_center _REG_WIDTH) - 2 ));echo -n ${MARK}
	done
	tcup $(( _REG_X + CONT_REF + CONT_HEIGHT - 1 )) $(( _REG_Y + $(center_get_center _REG_WIDTH) - 2 ));echo "---"
	msg_box -x0 -y0 -p -PK -jl -H1 "Vertical Container Test|REGION_X/Y:(${_REG_X},${_REG_Y})|REGION_W/H:(${_REG_WIDTH},${_REG_HEIGHT})|CONTAINER HEIGHT:${CONT_HEIGHT}|CONTAINER REF:${CONT_REF}|VERT OFFSET:${_X_OFFSET}|ABSOLUTE:$(( _REG_X + CONT_REF ))"
	cursor_on
	clear
}

