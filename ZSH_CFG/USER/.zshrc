#!/usr/bin/env zsh

# Inline ansi
BOLD="\033[1m"
ITALIC="\033[3m"
RESET="\033[m"
REVERSE="\033[7m"
STRIKE="\033[9m"
UNDER="\033[4m"
BLACK_BG="\033[40m"
BLUE_FG="\033[34m"
CYAN_FG="\033[36m"
GREEN_FG="\033[32m"
MAGENTA_FG="\033[35m"
RED_FG="\033[31m"
WHITE_FG="\033[37m"
YELLOW_FG="\033[33m"

# Constants
_REL=$(lsb_release -d | cut -d: -f2- | sed 's/^[ \t]*//')
_RLBL=$(lsb_release -c | cut -d: -f2- | sed 's/^[ \t]*//')
_USR_LOCAL_SRC=/usr/local/src
_CMP_FUNCTIONS=/home/kmiller/.zsh/completions
_SYS_FUNCTIONS=/etc/zsh/system_wide/functions
_MOTD_DIR=/etc/update-motd.d
_SYS_ALIASES=/etc/zsh/aliases
_SYS_ZSHRC=/etc/zsh/zshrc
_WIFI_PREF="WiFi_OliveNet-Casa 7_5G"
_BATT_LIMIT=96
_CAL_LINES=9
_HIST_MSG=$(mktemp /tmp/hist.msg.XXXXXX)

# Vars
_TERMCNT=$(terms -c)
_NDX=0

# Declarations
typeset -a _MOTD=()
typeset -a _HIST=()
typeset -U path cdpath fpath manpath # Automatically remove duplicates from these arrays
typeset -A _NUM_WORDS=(1 one 2 two 3 three 4 four 5 five 6 six 7 seven 8 eight 9 nine 10 ten)

# Imports 
source ${_SYS_ALIASES}
source ${_SYS_ZSHRC}
source ${_USR_LOCAL_SRC}/fast-syntax-highlighting/F-Sy-H.plugin.zsh # Fast-syntax-highlighting.plugin
#source ${_USR_LOCAL_SRC}/zsh-autocomplete/zsh-autocomplete.plugin.zsh # Auto completion
source ${_USR_LOCAL_SRC}/zhooks/zhooks.plugin.zsh # Add zhooks command to display active hooks

# Exports
export GREP_COLORS='ms=01;31:mc=01;31:sl=:cx=:fn=97:ln=32:bn=32:se=36' # https://askubuntu.com/questions/1042234/modifying-the-color-of-grep
export HISTORY_IGNORE="(cd(| *)|ls(| *)|tail(| *)|tvi(| *)|cp(| *)|mv(| *)|exit(| *))"
export MUSIC_DIR=/media/kmiller/KEM_Misc/Music/KEM-B9
export PRINTER=ENVY-5000
export TERM=xterm
export DEFAULT_PLAYER=CLMN
export PYDEVD_DISABLE_FILE_VALIDATION=1
export GIT_AUTHOR_NAME="Kurt Miller"
export GIT_AUTHOR_EMAIL="miller.kurt.e@gmail.com"
export LC_ALL=C.utf8
export DISPLAY=:0
export CPU_WARN_LIMIT=800

# Functions 
_check_updates () {
	sudo chmod 644 ${_MOTD_DIR}/10-help-text # Disable

	local -a MSGS_1
	local -a MSGS_2
	local COUNT=0
	local NUM=0
	local M

	MSGS_1+=("${(f)$(sudo run-parts ${_MOTD_DIR} | grep -vi esm)}")

	for M in ${MSGS_1};do
		[[ ${M:l} =~ 'esm' ]] && continue
		[[ ! ${M:l} =~ 'applied' ]] && continue
		NUM=$(cut -d' ' -f1 <<<${M})
		if [[ ${NUM} -gt 0 && ${M} =~ 'applied' ]];then
			(( COUNT += ${NUM} ))
		fi
	done

	MSGS_2=("${(f)$(apt list --upgradable 2>/dev/null)}")

	if [[ ${COUNT} -ne 0 ]];then
		for M in ${MSGS_2};do
			[[ ! ${M:l} =~ 'listing\|done' ]] && continue
			((COUNT++))
		done
	fi

	if [[ ${COUNT} -eq 0 ]];then
		_MOTD+="${ITALIC}No updates available...${RESET}"
	else
		_MOTD+="${GREEN_FG}${BOLD}${ITALIC}Updates available:${RESET}(${WHITE_FG}${COUNT}${RESET})"
	fi
}

_cursor_on () {
	tput cnorm
}

_cursor_row () {
	local ROW

	echo -ne "\033[6n" > /dev/tty # Voodoo to grab row
	read -t1 -s -d'R' ROW < /dev/tty # Parse usable bit
	ROW=$(cut -d';' -f1 <<<${ROW} | tr -dc '0-9') # Split and strip non digits (escape seq etc.)
	((ROW--))
	echo ${ROW}
}

