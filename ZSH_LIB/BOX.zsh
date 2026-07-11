# LIB Dependencies
_DEPS+=(TPUT.zsh)

# LIB Vars
_BOX_TAG="/tmp/${_MY_PID}.box_tag"

# LIB Functions
box_coords_del () {
	local TAG=${1}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TAG:${TAG}"

	assoc_del_key _BOX_COORDS ${TAG}
}

box_coords_dump () {
	local K

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	echo "\n--- Begin BOX COORDS ---"
	for K in ${(ok)_BOX_COORDS};do
		printf "${WHITE_FG}TAG${RESET}:%s ${WHITE_FG}COORDS${RESET}:%s\n" ${K} ${_BOX_COORDS[${K}]}
	done
	echo "--- End BOX COORDS ---"
}

box_coords_get () {
	local TAG=${1}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TAG:${TAG}"

	[[ -z ${_BOX_COORDS[${TAG}]} ]] && return 1

	echo ${(kv)_BOX_COORDS[${TAG}]}
}

box_coords_overlap () {
	local TAG_1=${1}
	local TAG_2=${2}

	local -A BOX_1_COORDS=($(box_coords_get ${TAG_1}))
	local -A BOX_2_COORDS=($(box_coords_get ${TAG_2}))

	local X1_MIN=${BOX_1_COORDS[X]}
	local X1_MAX=$(( BOX_1_COORDS[X] + BOX_1_COORDS[H] - 1 )) # Add the height
	local Y1_MIN=${BOX_1_COORDS[Y]}
	local Y1_MAX=$(( BOX_1_COORDS[Y] + BOX_1_COORDS[W] - 1 )) # Add the width

	local X2_MIN=${BOX_2_COORDS[X]}
	local X2_MAX=$(( BOX_2_COORDS[X] + BOX_2_COORDS[H] - 1 )) # Add the height
	local Y2_MIN=${BOX_2_COORDS[Y]}
	local Y2_MAX=$(( BOX_2_COORDS[Y] + BOX_2_COORDS[W] - 1 )) # Add the width

	# isOverlapping = (x1min < x2max) && (x2min < x1max) && (y1min < y2max) && (y2min < y1max)
	
	local OVERLAP=1

	[[ ${X1_MIN} -lt ${X2_MAX} && ${X2_MIN} -lt ${X1_MAX} && ${Y1_MIN} -lt ${Y2_MAX} && ${Y2_MIN} -lt ${Y1_MAX} ]] && OVERLAP=0

	return ${OVERLAP} # Return true - is overlap
}

box_coords_relative () {
	local BASE_TAG=${1};shift
	local -A OFFSETS=(${@})
	local -A BASE_COORDS=()

	# OFFSETS are in the form [+-]INT or INT

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	BASE_COORDS=($(box_coords_get ${BASE_TAG}))
	[[ -z ${BASE_COORDS} ]] && return 1

	if [[ -n ${OFFSETS[X]} ]];then
		[[ ${OFFSETS[X]} =~ '[+-]' ]] && BASE_COORDS[X]=$(( ${BASE_COORDS[X]}${OFFSETS[X]} )) || BASE_COORDS[X]=${OFFSETS[X]}
	fi
	if [[ -n ${OFFSETS[Y]} ]];then
		[[ ${OFFSETS[Y]} =~ '[+-]' ]] && BASE_COORDS[Y]=$(( ${BASE_COORDS[Y]}${OFFSETS[Y]} )) || BASE_COORDS[Y]=${OFFSETS[Y]}
	fi
	if [[ -n ${OFFSETS[W]} ]];then
		[[ ${OFFSETS[W]} =~ '[+-]' ]] && BASE_COORDS[W]=$(( ${BASE_COORDS[W]}${OFFSETS[W]} )) || BASE_COORDS[W]=${OFFSETS[W]}
	fi
	if [[ -n ${OFFSETS[H]} ]];then
		[[ ${OFFSETS[H]} =~ '[+-]' ]] && BASE_COORDS[H]=$(( ${BASE_COORDS[H]}${OFFSETS[H]} )) || BASE_COORDS[H]=${OFFSETS[H]}
	fi

	echo ${(kv)BASE_COORDS}
}

box_coords_repaint () {
	local TAG=${1}
	local -A COORDS=($(box_coords_get ${TAG}))
	local LIST_ROW=0
	local LNDX=0
	local ROW_LIMIT=0
	local SNDX=0

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	[[ -z ${_SCREEN} ]] && return # Screen cache is empty

	if [[ -z ${TAG} && -e ${LAST_COORDS} ]];then
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: No TAG, getting LAST_COORDS TAG"
		read TAG < ${LAST_COORDS}
		/bin/rm -f ${LAST_COORDS}
		if [[ -n ${TAG} ]];then
			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Got LAST_COORDS TAG:${TAG}"
			COORDS=($(box_coords_get ${TAG}))
		fi
	fi

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: TAG:${TAG} COORDS:${(kv)COORDS}"

	LIST_ROW=$(( COORDS[X] - _LIST_HEADER_LINES + 1 ))
	ROW_LIMIT=$(( LIST_ROW + COORDS[H] - 1 ))

	for (( LNDX=LIST_ROW; LNDX <= ROW_LIMIT; LNDX++ ));do
		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _SCREEN[LNDX]: ${_SCREEN[${LNDX}]}"
		[[ -n ${_SCREEN[${LNDX}]} ]] && tput cup $(( COORDS[X] + SNDX )) 0 && echo -n ${_SCREEN[${LNDX}]}
		((SNDX++))
	done
}

box_coords_set () {
	local -a ARGS=(${@})
	local TAG=${ARGS[1]}
	local COORDS=${ARGS[2,-1]}

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TAG:${TAG}"

	_BOX_COORDS[${TAG}]="OWNER ${(U)functrace[1]:s/:/_/} ${COORDS}"

	echo ${TAG} > ${_BOX_TAG}
}

box_coords_upd () {
	local -a ARGS=(${@})
	local TAG=${ARGS[1]}
	local -A UPD=(${ARGS[2,-1]})
	local -A ORIG=($(box_coords_get ${TAG}))
	local K V

	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"

	for K in ${(k)UPD};do
		ORIG[${K}]=${UPD[${K}]}
	done

	box_coords_set ${TAG} ${(kv)ORIG}
}
