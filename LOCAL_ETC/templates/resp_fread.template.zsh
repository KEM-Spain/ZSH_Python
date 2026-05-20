while read -u3 F;do # Separate file descriptor to allow embedded read
	echo "${F}"
	echo -n "Next..."
	read -s -k1 RESPONSE
	[[ ${RESPONSE} == $'\n' ]] && exit_leave "${RED_FG}Operation cancelled${RESET}..."
done 3< <FILE>
