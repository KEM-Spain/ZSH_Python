# y/n response template
local ALERT="${RED_FG}Warning${RESET}"
local DESCRIPTION="ACTION"

echo -n "\n${RED_FG}${ALERT}!${RESET} ${DESCRIPTION}${WHITE_FG}${RESET}:(${WHITE_FG}y/n${RESET})?"
read -q RESPONSE
echo
if [[ ${RESPONSE} == "y" ]];then # Only 'y' will execute task
	echo "${WHITE_FG}${DESCRIPTION}${RESET}"
	echo "ACTION goes here"
else # All other keys terminate
	echo "${RED_FG}Operation cancelled${RESET}..."
	exit
fi
