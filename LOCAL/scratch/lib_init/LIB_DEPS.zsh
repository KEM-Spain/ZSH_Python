typeset -a APP_DEPS=(${@})
typeset -A SEEN=()

#echo "ARGS:${#} ${@}" > debug.log
#echo "APP_DEPS:${APP_DEPS}" >> debug.log

# Pre-scan - each APP module can add it's dependencies 
# to _DEPS (defined in LIB_INIT) to be sourced by the post scan
for A in ${=APP_DEPS};do # Pre scan
	[[ ${A} == ${0:t} ]] && continue # Don't source ourselves
	[[ ${SEEN[${A}]} -eq 1 ]] && continue # Don't source seen
	[[ ! -e ${_LIB_DIR}/${A} ]] && continue # Don't source non-existent
	#echo "Pre-scan Sourcing ${A}" >> debug.log
	source ${_LIB_DIR}/${A}
	SEEN[${A}]=1
done

#echo "_DEPS:${_DEPS}" >> debug.log

# Post-scan - source any modules in _DEPS
for D in ${_DEPS};do # Post scan
	[[ ${D} == ${0:t} ]] && continue # Don't source ourselves
	[[ ${SEEN[${D}]} -eq 1 ]] && continue # Don't source seen
	[[ ! -e ${_LIB_DIR}/${D} ]] && continue # Don't source non-existent
	#echo "Post-scan Sourcing ${D}" >> debug.log
	source ${_LIB_DIR}/${D}
	SEEN[${D}]=1
done
