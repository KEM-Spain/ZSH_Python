QUESTION="${WHITE_FG}This action is pending${RESET}"
echo -n "${QUESTION}:(y/n)?"
read -k1 RESPONSE;echo
[[ ${RESPONSE} != "y" ]] && exit_leave "${RED_FG}Operation cancelled${RESET}..."
echo "Doing Action"
