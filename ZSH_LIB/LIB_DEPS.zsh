# LIB functions
for D in ${=_DEPS_};do
	if [[ -e ${LIB_DIR}/${D} ]];then
		source ${LIB_DIR}/${D}
	else
		echo "Cannot source:${LIB_DIR}/${D} - not found"
		exit 1
	fi
done
