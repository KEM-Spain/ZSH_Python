# Imports
[[ -z ${ZSH_LIB_DIR} ]] && _LIB_DIR=/usr/local/lib || _LIB_DIR=${ZSH_LIB_DIR}
source ${_LIB_DIR}/LIB_INIT.zsh
source ${_LIB_DIR}/LIB_DEPS.zsh ${DEPS} # (Must be pre defined array and loaded with dependencies or passed as string)
