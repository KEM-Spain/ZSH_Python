# Prevent user inputs from leaking onto the terminal display during a get_keys call
stty -a | grep -qP '\b\-echo\b'
if [[ ${?} -ne 0 ]];then
	stty -echo
	trap 'stty echo' EXIT INT TERM
fi

