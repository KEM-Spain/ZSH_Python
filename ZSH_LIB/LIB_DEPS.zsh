typeset -a APP_DEPS=(${@})
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

# Pre-scan - each module will add it's dependencies 
# to _DEPS (defined in LIB_INIT) to be sourced by the post scan
# TODO: This section is likely unecessary. The post-scan section
# TODO: modification to perform multiple passes should suffice.
for A in ${=APP_DEPS};do # Pre scan
	FN=${A:t}
	if is_valid ${FN};then
		[[ ${DBG} == 'true' ]] && echo "Pre-scan Sourcing ${FN}" >> debug.log
		source ${_LIB_DIR}/${FN}
		[[ ${DBG} == 'true' ]] && echo "${FN}: _DEPS:${_DEPS}" >> debug.log
		SEEN[${FN}]=1
	fi
done


# Post-scan - source any modules in _DEPS
# Multiple passes may be needed as previously
# unseen dependencies are added to _DEPS
MAX_DEPS=${#_DEPS}
PASS=1
while true;do
	for D in ${_DEPS};do # Post scan
		FN=${D:t}
		if is_valid ${FN};then
			[[ ${DBG} == 'true' ]] && echo "Post-scan pass ${PASS}: Sourcing ${FN}" >> debug.log
			source ${_LIB_DIR}/${FN}
			SEEN[${FN}]=1
		fi
	done
	[[ ${#_DEPS} -gt ${MAX_DEPS} ]] && MAX_DEPS=${#_DEPS} || break
	((PASS++))
done
