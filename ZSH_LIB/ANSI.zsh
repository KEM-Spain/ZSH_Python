# Inline ansi

BOLD="\033[1m"
ITALIC="\033[3m"
RESET="\033[m"
REVERSE="\033[7m"
STRIKE="\033[9m"
UNDER="\033[4m"
BLINK="\033[5m"
BLACK_BG="\033[40m"
BLUE_FG="\033[34m"
CYAN_FG="\033[36m"
GREEN_FG="\033[32m"
MAGENTA_FG="\033[35m"
RED_FG="\033[31m"
WHITE_FG="\033[37m"
YELLOW_FG="\033[33m"
CSR_OFF="\033[?25l"
CSR_ON="\033[?25h"

CYAN_ON_GREY="\033[0m\033[0;1;36;100m"
GREEN_ON_GREY="\033[0m\033[0;1;32;100m"
MAGENTA_ON_GREY="\033[0m\033[0;1;35;100m"
RED_ON_GREY="\033[0m\033[0;1;31;100m"
RED_ON_WHITE="\033[0m\033[0;1;31;107m"
WHITE_ON_GREY="\033[0m\033[0;1;37;100m"
YELLOW_ON_GREY="\033[0m\033[0;1;33;100m"

E_BOLD=$(echo -n "\033[1m")
E_ITALIC=$(echo -n "\033[3m")
E_RESET=$(echo -n "\033[m")
E_REVERSE=$(echo -n "\033[7m")
E_STRIKE=$(echo -n "\033[9m")
E_UNDER=$(echo -n "\033[4m")

E_BLUE_FG=$(echo -n "\033[34m")
E_CYAN_FG=$(echo -n "\033[36m")
E_GREEN_FG=$(echo -n "\033[32m")
E_MAGENTA_FG=$(echo -n "\033[35m")
E_RED_FG=$(echo -n "\033[31m")
E_WHITE_FG=$(echo -n "\033[37m")
E_YELLOW_FG=$(echo -n "\033[33m")

E_BLACK_BG=$(echo -n "\033[40m")
E_BLUE_BG=$(echo -n "\033[44m")
E_CYAN_BG=$(echo -n "\033[46m")
E_GREEN_BG=$(echo -n "\033[42m")
E_MAGENTA_BG=$(echo -n "\033[45m")
E_RED_BG=$(echo -n "\033[41m")
E_WHITE_BG=$(echo -n "\033[47m")
E_YELLOW_BG=$(echo -n "\033[43m")

