# Import standard libs
[[ -z ${ZSH_LIB_DIR} ]] && LIB_DIR=/usr/local/lib || LIB_DIR=${ZSH_LIB_DIR}

source ${LIB_DIR}/ANSI.zsh
source ${LIB_DIR}/EXIT.zsh
source ${LIB_DIR}/ERROR.zsh
source ${LIB_DIR}/LIB_DEPS.zsh

# Default Options
setopt warncreateglobal # Monitor locals
setopt rematchpcre # Use perl regex

# Perl vars
MATCH=?
MBEGIN=?
MEND=?
match=''
mbegin=''
mend=''

# Constants
_MY_PID="$$"

_SCRIPT=${$(cut -d: -f1 <<<${funcfiletrace}):t}
_DEBUG_FILE=/tmp/${_MY_PID}.${_SCRIPT}_debug.out
_GEO_KEY="key=uMibiyDeEGlYxeK3jx6J"
_GEO_PROVIDER="https://extreme-ip-lookup.com"
_MAX_COLS=$(tput -T xterm cols)
_MAX_ROWS=$(tput -T xterm lines)
_SCRIPT_TAG="[${WHITE_FG}${_SCRIPT}${RESET}]:"
_TERM=xterm
_XSET_DEFAULT_RATE="r rate 500 33" # Default <delay> <repeat>
_XSET_MENU_RATE="r rate 600 20" # Menu rate <delay> <repeat>

# ROW status 
_AVAIL_ROW=0 # Selectable
_SELECTED_ROW=1 # Selected
_STALE_ROW=2 # Not selectable
_USED_ROW=3 # Processed row

# LIB declarations
typeset -aU _DEPS_
typeset -A _BOX_COORDS=()
typeset -A _REL_COORDS=()

# Debug levels
_LOW_DBG=1
_LOW_DETAIL_DBG=2
_MID_DBG=3
_MID_DETAIL_DBG=4
_HIGH_DBG=5

typeset -A _DEBUG_LEVELS=(
${_LOW_DBG} LOW
${_LOW_DETAIL_DBG} LOW_DETAIL
${_MID_DBG} MID
${_MID_DETAIL_DBG} MID_DETAIL
${_HIGH_DBG} HIGH
)

# LIB var inits
_CURSOR_STATE=on
_DEBUG=0
_DEBUG_INIT=true
_EXIT_MSGS=''
_EXIT_SCRUB=true

# Initialize traps
unsetopt localtraps
for SIG in {1..9}; do
	trap 'exit_sigexit '${SIG}'' ${SIG}
done
_FUNC_TRAP=true

# Initialize debugging
[[ -e ${_DEBUG_FILE} ]] && /bin/rm ${_DEBUG_FILE}

