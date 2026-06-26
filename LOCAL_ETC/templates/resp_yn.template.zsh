QUERY="Continue?"
echo -n "\n${QUERY}: (y/n)?"
read -sq RESPONSE
if [[ ${RESPONSE} != "y" ]];then
	echo "no\n"
	exit_leave "${RED_FG}Operation cancelled${RESET}"
fi
echo
