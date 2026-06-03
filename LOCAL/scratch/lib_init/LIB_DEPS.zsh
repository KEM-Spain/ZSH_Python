typeset -A SEEN=()
_DBG=false

is_valid () {
	FN=${1}

	[[ ! -e ${_LIB_DIR}/${FN} ]] && return 1 # Don't source non-existent
	[[ ${SEEN[${FN}]} -eq 1 ]] && return 1 # Don't source seen
	[[ ${FN} == ${0} ]] && return 1 # Don't source ourselves
	return 0
}

# LIB_INIT defines the _DEPS array and pre-populates
# it with default modules. Sourced modules then
# append _DEPS with their dependencies.  Multiple 
# passes resolve any additions to the _DEPS array if 
# modified when modules are sourced
MAX_DEPS=${#_DEPS}
PASS=1
while true;do
	for D in ${_DEPS};do # Post scan
		FN=${D:t}
		if is_valid ${FN};then
			[[ ${_DBG} == 'true' ]] && echo "Dependency scan pass ${PASS}: Sourcing ${FN}" >> debug.log
			source ${_LIB_DIR}/${FN}
			SEEN[${FN}]=1
		fi
	done
	[[ ${#_DEPS} -gt ${MAX_DEPS} ]] && MAX_DEPS=${#_DEPS} || break # _DEPS is stable - break
	((PASS++))
done
