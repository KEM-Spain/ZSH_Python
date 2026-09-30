# Prevent user inputs from leaking onto the terminal display during a get_keys call
stty -echo
trap 'stty echo' EXIT INT TERM
