typeset -A SEEN=()
DBG=false

is_valid () {
	FN=${1}

	[[ ! -e ${_LIB_DIR}/${FN} ]] && return 1 # Don't source non-existent
	[[ ${SEEN[${FN}]} -eq 1 ]] && return 1 # Don't source seen
	[[ ${FN} == ${0} ]] && return 1 # Don't source ourselves
	return 0
}

[[ ${DBG} == 'true' ]] && echo "ARGS:${#} ${@}" > debug.log
[[ ${DBG} == 'true' ]] && echo "APP_DEPS:${APP_DEPS}" >> debug.log

# Multiple passes may be needed as previously
# unseen dependencies are added to _DEPS array
MAX_DEPS=${#_DEPS}
PASS=1
while true;do
	for D in ${_DEPS};do # Post scan
		FN=${D:t}
		if is_valid ${FN};then
			[[ ${DBG} == 'true' ]] && echo "Dependency scan pass ${PASS}: Sourcing ${FN}" >> debug.log
			source ${_LIB_DIR}/${FN}
			SEEN[${FN}]=1
		fi
	done
	[[ ${#_DEPS} -gt ${MAX_DEPS} ]] && MAX_DEPS=${#_DEPS} || break
	((PASS++))
done
