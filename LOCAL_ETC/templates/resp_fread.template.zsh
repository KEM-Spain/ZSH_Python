# file read response template
while read -u3 F;do # Separate file descriptor to allow embedded read
	echo "ACTION goes here"
	echo -n "Next..."
	read -s -k1 RESPONSE
	[[ ${RESPONSE} == $'\n' ]] && exit # ANSI quoting to detect empty return
done 3< <FILE>

