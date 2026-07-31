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
[[ -z ${_SCRIPT} ]] && _SCRIPT=${${${(s/:/)funcfiletrace}[1]}:t}
_MY_PID="$$"
_SCRIPT_TAG="[${WHITE_FG}${_SCRIPT}${RESET}]:"
_DEBUG_FILE=/tmp/${_MY_PID}.${_SCRIPT}_debug.out
_GEO_KEY="key=uMibiyDeEGlYxeK3jx6J"
_GEO_PROVIDER="https://extreme-ip-lookup.com"
_MAX_COLS=$(tput -T xterm cols)
_MAX_ROWS=$(tput -T xterm lines)
_TERM=xterm
_XSET_DEFAULT_RATE="r rate 500 33" # Default <delay> <repeat>
_XSET_MENU_RATE="r rate 600 20" # Menu rate <delay> <repeat>

# LIST ROW status 
_AVAIL_ROW=0 # Selectable
_SELECTED_ROW=1 # Selected
_STALE_ROW=2 # Not selectable
_USED_ROW=3 # Processed row

# LIB declarations
typeset -A _BOX_COORDS=()
typeset -A _REL_COORDS=()
typeset -aU _DEPS=()
typeset -a _SCREEN=() # Holds displayed list content
typeset -A _ROW_CODES=(0 AVAILABLE 1 SELECTED 2 STALE  3 USED)
typeset -A _MOUNT_CODES=(
0 "0 - success"
1 "1 - incorrect invocation or permissions"
2 "2 - system error (out of memory, cannot fork, no more loop devices)"
4 "4 - internal mount bug"
8 "8 - user interrupt"
16 "16 - problems writing or locking /etc/mtab"
20 "partition is not free - an active process is using the partition"
25 "cannot unmount - partition is not mounted"
30 "partition is not free - an active process is using the partition"
35 "cannot mount - partition is already mounted"
32 "32 - failure"
64 "64 - partial mount succeeded"
)

# Default Modules
_DEPS=(ANSI.zsh DBG.zsh ERROR.zsh EXIT.zsh UTILS.zsh)

# Debug level constants
_LOW_DBG=1
_MID_DBG=2
_HIGH_DBG=3

typeset -A _DEBUG_LEVELS=(
${_LOW_DBG} LOW
${_MID_DBG} MID
${_HIGH_DBG} HIGH
)

# LIB var inits
_CURSOR_STATE=on
_DEBUG=0
_DEBUG_INIT=true
_EXIT_MSGS=''
_EXIT_SCRUB=true
_SMCUP=false

# Initialize traps
unsetopt localtraps
for SIG in {1..9}; do
	trap 'exit_sigexit '${SIG}'' ${SIG}
done
_FUNC_TRAP=true

# Initialize debugging
[[ -e ${_DEBUG_FILE} ]] && /bin/rm ${_DEBUG_FILE}
