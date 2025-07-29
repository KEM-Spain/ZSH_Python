# LIB functions
center () {
	#--Begin GetOpts--
	local -a OPTIONS
	local OPTION
	local DESC
	local OPTSTR=":HDRTh:r:t:v:x:y:"
	local OPTIND=0

	local REGION=false
	local HORZ=false
	local VERT=false
	local TEXT=false
	local TEST_MODE=false
	local REG_OVERRIDE=false
	local CONTAINER_WIDTH
	local CONTAINER_HEIGHT
	local REG_COORDS=''
	local _X_OFFSET=0
	local _Y_OFFSET=0

	while getopts ${OPTSTR} OPTION;do
		case $OPTION in
		  D) dbg_set_level;;
		  R) REGION=true;;
		  T) TEST_MODE=true;;
		  h) HORZ=true;CONTAINER_WIDTH=${OPTARG};;
		  r) REG_OVERRIDE=true;REG_COORDS=${OPTARG};;
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
	local _REG_HEIGHT=0
	local _REG_WIDTH=0
	local _TERM_HEIGHT=$(tput lines)
	local _TERM_WIDTH=$(tput cols)
	local _X_OFFSET=0
	local _Y_OFFSET=0
	
	[[ ${#} -eq 0 && ${#OPTIONS} -eq 0 ]] && exit_leave $(msg_exit E "Missing arguments or options")
	if [[ ${TEXT} == 'true' ]];then
		if validate_is_integer ${CONTAINER_WIDTH};then
			[[ -n ${1} ]] && TEXT_ARG=${1} || exit_leave $(err_msg_exit E "Missing argument:<TEXT>")
		else
			exit_leave $(err_msg_exit E "Invalid argument:<CONTAINER_WIDTH>:non integer")
		fi
		[[ $(( CONTAINER_WIDTH - 2 )) -lt ${#TEXT_ARG} ]] && exit_leave $(err_msg_exit E "Invalid argument:<CONTAINER_WIDTH> must exceed TEXT length (${#TEXT_ARG}) by 2 chars")
	fi

	if [[ ${REG_OVERRIDE} == 'false' ]];then
		_REG_WIDTH=${_TERM_WIDTH}
		_REG_HEIGHT=${_TERM_HEIGHT}
	else
		_REG_WIDTH=$(cut -d: -f1 <<<${REG_COORDS})
		_REG_HEIGHT=$(cut -d: -f2 <<<${REG_COORDS})
	fi

	[[ ${CONTAINER_HEIGHT} -gt ${_REG_HEIGHT} ]] && exit_leave $(err_msg_exit E "Invalid argument:<CONTAINER_HEIGHT>:exceeds region height (${_REG_HEIGHT})")
	[[ ${CONTAINER_WIDTH} -gt ${_REG_WIDTH} ]] && exit_leave $(err_msg_exit E "Invalid argument:<CONTAINER_WIDTH>:exceeds region width (${_REG_WIDTH})")

	REG_HORZ_CTR=$(center_get_center ${_REG_WIDTH})
	REG_HORZ_CTR=$(( REG_HORZ_CTR + _Y_OFFSET ))
	REG_VERT_CTR=$(center_get_center ${_REG_HEIGHT})
	REG_VERT_CTR=$(( REG_VERT_CTR + _X_OFFSET ))

	if [[ ${REGION} == 'true' ]];then
		[[ ${TEST_MODE} == 'true' ]] && center_test_region ${REG_HORZ_CTR} ${REG_VERT_CTR} && return
		echo ${REG_HORZ_CTR}:${REG_VERT_CTR} && return
	fi

	CONT_HORZ_CTR=$(center_get_center ${CONTAINER_WIDTH})
	CONT_HORZ_REF=$(( REG_HORZ_CTR - CONT_HORZ_CTR ))
	CONT_HORZ_REF=$(( CONT_HORZ_REF + _Y_OFFSET ))
	if [[ ${HORZ} == 'true' ]];then
		[[ ${TEST_MODE} == 'true' ]] && center_test_horz ${CONT_HORZ_REF} ${CONTAINER_WIDTH} && return
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CALLER:${functrace[-1]}:${functrace[1]} LINE:${LINENO} returned CONT_HORZ_REF:${CONT_HORZ_REF}"
		echo ${CONT_HORZ_REF} && return
	fi

	CONT_VERT_CTR=$(center_get_center ${CONTAINER_HEIGHT})
	CONT_VERT_REF=$(( REG_VERT_CTR - CONT_VERT_CTR ))
	CONT_VERT_REF=$(( CONT_VERT_REF + _X_OFFSET ))
	if [[ ${VERT} == 'true' ]];then
		[[ ${TEST_MODE} == 'true' ]] && center_test_vert ${CONT_VERT_REF} ${CONTAINER_HEIGHT} && return
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CALLER:${functrace[-1]}:${functrace[1]} LINE:${LINENO} returned CONT_VERT_REF:${CONT_VERT_REF}"
		echo ${CONT_VERT_REF} && return
	fi

	if [[ ${TEXT} == 'true' ]];then
		TEXT_CTR=$(center_get_center ${#TEXT_ARG})
		TEXT_REF=$(( CONT_HORZ_CTR - TEXT_CTR ))
		TEXT_REF=$(( CONT_HORZ_REF + TEXT_REF ))
		[[ ${TEST_MODE} == 'true' ]] && center_test_text ${CONT_HORZ_REF} ${CONTAINER_WIDTH} ${TEXT_REF} ${TEXT_ARG} && return
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CALLER:${functrace[-1]}:${functrace[1]} LINE:${LINENO} returned TEXT_REF:${TEXT_REF}"
		echo ${TEXT_REF} && return
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

center_opt_exists () {
	local OPT=${1}
	[[ $(( $OPTIONS[(Ie)${OPT}] )) -ne 0 ]] && return 0 || return 1
}

center_opt_type () {
	local OPT=${1}
	case ${OPT} in
		h) echo "<INT>";;
		o) echo "<INT>";;
		r) echo "<COORDS>";;
		s) echo "<STRING>";;
		t) echo "<INT>";;
		v) echo "<INT>";;
		x) echo "<INT>";;
		y) echo "<INT>";;
	esac
}

