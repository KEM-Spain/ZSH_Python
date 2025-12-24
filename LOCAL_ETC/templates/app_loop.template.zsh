item_decorate () {
	local NDX=${1}
	# Add code for any decorations
	echo ${_LIST[${NDX}]}
}

PATHLBL=$(path_get_label 40) 

LOCAL_LIST=("${(f)$(eval "find ${PWD} -maxdepth 1 -type f ! -path ." 2>/dev/null )}")
if ! arr_is_populated "${LOCAL_LIST}";then
	exit_leave $(msg_exit E "LOCAL_LIST was not populated")
fi

# Set headings
list_set_header 'printf "Found:${WHITE_FG}%-d${RESET} Path:${WHITE_FG}%-*s${RESET} Selected:${WHITE_FG}%-d${RESET}  ${_PG}" ${#_LIST} ${#PATHLBL} ${PATHLBL} ${SELECTED_COUNT}'
list_add_header_break

# Set line item
list_set_line_item ' 
printf "${BOLD}${WHITE_FG}%4s${RESET}) ${SHADE}${BAR}%s${RESET}\n" ${_LIST_NDX} "$(item_decorate ${_LIST_NDX})" 
'

list_set_prompt "Hit <${GREEN_FG}SPACE${RESET}> to select ${g_OBJECT}(s) then <${GREEN_FG}ENTER${RESET}> to ${g_ACTION} ${g_OBJECT}(s) (${ITALIC}or exit if none selected${RESET})"

while true;do
	# Get selection
	list_select ${LOCAL_LIST}
	[[ ${?} -eq 0 ]] && break

	# Get selections
	_MARKED=($(list_get_selected))
	
	if [[ $(list_get_selected_count) -ne 0 ]];then
		action_warn
		if [[ ${_MSG_KEY} == "y" ]];then
			action_do
		fi
	fi
done
