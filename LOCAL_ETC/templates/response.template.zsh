#!/usr/bin/zsh
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

WHITE_ON_GREY="\033[0m\033[0;1;37;100m"


ALERT="${RED_FG}Warning${RESET}"
DESCRIPTION="ACTION"

[[ ${1} == "-H" ]] && echo "${WHITE_FG}Usage${RESET}:${0}\n ${WHITE_FG}Desc${RESET}:${DESCRIPTION}" && exit

# Yes/No template
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

# File read template
while read -u3 F;do # Separate file descriptor to allow embedded read
	echo "ACTION goes here"
	echo -n "Next..."
	read -s -k1 RESPONSE
	[[ ${RESPONSE} == $'\n' ]] && exit # ANSI quoting to detect empty return
done 3< <FILE>

