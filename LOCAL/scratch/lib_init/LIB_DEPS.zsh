typeset -a APP_DEPS=(${@})
typeset -A SEEN=()
DBG=true

is_valid () {
	FN=${1}

	[[ ! -e ${_LIB_DIR}/${FN} ]] && return 1 # Don't source non-existent
	[[ ${SEEN[${FN}]} -eq 1 ]] && return 1 # Don't source seen
	[[ ${FN} == ${0} ]] && return 1 # Don't source ourselves
	return 0
}

[[ ${DBG} == 'true' ]] && echo "ARGS:${#} ${@}" > debug.log
[[ ${DBG} == 'true' ]] && echo "APP_DEPS:${APP_DEPS}" >> debug.log

# Pre-scan - each APP module can add it's dependencies 
# to _DEPS (defined in LIB_INIT) to be sourced by the post scan
for A in ${=APP_DEPS};do # Pre scan
	FN=${A:t}
	if is_valid ${FN};then
		[[ ${DBG} == 'true' ]] && echo "Pre-scan Sourcing ${FN}" >> debug.log
		source ${_LIB_DIR}/${FN}
		SEEN[${FN}]=1
	fi
done

[[ ${DBG} == 'true' ]] && echo "_DEPS:${_DEPS}" >> debug.log

# Post-scan - source any modules in _DEPS
for D in ${_DEPS};do # Post scan
	FN=${D:t}
	if is_valid ${FN};then
		[[ ${DBG} == 'true' ]] && echo "Post-scan Sourcing ${FN}" >> debug.log
		source ${_LIB_DIR}/${FN}
		SEEN[${FN}]=1
	fi
done