_reload_aliases () {
	local LAST_ALIAS_REFRESH=0
	local CURR_ALIAS_TIME
	local STAMP_FILE=~/.zsh/last_alias_refresh

	[[ -e ${_SYS_ALIASES} ]] || return 1
	[[ -e ${STAMP_FILE} ]] && LAST_ALIAS_REFRESH=$(<${STAMP_FILE})
	CURR_ALIAS_TIME=$(stat -c %Y ${_SYS_ALIASES}) 
	if [[ ${LAST_ALIAS_REFRESH} -lt ${CURR_ALIAS_TIME} ]]; then
		echo "Refreshing aliases..."
		unalias -m '*'
		source ${_SYS_ALIASES}
		echo "${CURR_ALIAS_TIME}" > ${STAMP_FILE}
	fi
}

_reload_funcs () {
	local F
	local FILE
	local HOURS

	MODIFIED=("${(f)$(
		find -L ${_SYS_FUNCTIONS} -type f
		find -L ${_CMP_FUNCTIONS} -type f
	)}")

	NOW=$(date +'%s')
	for F in ${MODIFIED};do
		FILE=$(date +'%s' -r ${F}) # Last file mod secs
		HOURS=$(((NOW - FILE)/3600)) # Last file mod hours
		if [[ ${HOURS} -le 24 ]];then # Today?
			echo "Refreshing functions..."
			unfunction ${F} &> /dev/null
			autoload -Uz ${F}
			sudo touch -d '25 hours ago' $(realpath ${F})
		fi
	done
}

_set_ssid () {
	local SSID=$(wless -s)
	local NTWK=$(nut conn)
	local KEY=n

	tput sc
	[[ -n ${SSID} ]] && WIFI=" to ${WHITE_FG}${SSID}${RESET}" && echo ${NTWK}${WIFI}

	if [[ ! ${SSID} =~ ${_WIFI_PREF} ]];then
		echo -n "Change wireless to:${WHITE_FG}${_WIFI_PREF}${RESET} [y]es, [n]o [c]hoose:"
		read -t3 -sk1 KEY # Time out after 3 seconds; default is no
		if [[ ${KEY:l} == "y" ]];then
			tput rc
			tput ed
			wless -n "${_WIFI_PREF}"
		elif [[ ${KEY:l} == "c" ]];then
			C_POS=$(_cursor_row)
			((C_POS--)) # Up 1 line to overwrite prompt
			tput smcup
			wless -cn
			tput rmcup
			SSID=$(wless -s 2>/dev/null)
			[[ -n ${SSID} ]] && WIFI=" to ${WHITE_FG}${SSID}${RESET}"
			tput cup ${C_POS} 0
			tput ed
			echo ${NTWK}${WIFI}
		else
			tput rc
			tput ed
			echo ${NTWK}${WIFI}
		fi
	fi
}

_set_term_header () {
	local -a ALL_TTYS=($(find /dev/pts ! -path /dev/pts  -printf "%f\n" | grep -v ptmx))
	local THIS_TTY=${$(tty):t}
	local MAX=$(terms -c)
	local THIS_TERM=0
	local NDX=0
	local T

	for T in ${(n)ALL_TTYS};do
		((NDX++))
		[[ ${T} -eq ${THIS_TTY} ]] && THIS_TERM=${NDX}
	done

	print -Pn "\e]0;Terminal ${THIS_TERM} of ${MAX}\a"
}

_term_wid () {
	local WID=$(wmctrl -l | grep -i -E 'terminal|zsh' | tr -s '[:space:]' | cut -d' ' -f1)
	[[ -z ${WID} ]] && echo "Unable to obtain WID" >&2 || echo ${WID}
}

_is_top_term () {
	local -a TERMS=()
	local -a TTYS=()
	local TTY=''
	local MIN=0
	local NDX=0
	local CURRENT=''
	local L T

	[[ $(terms -c) -eq 1 ]] && return 0

	TERMS=("${(f)$(terms)}")

	for L in ${TERMS};do
		TTY=''
		case ${L} in
			*session*) SESSIONS=$(tr -s '[:space:]' <<<${L} | cut -d' ' -f1);;
			*pts*)	TTY+=$(tr -s '[:space:]' <<<${L} | cut -d'/' -f2)
						if [[ ${TTY} =~ '\*' ]];then
							CURRENT=$(cut -d' ' -f1 <<<${TTY})
							TTYS+=${CURRENT}
						else
							CURRENT=$(cut -d' ' -f1 <<<${TTY})
							TTYS+=${CURRENT}
						fi
						;;
		esac
	done

	for T in ${(n)TTYS};do
		((NDX++))
		[[ ${T} -lt ${MIN} || ${NDX} -eq 1 ]] && MIN=${T}
	done

	[[ ${CURRENT} == ${MIN} ]] && return 0 || return 1
}

_wifi_on () {
	local R=$(nmcli -c no r | tail -1 | cut -d' ' -f1)

	if [[ ! ${R} =~ "enabled" ]];then
		nmcli radio wifi on
		return 1
	fi
	return 0
}

