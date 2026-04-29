# y/n response template
QUESTION="${WHITE_FG}This action is pending${RESET}"
echo -n "\n${QUESTION}:(y/n)?"
read -q RESPONSE
echo
if [[ ${RESPONSE} != "y" ]];then # Only 'y' will not exit
	exit_leave "${RED_FG}Operation cancelled${RESET}..."
fi