center_parse_opts () {
	local OPTS=${@}
	local -a OPTSTR
	local LETTER_OPT
	local O

	for O in {1..${#OPTS}};do
		[[ ${OPTS[${O}]} =~ '[A-Za-z]' ]] && LETTER_OPT=${OPTS[${O}]}
		[[ ${O} -eq 1 && ${OPTS[${O}]} == ":" ]] && continue
		[[ ${O} -gt 1 && ${OPTS[${O}]} == ":" ]] && OPTSTR+=$(center_opt_type ${LETTER_OPT}) && continue
		OPTSTR+="-${OPTS[${O}]}"
	done
	echo ${OPTSTR}
}

center_test_horz () {
	local CONT_REF=${1}
	local CONT_WIDTH=${2}
	local NDX=0
	local MARK=0
	local X

	# TODO: container -lt 2 breaks horz display
	 
	clear
	cursor_off
	tcup 0 ${CONT_REF};echo -n "|"
	NDX=1
	MARK=1
	for X in {1..$(( CONT_WIDTH - 2 ))};do
		[[ ${MARK} -ge 9 ]] && MARK=0 || ((MARK++))
		echo -n ${MARK}
		((NDX++))
	done
	((NDX++))
	tcup 0 $(( CONT_REF + CONT_WIDTH - 1 ));echo -n "|"
	tcup 1 0;echo -n "CONTAINER WIDTH:${NDX}"
	tcup 2 0;echo -n "CONTAINER REF:${CONT_REF}"
	tcup 3 0;echo -n "OFFSET:${_Y_OFFSET}"
	tcup 5 0;echo -n "${WHITE_FG}Press any key${RESET}"
	read -k1 2>/dev/null
	cursor_on
	clear
}

center_test_region () {
	local HORZ_CTR=${1}
	local VERT_CTR=${2}

	# TODO: Provide test for region override showing region outline and relative placement of containers and text
	 
	clear
	cursor_off
	tcup 0 ${HORZ_CTR};echo -n "|"
	tcup ${VERT_CTR} ${HORZ_CTR};echo -n "+"
	tcup $(( VERT_CTR + 1 )) 0;echo -n "VERT_CTR:${VERT_CTR}"
	tcup $(( VERT_CTR + 2 )) 0;echo -n "HORZ_CTR:${HORZ_CTR}"
	tcup $(( VERT_CTR + 3 )) 0;echo -n "REGION_WIDTH:${_REG_WIDTH}"
	tcup $(( VERT_CTR + 4 )) 0;echo -n "REGION_HEIGHT:${_REG_HEIGHT}"
	tcup $(( VERT_CTR + 5 )) 0;echo -n "OFFSETS: HORZ:${_Y_OFFSET}, VERT:${_X_OFFSET}"
	tcup $(( VERT_CTR + 7 )) 0;echo -n "${WHITE_FG}Press any key${RESET}"
	read -k1 2>/dev/null
	cursor_on
	clear
}

center_test_text () {
	local CONT_REF=${1}
	local CONT_WIDTH=${2}
	local TEXT_REF=${3}
	local TEXT=${4}
	local NDX=0
	local X

	clear
	cursor_off
	tcup ${_X_OFFSET} ${CONT_REF};echo -n "|"
	NDX=1
	for X in {1..$(( CONT_WIDTH - 2 ))};do
		((NDX++))
	done
	((NDX++))
	tcup ${_X_OFFSET} $(( CONT_REF + CONT_WIDTH - 1 ));echo -n "|"
	tcup $(( _X_OFFSET + 1 )) 0;echo -n "CONTAINER WIDTH:${NDX}"
	tcup $(( _X_OFFSET + 2 )) 0;echo -n "CONTAINER REF:${CONT_REF}"
	tcup $(( _X_OFFSET + 3 )) 0;echo -n "TEXT WIDTH:${#TEXT}"
	tcup $(( _X_OFFSET + 4 )) 0;echo -n "TEXT REF:${TEXT_REF}"
	tcup $(( _X_OFFSET + 5 )) 0;echo -n "OFFSETS: HORZ:${_Y_OFFSET}, VERT:${_X_OFFSET}"
	tcup ${_X_OFFSET} ${TEXT_REF};echo -n ${TEXT}
	tcup $(( _X_OFFSET + 7 )) 0;echo -n "${WHITE_FG}Press any key${RESET}"
	read -k1 2>/dev/null
	cursor_on
	clear
}

center_test_vert () {
	local CONT_REF=${1}
	local CONT_HEIGHT=${2}
	local NDX=0
	local MARK=0
	local CSR=${CONT_REF}
	local V_REF=0
	local X

	# TODO: container -lt 2 breaks vert display

	clear
	cursor_off
	tcup ${CSR} 80;echo -n "---"
	NDX=1
	MARK=1
	for X in {1..$(( CONT_HEIGHT - 2 ))};do
		((CSR++))
		[[ ${MARK} -ge 9 ]] && MARK=0 || ((MARK++))
		tcup ${CSR} 80;echo -n ${MARK}
		((NDX++))
	done
	((NDX++))
	V_REF=$(( CONT_REF + CONT_HEIGHT - 1 ))
	tcup ${V_REF} 80;echo "---"
	tcup $(( V_REF + 1 )) 0;echo -n "CONTAINER HEIGHT:${NDX}"
	tcup $(( V_REF + 2 )) 0;echo -n "CONTAINER REF:${CONT_REF}"
	tcup $(( V_REF + 3 )) 0;echo -n "OFFSET:${_X_OFFSET}"
	tcup $(( V_REF + 5 )) 0;echo -n "${WHITE_FG}Press any key${RESET}"
	read -k1 2>/dev/null
	cursor_on
	clear
}