precmd () {
	local HIT=false
	local LPWD=''
	local P

	if [[ -e /tmp/pwd.last ]];then
		read LPWD < /tmp/pwd.last # Just use ${OLDPWD}?
		/bin/rm -f /tmp/pwd.last >/dev/null 2>&1
	fi

	if [[ ${PWD} != ${LPWD} ]];then
		export PATH=${ORIG_PATH} # Reset path to the original setting

		while read -d: P;do
			[[ ${PWD} == ${P} ]] && HIT=true && break
		done <<<${PATH}

		[[ ${HIT} == 'false' ]] && export PATH=$(pwd):${PATH} # Prepend pwd to path

	fi
	echo ${PWD} > /tmp/pwd.last
	_set_term_header
}

# Execution
[[ -o login ]] && LOGIN=login || LOGIN=''

set -o login # Set as login shell
stty -ixon
umask 002 # Standard
alias sudo='sudo ' # Sudo tweak

# Save options
setopt >~/.cur_setopts
unsetopt >~/.cur_unsetopts

# Completions
fpath=(/home/kmiller/.zsh/completions ${fpath})
autoload -Uz compinit
if [ "$(date +%j)" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
  compinit
else
  compinit -C
fi

# Hooks
add-zsh-hook precmd _reload_funcs # Reload modified functions
add-zsh-hook precmd _reload_aliases # Reload modified aliases
add-zsh-hook precmd _cursor_on

if _is_top_term && [[ -z ${SSH_CLIENT} ]];then
	if [[ -o interactive ]]; then
		wmctrl -i -r $(_term_wid) -b add,maximized_vert,maximized_horz

		tput cup 0 0
		tput ed

		echo "${_REL} (${(C)_RLBL}):${WHITE_FG}${(C)XDG_SESSION_TYPE}${RESET}"

		# Show update status
		_check_updates
		for M in ${_MOTD};do
			echo ${M}
		done

		upd_locate -u # >/dev/null 2>&1 # &|

		# Show/set wifi
		if ! _wifi_on;then
			echo "Wireless was activated"
		fi

		_set_ssid

		echo "Last backup was:${WHITE_FG}$(backup -s)${RESET}" # Show days since last backup 

		C_POS=$(_cursor_row) # Save current row
		tput el1; tput sc # Clear line - save cursor

		echo "Monitoring history..." 
		hist_no_dups -p | tee -a ${_HIST_MSG}

		tput rc; tput ed; tput cup ${C_POS} 0 # Restore cursor - return to saved row
		[[ -n ${_HIST_MSG} ]] && tail -1 ${_HIST_MSG} || echo -n "History checked" # Display last line of output

		tput cup $(( C_POS + 1 )) 0 # Advance row
		tput el1 # Clear line

		EDS=$(dut external -s) # External drive status
		echo ${EDS}

		gd -s # Google Drive status

		[[ ${XDG_SESSION_TYPE:l} == 'x11' ]] && xset r rate 500 33 # Set keyboard repeat delay

		echo "Battery charging limit:${WHITE_FG}${_BATT_LIMIT}%${RESET}"
		/usr/local/bin/system/tweaks/battery_charge_limit ${_BATT_LIMIT} >/dev/null 2>&1 # Set battery charge limit

		echo "Killing ${WHITE_FG}power management for wifi...${RESET}"
		sudo iwconfig wlo1 power off # Turn off power mgt for wifi

		[[ ${CAM_DEFAULT} == 'off' ]] && sut cam off # Kill cam - show status

		C_POS=$(_cursor_row) # Save current row

		# Background dbus monitor - maximize new windows (gnome doesn't track win coords)
		INSTANCE=$(pgrep -c wait_app_start)
		if [[ ${INSTANCE} -eq 0 ]];then
			( nohup wait_app_start & ) >/dev/null 2>&1
		fi

		# Cpu usage warning
		INSTANCE=$(pgrep -c cpu_warn)
		if [[ ${INSTANCE} -eq 0 ]];then
			( nohup /usr/local/bin/system/cpu_warn & ) >/dev/null 2>&1
		fi

		remind # Post any reminders

		# Show calendar
		TERM_LINES=$(tput lines)
		CAL_TOP_ROW=$(( TERM_LINES - _CAL_LINES ))
		tput cup ${CAL_TOP_ROW} 0
		cal_clr

		xdotool mousemove $((1920/2)) $((1080/2)) # Center the cursor

		CNT=$(pgrep -ic enpass)
		if [[ ${CNT} -eq 0 ]];then
			wmctrl -i -a $(_term_wid)
			run_enpass
		else
			tput cup ${C_POS} 0 # Return to saved row
			echo "Enpass is running..."
			tput cup $(tput lines) 0 # Cursor last line
		fi
	fi
else
	wmctrl -i -R $(win_id | cut -d'|' -f1) -b add,maximized_vert,maximized_horz
fi

if [[ $(terms -c) -eq 1 ]];then
	wmctrl -i -a $(_term_wid)
fi
