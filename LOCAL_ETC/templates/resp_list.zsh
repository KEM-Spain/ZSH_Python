_SIZES=(10 20 30 40)

do_list () {
	local REGEX='^[0-9]+$'
	local SNDX=0
	local S

	for S in ${_SIZES};do
		((SNDX++))
		echo "${WHITE_FG}${SNDX}${RESET}) ${S}"
	done
}

SIZE=''
while true;do
	do_list
	echo -n "Choose size (1..${#_SIZES}) or <ENTER> to ignore:"
	read RESPONSE;echo
	[[ -z ${RESPONSE} ]] && break
	if [[ ${RESPONSE} =~ ${REGEX} && (${RESPONSE} -ge 1 && ${RESPONSE} -le ${#_SIZES}) ]] ; then
		SIZE=${_SIZES[${RESPONSE}]}
		break
	else
		echo "Invalid selection..."
	fi
done
echo "Selected:${RESPONSE}"
