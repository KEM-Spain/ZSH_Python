476bbdb 112 commit 476bbdb9b2bed1927c19614c8bd4a2570ac1c922
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Sun Mar 2 13:06:42 2025 +0100

    03-02-2025-13:06:41

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 7c5d650..7d35e8b 100755
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -11,6 +11,7 @@ _DMD="◈"
 typeset -A _CAT_COLS=()
 typeset -A _LIST_DATA=()
 typeset -A _PAGE_TOPS=()
+typeset -A _TAG_DATA=()
 typeset -a _APP_KEYS=()
 typeset -a _LIST=()
 typeset -a _PAGE=()
@@ -25,7 +26,7 @@ _SAVE_MENU_POS=false
 _SEL_KEY=''
 _SEL_VAL=''
 _TAG=''
-_TAG_FILE=''
+_SELECT_TAG_FILE=''
 
 sel_box_center () {
 	local BOX_LEFT=${1};shift # Box Y coord
@@ -240,7 +241,7 @@ sel_list () {
 
 	[[ ${#_LIST} -gt 100 ]] && msg_box -c "<w>Working...<N>"
 
-	[[ -n ${_TAG}  ]] && _TAG_FILE="/tmp/$$.${_TAG}.state" || _TAG_FILE="/tmp/$$.${0}.state"
+	[[ -n ${_TAG}  ]] && _SELECT_TAG_FILE="/tmp/$$.${_TAG}.state" || _SELECT_TAG_FILE="/tmp/$$.${0}.state"
 
 	# If no X,Y coords are passed default to center
 	LIST_W=$(arr_long_elem_len ${_LIST})
@@ -485,23 +486,24 @@ sel_scroll () {
 		fi
 
 		# Handle stored list position
-		if [[ -e ${_TAG_FILE}  ]];then
-			IFS='|' read -r TAG_PAGE TAG_NDX < ${_TAG_FILE} # Retrieve any stored menu positions
-			LAST_TAG=${_TAG_FILE} # Only use position memory for differing menus unless _SAVE_MENU_POS is indicated
-			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: RESTORING MENU POS: _TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
+		sel_get_position
+		if [[ ${_TAG_DATA[RESTORE]} == 'true'  ]];then
+			LAST_TAG=${_SELECT_TAG_FILE} # Only use position memory for differing menus unless _SAVE_MENU_POS is indicated
+			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: RESTORING MENU POS: _SELECT_TAG_FILE:${_SELECT_TAG_FILE}  LAST_TAG:${LAST_TAG}"
 		fi
 
 		NDX=1 # Initialize index
 		if [[ ${PAGE_CHANGE} == 'false' ]];then
-			if [[ ${TAG_NDX} -ne 0 ]];then
+			if [[ ${_TAG_DATA[RESTORE]} == 'true' ]];then
 				if [[ ${_SAVE_MENU_POS} == 'true' ]];then
-					NDX=${TAG_NDX} # Restore menu position regardless
-					PAGE=${TAG_PAGE} # Restore menu position regardless
-					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:RESTORED POSITION: ${NDX}"
+					NDX=${_TAG_DATA[NDX]} # Restore menu position regardless
+					PAGE=${_TAG_DATA[PAGE]} # Restore menu position regardless
+					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:RESTORED POSITION: ${_TAG_DATA[NDX]}"
 				else
-					[[ ${LAST_TAG} != ${_TAG_FILE} ]] && NDX=${TAG_NDX} && PAGE=${TAG_PAGE} # Restore menu position only if menu changed
-					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:MENU CHANGED - RESTORED POSITION: ${NDX}"
+					[[ ${LAST_TAG} != ${_SELECT_TAG_FILE} ]] && NDX=${_TAG_DATA[NDX]} && PAGE=${_TAG_DATA[PAGE]} # Restore menu position only if menu changed
+					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:MENU CHANGED - RESTORED POSITION: ${_TAG_DATA[NDX]}"
 				fi
+				_TAG_DATA[RESTORE]=false
 			fi
 		fi
 
@@ -538,7 +540,7 @@ sel_scroll () {
 			NAV=true # Return only menu selections
 
 			case ${KEY} in
-				0) sel_set_tag ${PAGE} ${NDX}; break 2;;
+				0) sel_set_position ${PAGE} ${NDX}; break 2;;
 				q) exit_request $(sel_set_ebox);break;;
 				27) _SEL_KEY=${KEY} && return -1;;
 				1|u|k) SCROLL="U";;
@@ -673,13 +675,28 @@ sel_set_pages () {
 	echo ${(kv)PAGE_TOPS}
 }
 
-sel_set_tag () {
+sel_set_position () {
 	PAGE=${1}
 	NDX=${2}
 
 	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: NDX:${NDX}"
 
-	[[ -n ${_TAG_FILE} ]] && echo "${PAGE}|${NDX}" >${_TAG_FILE} || dbg "_TAG_FILE not defined" # Save menu position
-	[[ -e ${_TAG_FILE} ]] && dbg "${_TAG_FILE} was created" || dbg "${_TAG_FILE} was NOT created"
+	[[ -n ${_SELECT_TAG_FILE} ]] && echo "${PAGE}|${NDX}" >${_SELECT_TAG_FILE} || dbg "_SELECT_TAG_FILE not defined" # Save menu position
+	[[ -e ${_SELECT_TAG_FILE} ]] && dbg "${_SELECT_TAG_FILE} was created" || dbg "${_SELECT_TAG_FILE} was NOT created"
+}
+
+sel_get_position () {
+	local PAGE=0
+	local NDX=0
+
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
+
+	if [[ -e ${_SELECT_TAG_FILE} ]];then
+		IFS='|' read -r PAGE NDX < ${_SELECT_TAG_FILE} # Retrieve stored position
+		[[ -n ${PAGE} ]] && _TAG_DATA[PAGE]=${PAGE} || _TAG_DATA[PAGE]=''
+		[[ -n ${NDX} ]] && _TAG_DATA[NDX]=${NDX} || _TAG_DATA[NDX]=''
+		[[ -n ${_TAG_DATA[PAGE]} && -n ${_TAG_DATA[NDX]} ]] && _TAG_DATA[RESTORE]=true || _TAG_DATA[RESTORE]=false
+		/bin/rm -f ${_SELECT_TAG_FILE}
+	fi
 }
 
0ff48fc 40 commit 0ff48fca7db045eaa4e6944fab3f12fd4fbd17aa
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Wed Feb 26 21:35:03 2025 +0100

    02-26-2025-21:35:02

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index c0fc3a4..7c5d650 100755
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -238,9 +238,9 @@ sel_list () {
 	done
 	shift $(( OPTIND - 1 ))
 
-	[[ ${#_LIST} -gt 100 ]] && msg_box "<w>Building list...<N>"
+	[[ ${#_LIST} -gt 100 ]] && msg_box -c "<w>Working...<N>"
 
-	[[ -n ${_TAG}  ]] && _TAG_FILE="/tmp/$$.${_TAG}.state"
+	[[ -n ${_TAG}  ]] && _TAG_FILE="/tmp/$$.${_TAG}.state" || _TAG_FILE="/tmp/$$.${0}.state"
 
 	# If no X,Y coords are passed default to center
 	LIST_W=$(arr_long_elem_len ${_LIST})
@@ -488,7 +488,7 @@ sel_scroll () {
 		if [[ -e ${_TAG_FILE}  ]];then
 			IFS='|' read -r TAG_PAGE TAG_NDX < ${_TAG_FILE} # Retrieve any stored menu positions
 			LAST_TAG=${_TAG_FILE} # Only use position memory for differing menus unless _SAVE_MENU_POS is indicated
-			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:_TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
+			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: RESTORING MENU POS: _TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
 		fi
 
 		NDX=1 # Initialize index
@@ -679,6 +679,7 @@ sel_set_tag () {
 
 	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: NDX:${NDX}"
 
-	[[ -n ${_TAG_FILE} ]] && echo "${PAGE}|${NDX}" >${_TAG_FILE} # Save menu position if indicated
+	[[ -n ${_TAG_FILE} ]] && echo "${PAGE}|${NDX}" >${_TAG_FILE} || dbg "_TAG_FILE not defined" # Save menu position
+	[[ -e ${_TAG_FILE} ]] && dbg "${_TAG_FILE} was created" || dbg "${_TAG_FILE} was NOT created"
 }
 
a2a2240 19 commit a2a2240ff53544d503d90cc4e42debd4455a5719
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Sat Feb 22 20:12:21 2025 +0100

    02-22-2025-20:12:20

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index a1e1ed0..c0fc3a4 100755
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -540,7 +540,7 @@ sel_scroll () {
 			case ${KEY} in
 				0) sel_set_tag ${PAGE} ${NDX}; break 2;;
 				q) exit_request $(sel_set_ebox);break;;
-				27) return -1;;
+				27) _SEL_KEY=${KEY} && return -1;;
 				1|u|k) SCROLL="U";;
 				2|d|j) SCROLL="D";;
 				3|t|h) SCROLL="T";;
1179b38 247 commit 1179b38907521a2dd20a46f9ef785b92186ff3cd
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Fri Feb 21 10:50:14 2025 +0100

    02-21-2025-10:50:13

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 8a38f20..a1e1ed0 100755
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -41,28 +41,28 @@ sel_box_center () {
 
 	if validate_is_integer ${TXT};then # Accept either strings or integers
 		TXT_LEN=${TXT}
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: GOT INTEGER FOR TXT_LEN"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: GOT INTEGER FOR TXT_LEN"
 	else
 		TXT_LEN=${#TXT}
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: GOT STRING FOR TXT_LEN"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: GOT STRING FOR TXT_LEN"
 	fi
 
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ARGC:${#@} TXT:${TXT} TXT_LEN:${TXT_LEN}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ARGC:${#@} TXT:${TXT} TXT_LEN:${TXT_LEN}"
 
 	CTR=$(( TXT_LEN / 2 )) && REM=$((TXT_LEN % 2))
 	[[ ${REM} -ne 0 ]] && TXT_CTR=$((CTR+1)) || TXT_CTR=${CTR}
 
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CTR='$(( TXT_LEN / 2 )) && REM=$((CTR % 2))':$(( TXT_LEN / 2 )) && REM:$((CTR % 2))"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CTR='$(( TXT_LEN / 2 )) && REM=$((CTR % 2))':$(( TXT_LEN / 2 )) && REM:$((CTR % 2))"
 
 	CTR=$(( BOX_WIDTH / 2 )) && REM=$((BOX_WIDTH % 2))
 	[[ ${REM} -ne 0 ]] && BOX_CTR=$((CTR+1)) || BOX_CTR=${CTR}
 
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CTR='$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))':$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CTR='$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))':$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))"
 
 	CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))
 
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CTR='$(( BOX_LEFT + BOX_CTR - TXT_CTR ))': $(( BOX_LEFT + BOX_CTR - TXT_CTR ))"
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: BOX_LEFT:${BOX_LEFT} BOX_CTR:${BOX_CTR} TXT_CTR:${TXT_CTR}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CTR='$(( BOX_LEFT + BOX_CTR - TXT_CTR ))': $(( BOX_LEFT + BOX_CTR - TXT_CTR ))"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: BOX_LEFT:${BOX_LEFT} BOX_CTR:${BOX_CTR} TXT_CTR:${TXT_CTR}"
 
 	echo ${CTR}
 }
@@ -81,10 +81,10 @@ sel_clear_region () {
 	R_COORDS=($(box_coords_get REGION))
 
 	if [[ -z ${R_COORDS} ]];then
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: R_COORDS is null - returning"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: R_COORDS is null - returning"
 		return -1
 	else
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: R_COORDS: ${(kv)R_COORDS}"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: R_COORDS: ${(kv)R_COORDS}"
 	fi
 
 	X_ARG=${R_COORDS[X]}
@@ -92,10 +92,10 @@ sel_clear_region () {
 	W_ARG=${R_COORDS[W]}
 	H_ARG=${R_COORDS[H]}
 
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
 
 	if	[[ ${R_COORDS[OB_W]} -ne 0 ]];then
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: HAS OUTER BOX"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: HAS OUTER BOX"
 		((X_ARG-=1))
 		Y_ARG=$(( R_COORDS[OB_Y] - 4 ))
 		W_ARG=$(( R_COORDS[OB_W] + 8 ))
@@ -106,15 +106,15 @@ sel_clear_region () {
 		((W_ARG+=4))
 		((H_ARG+=2))
 	fi
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
 
 	local STR=$(str_rep_char "#" ${W_ARG})
 	for (( R=0; R <= ${H_ARG}; R++ ));do
 		tcup $(( X_ARG + R )) ${Y_ARG};tput ech ${W_ARG}
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${STR}
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${STR} # Show cleared display area in debug
 	done
 
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: Cleared ${H_ARG} rows starting from row:${X_ARG}, col:${Y_ARG} for:${W_ARG} columns"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Cleared ${H_ARG} rows starting from row:${X_ARG}, col:${Y_ARG} for:${W_ARG} columns"
 }
 
 sel_disp_page () {
@@ -141,7 +141,7 @@ sel_hilite () {
 	if [[ ${_HAS_CAT} == 'true' ]];then
 		F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${TEXT})
 		F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${TEXT})
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 		printf "${WHITE_FG}%-*s${RESET} ${_HILITE}%-*s${RESET}
" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
 	else
 		echo ${TEXT}
@@ -244,35 +244,35 @@ sel_list () {
 
 	# If no X,Y coords are passed default to center
 	LIST_W=$(arr_long_elem_len ${_LIST})
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: arr_long_elem_len returned: ${LIST_W}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: arr_long_elem_len returned: ${LIST_W}"
 
 	if [[ ${LIST_W} -gt ${_MAX_COLS} ]];then
 		LIST_W=$(( _MAX_COLS - 20 ))
 		local LONG_EL=$(arr_long_elem ${_LIST})
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: arr_long_elem returned: ${LONG_EL}"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: arr_long_elem returned: ${LONG_EL}"
 	fi
 
 	[[ ${#_LIST} -gt ${_PAGE_MAX_ROWS} ]] && LIST_H=${_PAGE_MAX_ROWS} || LIST_H=${#_LIST}
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: LIST_W:${LIST_W} LIST_H:${LIST_H}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: LIST_W:${LIST_W} LIST_H:${LIST_H}"
 
 	BOX_H=$((LIST_H+2)) # Box height based on list count
 	[[ ${_HAS_CAT} == 'true' ]] && BOX_W=$(( LIST_W + 6 )) || BOX_W=$(( LIST_W + 2 )) # Categories get extra padding
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: INNER BOX SET: BOX_W:${BOX_W} BOX_H:${BOX_H}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: INNER BOX SET: BOX_W:${BOX_W} BOX_H:${BOX_H}"
 
 	[[ ${X_COORD_ARG} -eq 0 ]] && BOX_X=$(coord_center $(( _MAX_ROWS - 1 )) ${BOX_H}) || BOX_X=${X_COORD_ARG}
 	[[ ${Y_COORD_ARG} -eq 0 ]] && BOX_Y=$(coord_center $(( _MAX_COLS - 1 )) ${BOX_W}) || BOX_Y=${Y_COORD_ARG}
 
 	# Set field widths for lists having categories
 	if [[ ${_HAS_CAT} == 'true' ]];then
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CATEGORIES DETECTED"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: CATEGORIES DETECTED"
 		for L in ${_LIST};do
 			F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${L})
 			F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${L})
-			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
+			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 			[[ ${#F1} -gt ${_CAT_COLS[1]} ]] && _CAT_COLS[1]=${#F1}
 			[[ ${#F2} -gt ${_CAT_COLS[2]} ]] && _CAT_COLS[2]=${#F2}
 		done
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SET category field widths: F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: SET category field widths: F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 		case ${_CAT_SORT} in
 			r) _LIST=(${(O)_LIST});; # Descending categories
 			a) _LIST=(${(o)_LIST});; # Ascending categories
@@ -303,11 +303,11 @@ sel_list () {
 
 	# Widest decoration - inner box, header, footer, map, paging, or exit msg
 	MAX=$(max ${BOX_W} ${#NM_H} ${#NM_F} ${MH} ${PH} ${_EXIT_BOX}) # Add padding for MAP
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${#NM_H} LIST_FTR:${#NM_F} LIST_MAP:${MH} PAGE_HDR:${PH} _EXIT_BOX:${_EXIT_BOX}" 
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${#NM_H} LIST_FTR:${#NM_F} LIST_MAP:${MH} PAGE_HDR:${PH} _EXIT_BOX:${_EXIT_BOX}" 
 
 	# Handle outer box coords
 	if [[ ${HAS_OUTER} == 'true' ]];then
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: Setting OUTER BOX coords"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: Setting OUTER BOX coords"
 		OB_X=$(( BOX_X - OB_X_OFFSET ))
 		OB_Y=$(( BOX_Y - OB_Y_OFFSET ))
 		OB_W=$(( BOX_W + OB_Y_OFFSET * 2 ))
@@ -319,7 +319,7 @@ sel_list () {
 			(( OB_W+=DIFF * 2 ))
 		fi
 		MIN=$(min ${OB_X} ${OB_Y} ${OB_W} ${OB_H})
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: OUTER_BOX coords: MIN:${MIN} OB_X:${OB_X}  OB_Y:${OB_Y} OB_W:${OB_W} OB_H:${OB_H}"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: OUTER_BOX coords: MIN:${MIN} OB_X:${OB_X}  OB_Y:${OB_Y} OB_W:${OB_W} OB_H:${OB_H}"
 
 		if [[ ${MIN} -lt 1 ]];then
 			exit_leave "[${WHITE_FG}SELECT.zsh${RESET}] ${RED_FG}OUTER BOX${RESET} would exceed available display. ${CYAN_FG}HINT${RESET}: increase sel_list -y option from ${Y_COORD_ARG} to $(( (MIN * -1) + Y_COORD_ARG + 1 ))"
@@ -404,7 +404,7 @@ sel_load_page () {
 		PAGE=1
 	fi
 	 
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: TOP_ROW:${TOP_ROW}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: TOP_ROW:${TOP_ROW}"
 
 	_PAGE=()
 	for (( NDX=1; NDX <= _LIST_DATA[H]; NDX++ ));do
@@ -412,8 +412,8 @@ sel_load_page () {
 		_PAGE+=${_LIST[$(( NDX + TOP_ROW - 1 ))]}
 		[[ ${NDX} -eq ${#_LIST} ]] && break
 	done
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ADDED NDX ROWS"
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: _LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE} PAGE:${PAGE}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ADDED NDX ROWS"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: _LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE} PAGE:${PAGE}"
 
 	_CURRENT_PAGE=${PAGE} # Set the currently displayed page
 }
@@ -431,7 +431,7 @@ sel_norm () {
 	if [[ ${_HAS_CAT} == 'true' ]];then
 		F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${TEXT})
 		F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${TEXT})
-		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
+		[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 		printf "${WHITE_FG}%-*s${RESET} %-*s
" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
 	else
 		echo ${TEXT}
@@ -488,7 +488,7 @@ sel_scroll () {
 		if [[ -e ${_TAG_FILE}  ]];then
 			IFS='|' read -r TAG_PAGE TAG_NDX < ${_TAG_FILE} # Retrieve any stored menu positions
 			LAST_TAG=${_TAG_FILE} # Only use position memory for differing menus unless _SAVE_MENU_POS is indicated
-			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}:_TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
+			[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:_TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
 		fi
 
 		NDX=1 # Initialize index
@@ -497,10 +497,10 @@ sel_scroll () {
 				if [[ ${_SAVE_MENU_POS} == 'true' ]];then
 					NDX=${TAG_NDX} # Restore menu position regardless
 					PAGE=${TAG_PAGE} # Restore menu position regardless
-					[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}:RESTORED POSITION: ${NDX}"
+					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:RESTORED POSITION: ${NDX}"
 				else
 					[[ ${LAST_TAG} != ${_TAG_FILE} ]] && NDX=${TAG_NDX} && PAGE=${TAG_PAGE} # Restore menu position only if menu changed
-					[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}:MENU CHANGED - RESTORED POSITION: ${NDX}"
+					[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}:MENU CHANGED - RESTORED POSITION: ${NDX}"
 				fi
 			fi
 		fi
@@ -527,10 +527,10 @@ sel_scroll () {
 
 			# Reserved application key breaks from navigation
 			if [[ ${_APP_KEYS[(i)${KEY}]} -le ${#_APP_KEYS} ]];then # App key was pressed
-				[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"
+				[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"
 
 				_SEL_KEY=${KEY} 
-				[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"
+				[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"
 
 				break 2 # Quit navigation
 			fi
@@ -659,14 +659,14 @@ sel_set_pages () {
 	[[ ${REM} -ne 0 ]] && (( PAGE++ ))
 
 	MAX_PAGE=${PAGE} # Page boundary
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: MAX_PAGE:${MAX_PAGE} PAGE:${PAGE}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: MAX_PAGE:${MAX_PAGE} PAGE:${PAGE}"
 
 	for (( P=1; P<=PAGE; P++ ));do
 		[[ ${P} -eq 1 ]] && PG_TOP=1 || PG_TOP=$(( PAGE_TOPS[$(( P-1 ))] + LIST_HEIGHT ))
 		PAGE_TOPS[${P}]=${PG_TOP}
 	done
 
-	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: _PAGE_TOPS:${(kv)PAGE_TOPS}"
+	[[ ${_DEBUG} -ge ${_MID_DETAIL_DBG} ]] && dbg "${0}: _PAGE_TOPS:${(kv)PAGE_TOPS}"
 
 	PAGE_TOPS[MAX]=${MAX_PAGE}
 
399d907 127 commit 399d9071e0c83e94173c93d32acb7883349e110c
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Fri Feb 21 01:15:22 2025 +0100

    02-21-2025-01:15:21

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 68c8d60..8a38f20 100755
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -37,7 +37,7 @@ sel_box_center () {
 	local TXT_CTR=0
 	local TXT_LEN=0
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	if validate_is_integer ${TXT};then # Accept either strings or integers
 		TXT_LEN=${TXT}
@@ -76,7 +76,7 @@ sel_clear_region () {
 	local DIFF=0
 	local R=0
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	R_COORDS=($(box_coords_get REGION))
 
@@ -120,7 +120,7 @@ sel_clear_region () {
 sel_disp_page () {
 	local NDX=0
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"
 
 	for (( NDX=1; NDX <= ${#_PAGE}; NDX++ ));do
 		sel_norm $(( _LIST_DATA[X] + NDX - 1 )) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
@@ -133,7 +133,7 @@ sel_hilite () {
 	local TEXT=${3}
 	local F1 F2
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
 
 	tcup ${X} ${Y}
 
@@ -214,7 +214,7 @@ sel_list () {
 	local _HAS_CAT=false
 	local STR=''
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	while getopts ${OPTSTR} OPTION;do
 		case $OPTION in
@@ -394,7 +394,7 @@ sel_load_page () {
 	local NDX=0
 	local TOP_ROW=1
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
 
 	# Evaluate/validate PAGE arg
 	if [[ -n ${_PAGE_TOPS[${PAGE}]} ]];then
@@ -424,7 +424,7 @@ sel_norm () {
 	local TEXT=${3}
 	local F1 F2
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
 
 	tcup ${X} ${Y}
 	do_rmso
@@ -456,7 +456,7 @@ sel_scroll () {
 	local X_OFF=0
 	local PAGE_CHANGE=false
 	
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	cursor_off
 
@@ -599,7 +599,7 @@ sel_scroll () {
 }
 
 sel_set_app_keys () {
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _APP_KEYS:${_APP_KEYS}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _APP_KEYS:${_APP_KEYS}"
 
 	_APP_KEYS=(${@})
 }
@@ -612,7 +612,7 @@ sel_set_ebox () {
 	local W_ARG=0
 	local DIFF=0
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	# Set coords for exit msg display
 	I_COORDS=($(box_coords_get INNER_BOX))
@@ -637,7 +637,7 @@ sel_set_ebox () {
 sel_set_list () {
 	local -a LIST=(${@})
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	_LIST=(${(o)LIST})
 }
@@ -652,7 +652,7 @@ sel_set_pages () {
 	local REM=0
 	local P
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	PAGE=$(( LIST_MAX / LIST_HEIGHT ))
 	REM=$(( LIST_MAX % LIST_HEIGHT ))
@@ -677,7 +677,7 @@ sel_set_tag () {
 	PAGE=${1}
 	NDX=${2}
 
-	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: NDX:${NDX}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: NDX:${NDX}"
 
 	[[ -n ${_TAG_FILE} ]] && echo "${PAGE}|${NDX}" >${_TAG_FILE} # Save menu position if indicated
 }
30c87b8 388 commit 30c87b89711faec3e1c6e5ac7226417ce52b08a8
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Thu Feb 20 13:17:40 2025 +0100

    02-20-2025-13:17:40

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 6b379e7..68c8d60 100755
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -2,7 +2,6 @@
 _DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh STR.zsh TPUT.zsh ./UTILS.zsh VALIDATE.zsh"
 
 # Constants
-_SEL_LIB_DBG=4
 _EXIT_BOX=32
 _HILITE=${WHITE_ON_GREY}
 _PAGE_MAX_ROWS=$(( _MAX_ROWS - 15 )) # Longest list that fits the available display
@@ -38,34 +37,32 @@ sel_box_center () {
 	local TXT_CTR=0
 	local TXT_LEN=0
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	if validate_is_integer ${TXT};then # Accept either strings or integers
 		TXT_LEN=${TXT}
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: GOT INTEGER FOR TXT_LEN"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: GOT INTEGER FOR TXT_LEN"
 	else
 		TXT_LEN=${#TXT}
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: GOT STRING FOR TXT_LEN"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: GOT STRING FOR TXT_LEN"
 	fi
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TXT:${TXT} TXT_LEN:${TXT_LEN}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ARGC:${#@} TXT:${TXT} TXT_LEN:${TXT_LEN}"
 
 	CTR=$(( TXT_LEN / 2 )) && REM=$((TXT_LEN % 2))
 	[[ ${REM} -ne 0 ]] && TXT_CTR=$((CTR+1)) || TXT_CTR=${CTR}
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( TXT_LEN / 2 )) && REM=$((CTR % 2))'
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} CTR:$(( TXT_LEN / 2 )) && REM:$((CTR % 2))"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CTR='$(( TXT_LEN / 2 )) && REM=$((CTR % 2))':$(( TXT_LEN / 2 )) && REM:$((CTR % 2))"
 
 	CTR=$(( BOX_WIDTH / 2 )) && REM=$((BOX_WIDTH % 2))
 	[[ ${REM} -ne 0 ]] && BOX_CTR=$((CTR+1)) || BOX_CTR=${CTR}
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))'
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} CTR:$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CTR='$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))':$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))"
 
 	CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))'
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} CTR:$(( BOX_LEFT + BOX_CTR - TXT_CTR )) BOX_LEFT:${BOX_LEFT} BOX_CTR:${BOX_CTR} TXT_CTR:${TXT_CTR}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CTR='$(( BOX_LEFT + BOX_CTR - TXT_CTR ))': $(( BOX_LEFT + BOX_CTR - TXT_CTR ))"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: BOX_LEFT:${BOX_LEFT} BOX_CTR:${BOX_CTR} TXT_CTR:${TXT_CTR}"
 
 	echo ${CTR}
 }
@@ -79,15 +76,15 @@ sel_clear_region () {
 	local DIFF=0
 	local R=0
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	R_COORDS=($(box_coords_get REGION))
 
 	if [[ -z ${R_COORDS} ]];then
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: R_COORDS is null - returning"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: R_COORDS is null - returning"
 		return -1
 	else
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: R_COORDS: ${(kv)R_COORDS}"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: R_COORDS: ${(kv)R_COORDS}"
 	fi
 
 	X_ARG=${R_COORDS[X]}
@@ -95,10 +92,10 @@ sel_clear_region () {
 	W_ARG=${R_COORDS[W]}
 	H_ARG=${R_COORDS[H]}
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
 
 	if	[[ ${R_COORDS[OB_W]} -ne 0 ]];then
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: HAS OUTER BOX"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: HAS OUTER BOX"
 		((X_ARG-=1))
 		Y_ARG=$(( R_COORDS[OB_Y] - 4 ))
 		W_ARG=$(( R_COORDS[OB_W] + 8 ))
@@ -109,21 +106,21 @@ sel_clear_region () {
 		((W_ARG+=4))
 		((H_ARG+=2))
 	fi
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
 
 	local STR=$(str_rep_char "#" ${W_ARG})
 	for (( R=0; R <= ${H_ARG}; R++ ));do
 		tcup $(( X_ARG + R )) ${Y_ARG};tput ech ${W_ARG}
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${STR}
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${STR}
 	done
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: Cleared ${H_ARG} rows starting from row:${X_ARG}, col:${Y_ARG} for:${W_ARG} columns"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: Cleared ${H_ARG} rows starting from row:${X_ARG}, col:${Y_ARG} for:${W_ARG} columns"
 }
 
 sel_disp_page () {
 	local NDX=0
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"
 
 	for (( NDX=1; NDX <= ${#_PAGE}; NDX++ ));do
 		sel_norm $(( _LIST_DATA[X] + NDX - 1 )) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
@@ -136,7 +133,7 @@ sel_hilite () {
 	local TEXT=${3}
 	local F1 F2
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
 
 	tcup ${X} ${Y}
 
@@ -144,7 +141,7 @@ sel_hilite () {
 	if [[ ${_HAS_CAT} == 'true' ]];then
 		F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${TEXT})
 		F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${TEXT})
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 		printf "${WHITE_FG}%-*s${RESET} ${_HILITE}%-*s${RESET}
" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
 	else
 		echo ${TEXT}
@@ -217,7 +214,7 @@ sel_list () {
 	local _HAS_CAT=false
 	local STR=''
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	while getopts ${OPTSTR} OPTION;do
 		case $OPTION in
@@ -247,35 +244,35 @@ sel_list () {
 
 	# If no X,Y coords are passed default to center
 	LIST_W=$(arr_long_elem_len ${_LIST})
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: arr_long_elem_len returned: ${LIST_W}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: arr_long_elem_len returned: ${LIST_W}"
 
 	if [[ ${LIST_W} -gt ${_MAX_COLS} ]];then
 		LIST_W=$(( _MAX_COLS - 20 ))
 		local LONG_EL=$(arr_long_elem ${_LIST})
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: arr_long_elem returned: ${LONG_EL}"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: arr_long_elem returned: ${LONG_EL}"
 	fi
 
 	[[ ${#_LIST} -gt ${_PAGE_MAX_ROWS} ]] && LIST_H=${_PAGE_MAX_ROWS} || LIST_H=${#_LIST}
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: LIST_W:${LIST_W} LIST_H:${LIST_H}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: LIST_W:${LIST_W} LIST_H:${LIST_H}"
 
 	BOX_H=$((LIST_H+2)) # Box height based on list count
 	[[ ${_HAS_CAT} == 'true' ]] && BOX_W=$(( LIST_W + 6 )) || BOX_W=$(( LIST_W + 2 )) # Categories get extra padding
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: INNER BOX SET: BOX_W:${BOX_W} BOX_H:${BOX_H}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: INNER BOX SET: BOX_W:${BOX_W} BOX_H:${BOX_H}"
 
 	[[ ${X_COORD_ARG} -eq 0 ]] && BOX_X=$(coord_center $(( _MAX_ROWS - 1 )) ${BOX_H}) || BOX_X=${X_COORD_ARG}
 	[[ ${Y_COORD_ARG} -eq 0 ]] && BOX_Y=$(coord_center $(( _MAX_COLS - 1 )) ${BOX_W}) || BOX_Y=${Y_COORD_ARG}
 
 	# Set field widths for lists having categories
 	if [[ ${_HAS_CAT} == 'true' ]];then
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: CATEGORIES DETECTED"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: CATEGORIES DETECTED"
 		for L in ${_LIST};do
 			F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${L})
 			F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${L})
-			[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
+			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 			[[ ${#F1} -gt ${_CAT_COLS[1]} ]] && _CAT_COLS[1]=${#F1}
 			[[ ${#F2} -gt ${_CAT_COLS[2]} ]] && _CAT_COLS[2]=${#F2}
 		done
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SET category field widths: F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: SET category field widths: F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 		case ${_CAT_SORT} in
 			r) _LIST=(${(O)_LIST});; # Descending categories
 			a) _LIST=(${(o)_LIST});; # Ascending categories
@@ -306,11 +303,11 @@ sel_list () {
 
 	# Widest decoration - inner box, header, footer, map, paging, or exit msg
 	MAX=$(max ${BOX_W} ${#NM_H} ${#NM_F} ${MH} ${PH} ${_EXIT_BOX}) # Add padding for MAP
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${#NM_H} LIST_FTR:${#NM_F} LIST_MAP:${MH} PAGE_HDR:${PH} _EXIT_BOX:${_EXIT_BOX}" 
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${#NM_H} LIST_FTR:${#NM_F} LIST_MAP:${MH} PAGE_HDR:${PH} _EXIT_BOX:${_EXIT_BOX}" 
 
 	# Handle outer box coords
 	if [[ ${HAS_OUTER} == 'true' ]];then
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Setting OUTER BOX coords"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: Setting OUTER BOX coords"
 		OB_X=$(( BOX_X - OB_X_OFFSET ))
 		OB_Y=$(( BOX_Y - OB_Y_OFFSET ))
 		OB_W=$(( BOX_W + OB_Y_OFFSET * 2 ))
@@ -322,7 +319,7 @@ sel_list () {
 			(( OB_W+=DIFF * 2 ))
 		fi
 		MIN=$(min ${OB_X} ${OB_Y} ${OB_W} ${OB_H})
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: OUTER_BOX coords: MIN:${MIN} OB_X:${OB_X}  OB_Y:${OB_Y} OB_W:${OB_W} OB_H:${OB_H}"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: OUTER_BOX coords: MIN:${MIN} OB_X:${OB_X}  OB_Y:${OB_Y} OB_W:${OB_W} OB_H:${OB_H}"
 
 		if [[ ${MIN} -lt 1 ]];then
 			exit_leave "[${WHITE_FG}SELECT.zsh${RESET}] ${RED_FG}OUTER BOX${RESET} would exceed available display. ${CYAN_FG}HINT${RESET}: increase sel_list -y option from ${Y_COORD_ARG} to $(( (MIN * -1) + Y_COORD_ARG + 1 ))"
@@ -397,7 +394,7 @@ sel_load_page () {
 	local NDX=0
 	local TOP_ROW=1
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
 
 	# Evaluate/validate PAGE arg
 	if [[ -n ${_PAGE_TOPS[${PAGE}]} ]];then
@@ -407,7 +404,7 @@ sel_load_page () {
 		PAGE=1
 	fi
 	 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "TOP_ROW:${TOP_ROW}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: TOP_ROW:${TOP_ROW}"
 
 	_PAGE=()
 	for (( NDX=1; NDX <= _LIST_DATA[H]; NDX++ ));do
@@ -415,8 +412,8 @@ sel_load_page () {
 		_PAGE+=${_LIST[$(( NDX + TOP_ROW - 1 ))]}
 		[[ ${NDX} -eq ${#_LIST} ]] && break
 	done
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "ADDED NDX ROWS"
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE} PAGE:${PAGE}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ADDED NDX ROWS"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: _LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE} PAGE:${PAGE}"
 
 	_CURRENT_PAGE=${PAGE} # Set the currently displayed page
 }
@@ -427,14 +424,14 @@ sel_norm () {
 	local TEXT=${3}
 	local F1 F2
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
 
 	tcup ${X} ${Y}
 	do_rmso
 	if [[ ${_HAS_CAT} == 'true' ]];then
 		F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${TEXT})
 		F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${TEXT})
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
+		[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 		printf "${WHITE_FG}%-*s${RESET} %-*s
" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
 	else
 		echo ${TEXT}
@@ -459,7 +456,7 @@ sel_scroll () {
 	local X_OFF=0
 	local PAGE_CHANGE=false
 	
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	cursor_off
 
@@ -491,7 +488,7 @@ sel_scroll () {
 		if [[ -e ${_TAG_FILE}  ]];then
 			IFS='|' read -r TAG_PAGE TAG_NDX < ${_TAG_FILE} # Retrieve any stored menu positions
 			LAST_TAG=${_TAG_FILE} # Only use position memory for differing menus unless _SAVE_MENU_POS is indicated
-			[[ ${_DEBUG} -gt 0 ]] && dbg "_TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
+			[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}:_TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
 		fi
 
 		NDX=1 # Initialize index
@@ -500,10 +497,10 @@ sel_scroll () {
 				if [[ ${_SAVE_MENU_POS} == 'true' ]];then
 					NDX=${TAG_NDX} # Restore menu position regardless
 					PAGE=${TAG_PAGE} # Restore menu position regardless
-					[[ ${_DEBUG} -gt 0 ]] && dbg "RESTORED POSITION: ${NDX}"
+					[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}:RESTORED POSITION: ${NDX}"
 				else
 					[[ ${LAST_TAG} != ${_TAG_FILE} ]] && NDX=${TAG_NDX} && PAGE=${TAG_PAGE} # Restore menu position only if menu changed
-					[[ ${_DEBUG} -gt 0 ]] && dbg "MENU CHANGED - RESTORED POSITION: ${NDX}"
+					[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}:MENU CHANGED - RESTORED POSITION: ${NDX}"
 				fi
 			fi
 		fi
@@ -530,11 +527,10 @@ sel_scroll () {
 
 			# Reserved application key breaks from navigation
 			if [[ ${_APP_KEYS[(i)${KEY}]} -le ${#_APP_KEYS} ]];then # App key was pressed
-				[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"
+				[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"
 
 				_SEL_KEY=${KEY} 
-
-				[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"
+				[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"
 
 				break 2 # Quit navigation
 			fi
@@ -562,23 +558,19 @@ sel_scroll () {
 				[[ ${NDX} -lt 1 ]] && NDX=${#_PAGE}
 				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
-				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'D' ]];then
 				NORM_NDX=${NDX} && ((NDX++))
 				[[ ${NDX} -gt ${#_PAGE} ]] && NDX=1
 				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
-				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'T' ]];then
 				NORM_NDX=${NDX} && NDX=1
 				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
-				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'B' ]];then
 				NORM_NDX=${NDX} && NDX=${#_PAGE}
 				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
-				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'N' ]];then
 				((PAGE++))
 				PAGE_CHANGE=true
@@ -607,7 +599,7 @@ sel_scroll () {
 }
 
 sel_set_app_keys () {
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _APP_KEYS:${_APP_KEYS}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _APP_KEYS:${_APP_KEYS}"
 
 	_APP_KEYS=(${@})
 }
@@ -620,7 +612,7 @@ sel_set_ebox () {
 	local W_ARG=0
 	local DIFF=0
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	# Set coords for exit msg display
 	I_COORDS=($(box_coords_get INNER_BOX))
@@ -645,7 +637,7 @@ sel_set_ebox () {
 sel_set_list () {
 	local -a LIST=(${@})
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	_LIST=(${(o)LIST})
 }
@@ -660,21 +652,21 @@ sel_set_pages () {
 	local REM=0
 	local P
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	PAGE=$(( LIST_MAX / LIST_HEIGHT ))
 	REM=$(( LIST_MAX % LIST_HEIGHT ))
 	[[ ${REM} -ne 0 ]] && (( PAGE++ ))
 
 	MAX_PAGE=${PAGE} # Page boundary
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: MAX_PAGE:${MAX_PAGE} PAGE:${PAGE}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: MAX_PAGE:${MAX_PAGE} PAGE:${PAGE}"
 
 	for (( P=1; P<=PAGE; P++ ));do
 		[[ ${P} -eq 1 ]] && PG_TOP=1 || PG_TOP=$(( PAGE_TOPS[$(( P-1 ))] + LIST_HEIGHT ))
 		PAGE_TOPS[${P}]=${PG_TOP}
 	done
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_PAGE_TOPS:${(kv)PAGE_TOPS}"
+	[[ ${_DEBUG} -ge ${_MID_DBG} ]] && dbg "${0}: _PAGE_TOPS:${(kv)PAGE_TOPS}"
 
 	PAGE_TOPS[MAX]=${MAX_PAGE}
 
@@ -685,7 +677,7 @@ sel_set_tag () {
 	PAGE=${1}
 	NDX=${2}
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: NDX:${NDX}"
+	[[ ${_DEBUG} -ge ${_LOW_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: NDX:${NDX}"
 
 	[[ -n ${_TAG_FILE} ]] && echo "${PAGE}|${NDX}" >${_TAG_FILE} # Save menu position if indicated
 }
b9599db 19 commit b9599db5e940085c211f6299510100ecd96b430d
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Tue Feb 18 23:25:26 2025 +0100

    02-18-2025-23:25:25

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 5f85fb7..6b379e7 100755
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -647,7 +647,7 @@ sel_set_list () {
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
-	_LIST=(${LIST})
+	_LIST=(${(o)LIST})
 }
 
 sel_set_pages () {
3d4827d 25 commit 3d4827d8b3a6060d5a312337b9e63295c44038bb
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Tue Feb 18 10:42:58 2025 +0100

    02-18-2025-10:42:57

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index d5f7bb4..5f85fb7 100755
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -247,6 +247,14 @@ sel_list () {
 
 	# If no X,Y coords are passed default to center
 	LIST_W=$(arr_long_elem_len ${_LIST})
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: arr_long_elem_len returned: ${LIST_W}"
+
+	if [[ ${LIST_W} -gt ${_MAX_COLS} ]];then
+		LIST_W=$(( _MAX_COLS - 20 ))
+		local LONG_EL=$(arr_long_elem ${_LIST})
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: arr_long_elem returned: ${LONG_EL}"
+	fi
+
 	[[ ${#_LIST} -gt ${_PAGE_MAX_ROWS} ]] && LIST_H=${_PAGE_MAX_ROWS} || LIST_H=${#_LIST}
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: LIST_W:${LIST_W} LIST_H:${LIST_H}"
 
ebf3cf0 9 commit ebf3cf04e05ae8d3fd365ed3ae34e651e264a850
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Sun Feb 16 15:59:49 2025 +0100

    02-16-2025-15:59:49

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
old mode 100644
new mode 100755
29e852e 170 commit 29e852e48bad37f486913598d9fa834ec87df283
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Sun Feb 16 15:57:10 2025 +0100

    02-16-2025-15:57:10

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index a959cdd..d5f7bb4 100644
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -18,7 +18,9 @@ typeset -a _PAGE=()
 
 # LIB Vars
 _CURRENT_PAGE=0
+_CAT_DELIM=':'
 _HAS_CAT=false
+_CAT_SORT=r
 _HILITE_X=0
 _SAVE_MENU_POS=false
 _SEL_KEY=''
@@ -140,8 +142,9 @@ sel_hilite () {
 
 	do_smso
 	if [[ ${_HAS_CAT} == 'true' ]];then
-		F1=$(cut -d: -f1 <<<${TEXT})
-		F2=$(cut -d: -f2 <<<${TEXT})
+		F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${TEXT})
+		F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${TEXT})
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 		printf "${WHITE_FG}%-*s${RESET} ${_HILITE}%-*s${RESET}
" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
 	else
 		echo ${TEXT}
@@ -191,14 +194,14 @@ sel_list () {
 	local L
 
 	local OPTION=''
-	local OPTSTR=":F:H:I:M:O:T:W:x:y:SCc"
+	local OPTSTR=":F:H:I:M:O:T:W:d:s:x:y:SCc"
 	OPTIND=0
 
 	local CLEAR_REGION=false
 	local HAS_FTR=false
 	local HAS_HDR=false
 	local HAS_MAP=false
-	local HAS_OB=false
+	local HAS_OUTER=false
 	local IB_COLOR=${RESET}
 	local LIST_FTR=''
 	local LIST_HDR=''
@@ -223,11 +226,13 @@ sel_list () {
 		H) HAS_HDR=true;LIST_HDR=${OPTARG};;
 	   I) IB_COLOR=${OPTARG};;
 		M) HAS_MAP=true;LIST_MAP=${OPTARG};;
-	   O) HAS_OB=true;OB_COLOR=${OPTARG};;
+	   O) HAS_OUTER=true;OB_COLOR=${OPTARG};;
 		S) _SAVE_MENU_POS=true;;
 	   T) _TAG=${OPTARG};;
 	   W) OB_PAD=${OPTARG};;
 	   c) CLEAR_REGION=true;;
+	   d) _CAT_DELIM=${OPTARG};;
+	   s) _CAT_SORT=${OPTARG};;
 	   x) X_COORD_ARG=${OPTARG};;
 	   y) Y_COORD_ARG=${OPTARG};;
 	   :) exit_leave "${RED_FG}${0}${RESET}: option: -${OPTARG} requires an argument";;
@@ -236,6 +241,8 @@ sel_list () {
 	done
 	shift $(( OPTIND - 1 ))
 
+	[[ ${#_LIST} -gt 100 ]] && msg_box "<w>Building list...<N>"
+
 	[[ -n ${_TAG}  ]] && _TAG_FILE="/tmp/$$.${_TAG}.state"
 
 	# If no X,Y coords are passed default to center
@@ -254,13 +261,18 @@ sel_list () {
 	if [[ ${_HAS_CAT} == 'true' ]];then
 		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: CATEGORIES DETECTED"
 		for L in ${_LIST};do
-			F1=$(cut -d: -f1 <<<${L})
-			F2=$(cut -d: -f2 <<<${L})
+			F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${L})
+			F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${L})
+			[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 			[[ ${#F1} -gt ${_CAT_COLS[1]} ]] && _CAT_COLS[1]=${#F1}
 			[[ ${#F2} -gt ${_CAT_COLS[2]} ]] && _CAT_COLS[2]=${#F2}
 		done
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SET category field widths: F1:${F1} F2:${F2}"
-		_LIST=(${(o)_LIST}) # Sort categories
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SET category field widths: F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
+		case ${_CAT_SORT} in
+			r) _LIST=(${(O)_LIST});; # Descending categories
+			a) _LIST=(${(o)_LIST});; # Ascending categories
+			n) _LIST=(${_LIST});; # No sorting of categories
+		esac
 	else
 		_CAT_COLS=()
 	fi
@@ -279,7 +291,7 @@ sel_list () {
 
 	MH=${#NM_M} # Set default MAP width
 	[[ ${PAGING} == 'true' ]] && PH=${#NM_P} # Set default PAGING width
-	if [[ ${HAS_OB} == 'true' ]];then
+	if [[ ${HAS_OUTER} == 'true' ]];then
 		((MH+=6)) # Add padding for MAP
 		[[ ${PAGING} == 'true' ]] && ((PH+=4)) # Add padding for PAGING
 	fi
@@ -289,7 +301,7 @@ sel_list () {
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${#NM_H} LIST_FTR:${#NM_F} LIST_MAP:${MH} PAGE_HDR:${PH} _EXIT_BOX:${_EXIT_BOX}" 
 
 	# Handle outer box coords
-	if [[ ${HAS_OB} == 'true' ]];then
+	if [[ ${HAS_OUTER} == 'true' ]];then
 		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Setting OUTER BOX coords"
 		OB_X=$(( BOX_X - OB_X_OFFSET ))
 		OB_Y=$(( BOX_Y - OB_Y_OFFSET ))
@@ -310,12 +322,12 @@ sel_list () {
 	fi
 
 	# Store OUTER_BOX coords
-	box_coords_set OUTER_BOX HAS_OB ${HAS_OB} X ${OB_X} Y ${OB_Y} W ${OB_W} H ${OB_H} COLOR ${OB_COLOR}
+	box_coords_set OUTER_BOX HAS_OUTER ${HAS_OUTER} X ${OB_X} Y ${OB_Y} W ${OB_W} H ${OB_H} COLOR ${OB_COLOR}
 
 	BOX_BOT=$(( BOX_X + BOX_H)) # Store coordinate
 
 	# Set coords for list decorations
-	if [[ ${HAS_OB} == 'true' ]];then
+	if [[ ${HAS_OUTER} == 'true' ]];then
 		HDR_X=$(( BOX_X - 3 ))
 		HDR_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) ${NM_H})
 		MAP_X=${BOX_BOT}
@@ -367,6 +379,8 @@ sel_list () {
 	_LIST_DATA[X]=${LIST_X}
 	_LIST_DATA[Y]=${LIST_Y}
 
+	msg_box_clear
+
 	sel_scroll 1 # Display list page 1 and handle user inputs
 }
 
@@ -410,8 +424,9 @@ sel_norm () {
 	tcup ${X} ${Y}
 	do_rmso
 	if [[ ${_HAS_CAT} == 'true' ]];then
-		F1=$(cut -d: -f1 <<<${TEXT})
-		F2=$(cut -d: -f2 <<<${TEXT})
+		F1=$(cut -d"${_CAT_DELIM}" -f1 <<<${TEXT})
+		F2=$(cut -d"${_CAT_DELIM}" -f2 <<<${TEXT})
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} PARSED TEXT:${TEXT} TO F1:${F1} F2:${F2} DELIM:${_CAT_DELIM}"
 		printf "${WHITE_FG}%-*s${RESET} %-*s
" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
 	else
 		echo ${TEXT}
@@ -448,7 +463,7 @@ sel_scroll () {
 
 	while true;do
 		# Display decorations
-		[[ ${O_COORDS[HAS_OB]} == 'true' ]] && msg_unicode_box ${O_COORDS[X]} ${O_COORDS[Y]} ${O_COORDS[W]} ${O_COORDS[H]} ${O_COORDS[COLOR]}
+		[[ ${O_COORDS[HAS_OUTER]} == 'true' ]] && msg_unicode_box ${O_COORDS[X]} ${O_COORDS[Y]} ${O_COORDS[W]} ${O_COORDS[H]} ${O_COORDS[COLOR]}
 		msg_unicode_box ${I_COORDS[X]} ${I_COORDS[Y]} ${I_COORDS[W]} ${I_COORDS[H]} ${I_COORDS[COLOR]}
 
 		# Display list decorations
@@ -610,6 +625,10 @@ sel_set_ebox () {
 	elif [[ ${MSG_LEN} -gt ${I_COORDS[W]}  ]];then
 		DIFF=$(( (MSG_LEN - I_COORDS[W]) / 2 ))
 		Y_ARG=$(( I_COORDS[Y] - DIFF ))
+	else
+		X_ARG=$(( I_COORDS[X] + 2 ))
+		Y_ARG=$(( I_COORDS[Y] + 2 ))
+		W_ARG=$(( I_COORDS[W] - 2 ))
 	fi
 
 	echo ${X_ARG} ${Y_ARG} ${W_ARG} 
b95b844 42 commit b95b8444f6da1c2d5408c6822b02f505c2519f1f
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Fri Jan 24 11:28:51 2025 +0100

    01-24-2025-11:28:50

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 5de8649..a959cdd 100644
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -204,7 +204,9 @@ sel_list () {
 	local LIST_HDR=''
 	local LIST_MAP=''
 	local LM=0
+	local MAX=0
 	local MAX_PAGE=0
+	local MIN=0
 	local OB_COLOR=${RESET}
 	local OB_PAD=0
 	local X_COORD_ARG=0
@@ -288,7 +290,7 @@ sel_list () {
 
 	# Handle outer box coords
 	if [[ ${HAS_OB} == 'true' ]];then
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: OUTER BOX DETECTED"
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: Setting OUTER BOX coords"
 		OB_X=$(( BOX_X - OB_X_OFFSET ))
 		OB_Y=$(( BOX_Y - OB_Y_OFFSET ))
 		OB_W=$(( BOX_W + OB_Y_OFFSET * 2 ))
@@ -299,6 +301,12 @@ sel_list () {
 			(( OB_Y-=DIFF ))
 			(( OB_W+=DIFF * 2 ))
 		fi
+		MIN=$(min ${OB_X} ${OB_Y} ${OB_W} ${OB_H})
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: OUTER_BOX coords: MIN:${MIN} OB_X:${OB_X}  OB_Y:${OB_Y} OB_W:${OB_W} OB_H:${OB_H}"
+
+		if [[ ${MIN} -lt 1 ]];then
+			exit_leave "[${WHITE_FG}SELECT.zsh${RESET}] ${RED_FG}OUTER BOX${RESET} would exceed available display. ${CYAN_FG}HINT${RESET}: increase sel_list -y option from ${Y_COORD_ARG} to $(( (MIN * -1) + Y_COORD_ARG + 1 ))"
+		fi
 	fi
 
 	# Store OUTER_BOX coords
01bb120 392 commit 01bb1209355fff4ad64baf2e8daf15912e0429e5
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Thu Jan 23 15:12:42 2025 +0100

    01-23-2025-15:12:41

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 703ba2e..5de8649 100644
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -20,6 +20,7 @@ typeset -a _PAGE=()
 _CURRENT_PAGE=0
 _HAS_CAT=false
 _HILITE_X=0
+_SAVE_MENU_POS=false
 _SEL_KEY=''
 _SEL_VAL=''
 _TAG=''
@@ -29,11 +30,11 @@ sel_box_center () {
 	local BOX_LEFT=${1};shift # Box Y coord
 	local BOX_WIDTH=${1};shift # Box W coord
 	local TXT=${@} # Text to center
-	local TXT_LEN=0
 	local BOX_CTR=0
 	local CTR=0
 	local REM=0
 	local TXT_CTR=0
+	local TXT_LEN=0
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
@@ -67,6 +68,66 @@ sel_box_center () {
 	echo ${CTR}
 }
 
+sel_clear_region () {
+	local -A R_COORDS
+	local X_ARG=0
+	local Y_ARG=0
+	local W_ARG=0
+	local H_ARG=0
+	local DIFF=0
+	local R=0
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+
+	R_COORDS=($(box_coords_get REGION))
+
+	if [[ -z ${R_COORDS} ]];then
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: R_COORDS is null - returning"
+		return -1
+	else
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: R_COORDS: ${(kv)R_COORDS}"
+	fi
+
+	X_ARG=${R_COORDS[X]}
+	Y_ARG=${R_COORDS[Y]}
+	W_ARG=${R_COORDS[W]}
+	H_ARG=${R_COORDS[H]}
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
+
+	if	[[ ${R_COORDS[OB_W]} -ne 0 ]];then
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: HAS OUTER BOX"
+		((X_ARG-=1))
+		Y_ARG=$(( R_COORDS[OB_Y] - 4 ))
+		W_ARG=$(( R_COORDS[OB_W] + 8 ))
+		((H_ARG+=5))
+	else
+		((X_ARG-=1))
+		((Y_ARG-=2))
+		((W_ARG+=4))
+		((H_ARG+=2))
+	fi
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
+
+	local STR=$(str_rep_char "#" ${W_ARG})
+	for (( R=0; R <= ${H_ARG}; R++ ));do
+		tcup $(( X_ARG + R )) ${Y_ARG};tput ech ${W_ARG}
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${STR}
+	done
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: Cleared ${H_ARG} rows starting from row:${X_ARG}, col:${Y_ARG} for:${W_ARG} columns"
+}
+
+sel_disp_page () {
+	local NDX=0
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"
+
+	for (( NDX=1; NDX <= ${#_PAGE}; NDX++ ));do
+		sel_norm $(( _LIST_DATA[X] + NDX - 1 )) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+	done
+}
+
 sel_hilite () {
 	local X=${1}
 	local Y=${2}
@@ -130,7 +191,7 @@ sel_list () {
 	local L
 
 	local OPTION=''
-	local OPTSTR=":CF:H:I:M:O:T:W:x:y:c"
+	local OPTSTR=":F:H:I:M:O:T:W:x:y:SCc"
 	OPTIND=0
 
 	local CLEAR_REGION=false
@@ -161,6 +222,7 @@ sel_list () {
 	   I) IB_COLOR=${OPTARG};;
 		M) HAS_MAP=true;LIST_MAP=${OPTARG};;
 	   O) HAS_OB=true;OB_COLOR=${OPTARG};;
+		S) _SAVE_MENU_POS=true;;
 	   T) _TAG=${OPTARG};;
 	   W) OB_PAD=${OPTARG};;
 	   c) CLEAR_REGION=true;;
@@ -203,7 +265,7 @@ sel_list () {
 
 	_PAGE_TOPS=($(sel_set_pages ${#_LIST} ${LIST_H})) # Create table of page top indexes
 
-	PAGE_HDR="Page <w>${_PAGE_TOPS[MAX]}<N> of <w>${_PAGE_TOPS[MAX]}<N> ${_DMD} (<w>N<N>)ext (<w>P<N>)rev"
+	PAGE_HDR="Page <w>${_PAGE_TOPS[MAX]}<N> of <w>${_PAGE_TOPS[MAX]}<N> ${_DMD} (<w>N<N>)ext (<w>P<N>)rev" # Create paging template
 
 	# Decorations w/o markup
 	NM_H=$(msg_nomarkup ${LIST_HDR})
@@ -216,8 +278,8 @@ sel_list () {
 	MH=${#NM_M} # Set default MAP width
 	[[ ${PAGING} == 'true' ]] && PH=${#NM_P} # Set default PAGING width
 	if [[ ${HAS_OB} == 'true' ]];then
-		((MH+=6)) # Add padding for MAP if OUTER_BOX
-		[[ ${PAGING} == 'true' ]] && ((PH+=4)) # Add padding for PAGING if OUTER_BOX
+		((MH+=6)) # Add padding for MAP
+		[[ ${PAGING} == 'true' ]] && ((PH+=4)) # Add padding for PAGING
 	fi
 
 	# Widest decoration - inner box, header, footer, map, paging, or exit msg
@@ -268,6 +330,7 @@ sel_list () {
 	# Store DECOR coords
 	box_coords_set DECOR HAS_HDR ${HAS_HDR} HDR_X ${HDR_X} HDR_Y ${HDR_Y} HAS_MAP ${HAS_MAP} MAP_X ${MAP_X} MAP_Y ${MAP_Y} HAS_FTR ${HAS_FTR} FTR_X ${FTR_X} FTR_Y ${FTR_Y}
 
+	# Set coords for region clearing
 	local R_H=$(max $(( FTR_X - BOX_X )) $(( MAP_X - BOX_X )) $(( PGH_X - BOX_X )) ${BOX_H}) 
 	local R_Y=$(min ${HDR_Y} ${MAP_Y} ${FTR_Y} ${PGH_Y} ${BOX_Y})
 	local R_W=$(max ${#LIST_HDR} ${#LIST_MAP} ${#LIST_FTR} ${#PAGE_HDR} ${BOX_W})
@@ -296,7 +359,36 @@ sel_list () {
 	_LIST_DATA[X]=${LIST_X}
 	_LIST_DATA[Y]=${LIST_Y}
 
-	sel_scroll 1 # Display list and handle user inputs
+	sel_scroll 1 # Display list page 1 and handle user inputs
+}
+
+sel_load_page () {
+	local PAGE=${1}
+	local NDX=0
+	local TOP_ROW=1
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
+
+	# Evaluate/validate PAGE arg
+	if [[ -n ${_PAGE_TOPS[${PAGE}]} ]];then
+		TOP_ROW=${_PAGE_TOPS[${PAGE}]}
+	else
+		TOP_ROW=1
+		PAGE=1
+	fi
+	 
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "TOP_ROW:${TOP_ROW}"
+
+	_PAGE=()
+	for (( NDX=1; NDX <= _LIST_DATA[H]; NDX++ ));do
+		[[ -z ${_LIST[$(( NDX + TOP_ROW - 1 ))]} ]] && continue # No blank rows
+		_PAGE+=${_LIST[$(( NDX + TOP_ROW - 1 ))]}
+		[[ ${NDX} -eq ${#_LIST} ]] && break
+	done
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "ADDED NDX ROWS"
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE} PAGE:${PAGE}"
+
+	_CURRENT_PAGE=${PAGE} # Set the currently displayed page
 }
 
 sel_norm () {
@@ -331,8 +423,10 @@ sel_scroll () {
 	local NDX=0
 	local NORM_NDX=0
 	local SCROLL=''
+	local TAG_PAGE=0
 	local TAG_NDX=0
 	local X_OFF=0
+	local PAGE_CHANGE=false
 	
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
@@ -362,27 +456,43 @@ sel_scroll () {
 			tcup ${D_COORDS[MAP_X]} ${D_COORDS[MAP_Y]};echo $(msg_markup ${_LIST_DATA[MAP]})
 		fi
 
+		# Handle stored list position
+		if [[ -e ${_TAG_FILE}  ]];then
+			IFS='|' read -r TAG_PAGE TAG_NDX < ${_TAG_FILE} # Retrieve any stored menu positions
+			LAST_TAG=${_TAG_FILE} # Only use position memory for differing menus unless _SAVE_MENU_POS is indicated
+			[[ ${_DEBUG} -gt 0 ]] && dbg "_TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
+		fi
+
+		NDX=1 # Initialize index
+		if [[ ${PAGE_CHANGE} == 'false' ]];then
+			if [[ ${TAG_NDX} -ne 0 ]];then
+				if [[ ${_SAVE_MENU_POS} == 'true' ]];then
+					NDX=${TAG_NDX} # Restore menu position regardless
+					PAGE=${TAG_PAGE} # Restore menu position regardless
+					[[ ${_DEBUG} -gt 0 ]] && dbg "RESTORED POSITION: ${NDX}"
+				else
+					[[ ${LAST_TAG} != ${_TAG_FILE} ]] && NDX=${TAG_NDX} && PAGE=${TAG_PAGE} # Restore menu position only if menu changed
+					[[ ${_DEBUG} -gt 0 ]] && dbg "MENU CHANGED - RESTORED POSITION: ${NDX}"
+				fi
+			fi
+		fi
+
+		# Populate current page array 
 		sel_load_page ${PAGE} # Sets _CURRENT_PAGE
 		PAGE=${_CURRENT_PAGE}
 
+		# Add header for paging
 		if [[ ${_LIST_DATA[PAGING]} == 'true' ]];then
 			tcup ${_LIST_DATA[PGH_X]} ${_LIST_DATA[PGH_Y]};echo -n $(msg_markup "Page <w>${PAGE}<N> of <w>${_PAGE_TOPS[MAX]}<N> <m>${_DMD}<N> (<w>N<N>)ext (<w>P<N>)rev")
 		fi
 
 		sel_disp_page # Display list items
 
-		if [[ -e ${_TAG_FILE}  ]];then
-			read TAG_NDX < ${_TAG_FILE} # Retrieve any stored menu positions
-			LAST_TAG=${_TAG_FILE} # Only use position memory for differing menus
-		fi
-
-		[[ ${_DEBUG} -gt 0 ]] && dbg "_TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
-
-		[[ ${TAG_NDX} -ne 0 && ${LAST_TAG} != ${_TAG_FILE} ]] && NDX=${TAG_NDX} || NDX=1 # Initialize index
 		_SEL_VAL=${_PAGE[${NDX}]} # Initialize return value
 
 		sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]} # Initial item hilite
 
+		# Get user inputs
 		while true;do
 			KEY=$(get_keys)
 			_SEL_KEY='?'
@@ -401,7 +511,7 @@ sel_scroll () {
 			NAV=true # Return only menu selections
 
 			case ${KEY} in
-				0) break 2;;
+				0) sel_set_tag ${PAGE} ${NDX}; break 2;;
 				q) exit_request $(sel_set_ebox);break;;
 				27) return -1;;
 				1|u|k) SCROLL="U";;
@@ -440,22 +550,25 @@ sel_scroll () {
 				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'N' ]];then
 				((PAGE++))
+				PAGE_CHANGE=true
 				break
 			elif [[ ${SCROLL} == 'P' ]];then
 				[[ ${PAGE} -eq 1 ]] && PAGE=${_PAGE_TOPS[MAX]} || ((PAGE--))
+				PAGE_CHANGE=true
 				break
 			elif [[ ${SCROLL} == 'H' ]];then
 				PAGE=1
+				PAGE_CHANGE=true
 				break
 			elif [[ ${SCROLL} == 'L' ]];then
 				PAGE=${_PAGE_TOPS[MAX]}
+				PAGE_CHANGE=true
 				break
 			fi
 
 			if [[ ${NAV} == 'true' ]];then # Set key pressed and item selected
 				_SEL_KEY=${KEY}
 				_SEL_VAL=${_PAGE[${NDX}]}
-				[[ -n ${_TAG_FILE} ]] && echo "${NDX}" >${_TAG_FILE} # Save menu position if indicated
 			fi
 		done
 	done
@@ -478,6 +591,7 @@ sel_set_ebox () {
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
+	# Set coords for exit msg display
 	I_COORDS=($(box_coords_get INNER_BOX))
 	X_ARG=$(( I_COORDS[X] + 1 ))
 	Y_ARG=$(( I_COORDS[Y] - 2 ))
@@ -501,56 +615,6 @@ sel_set_list () {
 	_LIST=(${LIST})
 }
 
-sel_clear_region () {
-	local -A R_COORDS
-	local X_ARG=0
-	local Y_ARG=0
-	local W_ARG=0
-	local H_ARG=0
-	local DIFF=0
-	local R=0
-
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
-
-	R_COORDS=($(box_coords_get REGION))
-
-	if [[ -z ${R_COORDS} ]];then
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: R_COORDS is null - returning"
-		return -1
-	else
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: R_COORDS: ${(kv)R_COORDS}"
-	fi
-
-	X_ARG=${R_COORDS[X]}
-	Y_ARG=${R_COORDS[Y]}
-	W_ARG=${R_COORDS[W]}
-	H_ARG=${R_COORDS[H]}
-
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
-
-	if	[[ ${R_COORDS[OB_W]} -ne 0 ]];then
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: HAS OUTER BOX"
-		((X_ARG-=1))
-		Y_ARG=$(( R_COORDS[OB_Y] - 4 ))
-		W_ARG=$(( R_COORDS[OB_W] + 8 ))
-		((H_ARG+=5))
-	else
-		((X_ARG-=1))
-		((Y_ARG-=2))
-		((W_ARG+=4))
-		((H_ARG+=2))
-	fi
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
-
-	local STR=$(str_rep_char "#" ${W_ARG})
-	for (( R=0; R <= ${H_ARG}; R++ ));do
-		tcup $(( X_ARG + R )) ${Y_ARG};tput ech ${W_ARG}
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${STR}
-	done
-
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: Cleared ${H_ARG} rows starting from row:${X_ARG}, col:${Y_ARG} for:${W_ARG} columns"
-}
-
 sel_set_pages () {
 	local LIST_MAX=${1}
 	local LIST_HEIGHT=${2}
@@ -582,41 +646,12 @@ sel_set_pages () {
 	echo ${(kv)PAGE_TOPS}
 }
 
-sel_load_page () {
-	local PAGE=${1}
-	local NDX=0
-	local TOP_ROW=1
-
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
-
-	# Evaluate/validate PAGE arg
-	if [[ -n ${_PAGE_TOPS[${PAGE}]} ]];then
-		TOP_ROW=${_PAGE_TOPS[${PAGE}]}
-	else
-		TOP_ROW=1
-		PAGE=1
-	fi
-	 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "TOP_ROW:${TOP_ROW}"
+sel_set_tag () {
+	PAGE=${1}
+	NDX=${2}
 
-	_PAGE=()
-	for (( NDX=1; NDX <= _LIST_DATA[H]; NDX++ ));do
-		[[ -z ${_LIST[$(( NDX + TOP_ROW - 1 ))]} ]] && continue # No blank rows
-		_PAGE+=${_LIST[$(( NDX + TOP_ROW - 1 ))]}
-		[[ ${NDX} -eq ${#_LIST} ]] && break
-	done
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "ADDED NDX ROWS"
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE} PAGE:${PAGE}"
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: NDX:${NDX}"
 
-	_CURRENT_PAGE=${PAGE} # Set the currently displayed page
+	[[ -n ${_TAG_FILE} ]] && echo "${PAGE}|${NDX}" >${_TAG_FILE} # Save menu position if indicated
 }
 
-sel_disp_page () {
-	local NDX=0
-
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"
-
-	for (( NDX=1; NDX <= ${#_PAGE}; NDX++ ));do
-		sel_norm $(( _LIST_DATA[X] + NDX - 1 )) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
-	done
-}
2f5c0ad 77 commit 2f5c0add575082bbe633d5603ddfc050e44bc78a
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Wed Jan 22 16:07:27 2025 +0100

    01-22-2025-16:07:27

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 4a585a6..703ba2e 100644
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -211,9 +211,7 @@ sel_list () {
 	NM_M=$(msg_nomarkup ${LIST_MAP})
 	NM_P=$(msg_nomarkup ${PAGE_HDR})
 
-	if [[ ${_PAGE_TOPS[MAX]} -gt 1 ]];then
-		PAGING=true
-	fi
+	[[ ${_PAGE_TOPS[MAX]} -gt 1 ]] && PAGING=true
 
 	MH=${#NM_M} # Set default MAP width
 	[[ ${PAGING} == 'true' ]] && PH=${#NM_P} # Set default PAGING width
@@ -327,6 +325,7 @@ sel_scroll () {
 	local -A O_COORDS=($(box_coords_get OUTER_BOX))
 	local BOT_X=0
 	local KEY=''
+	local LAST_TAG=?
 	local LIST_X=0
 	local NAV=''
 	local NDX=0
@@ -334,7 +333,6 @@ sel_scroll () {
 	local SCROLL=''
 	local TAG_NDX=0
 	local X_OFF=0
-	local LAST_TAG=?
 	
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
@@ -375,7 +373,7 @@ sel_scroll () {
 
 		if [[ -e ${_TAG_FILE}  ]];then
 			read TAG_NDX < ${_TAG_FILE} # Retrieve any stored menu positions
-			LAST_TAG=${_TAG_FILE}
+			LAST_TAG=${_TAG_FILE} # Only use position memory for differing menus
 		fi
 
 		[[ ${_DEBUG} -gt 0 ]] && dbg "_TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
@@ -412,6 +410,8 @@ sel_scroll () {
 				4|b|l) SCROLL="B";;
 				5|p) SCROLL="P";;
 				6|n) SCROLL="N";;
+				7|H) SCROLL="H";;
+				8|L) SCROLL="L";;
 				*) NAV=false;;
 			esac
 
@@ -434,7 +434,7 @@ sel_scroll () {
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
 				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'B' ]];then
-				NORM_NDX=${NDX} && NDX=${_LIST_DATA[H]}
+				NORM_NDX=${NDX} && NDX=${#_PAGE}
 				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
 				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
@@ -444,6 +444,12 @@ sel_scroll () {
 			elif [[ ${SCROLL} == 'P' ]];then
 				[[ ${PAGE} -eq 1 ]] && PAGE=${_PAGE_TOPS[MAX]} || ((PAGE--))
 				break
+			elif [[ ${SCROLL} == 'H' ]];then
+				PAGE=1
+				break
+			elif [[ ${SCROLL} == 'L' ]];then
+				PAGE=${_PAGE_TOPS[MAX]}
+				break
 			fi
 
 			if [[ ${NAV} == 'true' ]];then # Set key pressed and item selected
692e5fa 434 commit 692e5fa02ffb81fda9cc3101606fdef25de5f100
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Wed Jan 22 12:36:34 2025 +0100

    01-22-2025-12:36:33

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 0417d36..4a585a6 100644
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -6,6 +6,7 @@ _SEL_LIB_DBG=4
 _EXIT_BOX=32
 _HILITE=${WHITE_ON_GREY}
 _PAGE_MAX_ROWS=$(( _MAX_ROWS - 15 )) # Longest list that fits the available display
+_DMD="◈"
 
 # LIB Declarations
 typeset -A _CAT_COLS=()
@@ -19,7 +20,6 @@ typeset -a _PAGE=()
 _CURRENT_PAGE=0
 _HAS_CAT=false
 _HILITE_X=0
-_MAX_PAGE=0
 _SEL_KEY=''
 _SEL_VAL=''
 _TAG=''
@@ -110,6 +110,14 @@ sel_list () {
 	local LIST_Y=0
 	local MAP_X=0
 	local MAP_Y=0
+	local MH=0
+	local NM_H=''
+	local NM_F=''
+	local NM_M=''
+	local NM_P=''
+	local PGH_X=0
+	local PGH_Y=0
+	local PH=0
 	local MAX=0
 	local OB_H=0
 	local OB_W=0
@@ -117,6 +125,8 @@ sel_list () {
 	local OB_X_OFFSET=2
 	local OB_Y=0
 	local OB_Y_OFFSET=4
+	local PAGING=false
+	local PAGE_HDR=''
 	local L
 
 	local OPTION=''
@@ -129,12 +139,11 @@ sel_list () {
 	local HAS_MAP=false
 	local HAS_OB=false
 	local IB_COLOR=${RESET}
-	local LF=0
-	local LH=0
 	local LIST_FTR=''
 	local LIST_HDR=''
 	local LIST_MAP=''
 	local LM=0
+	local MAX_PAGE=0
 	local OB_COLOR=${RESET}
 	local OB_PAD=0
 	local X_COORD_ARG=0
@@ -147,10 +156,10 @@ sel_list () {
 	while getopts ${OPTSTR} OPTION;do
 		case $OPTION in
 	   C) _HAS_CAT=true;;
-		F) HAS_FTR=true;LIST_FTR=${OPTARG};STR=$(msg_nomarkup ${LIST_FTR});LF=${#STR};;
-		H) HAS_HDR=true;LIST_HDR=${OPTARG};STR=$(msg_nomarkup ${LIST_HDR});LH=${#STR};;
+		F) HAS_FTR=true;LIST_FTR=${OPTARG};;
+		H) HAS_HDR=true;LIST_HDR=${OPTARG};;
 	   I) IB_COLOR=${OPTARG};;
-		M) HAS_MAP=true;LIST_MAP=${OPTARG};STR=$(msg_nomarkup ${LIST_MAP});LM=${#STR};;
+		M) HAS_MAP=true;LIST_MAP=${OPTARG};;
 	   O) HAS_OB=true;OB_COLOR=${OPTARG};;
 	   T) _TAG=${OPTARG};;
 	   W) OB_PAD=${OPTARG};;
@@ -192,12 +201,30 @@ sel_list () {
 		_CAT_COLS=()
 	fi
 
-	BOX_BOT=$(( BOX_X + BOX_H)) # Store coordinate
+	_PAGE_TOPS=($(sel_set_pages ${#_LIST} ${LIST_H})) # Create table of page top indexes
+
+	PAGE_HDR="Page <w>${_PAGE_TOPS[MAX]}<N> of <w>${_PAGE_TOPS[MAX]}<N> ${_DMD} (<w>N<N>)ext (<w>P<N>)rev"
+
+	# Decorations w/o markup
+	NM_H=$(msg_nomarkup ${LIST_HDR})
+	NM_F=$(msg_nomarkup ${LIST_FTR})
+	NM_M=$(msg_nomarkup ${LIST_MAP})
+	NM_P=$(msg_nomarkup ${PAGE_HDR})
+
+	if [[ ${_PAGE_TOPS[MAX]} -gt 1 ]];then
+		PAGING=true
+	fi
+
+	MH=${#NM_M} # Set default MAP width
+	[[ ${PAGING} == 'true' ]] && PH=${#NM_P} # Set default PAGING width
+	if [[ ${HAS_OB} == 'true' ]];then
+		((MH+=6)) # Add padding for MAP if OUTER_BOX
+		[[ ${PAGING} == 'true' ]] && ((PH+=4)) # Add padding for PAGING if OUTER_BOX
+	fi
 
-	# Widest decoration - inner box, header, footer, map, or exit msg
-	((LM+=6)) #Add MAP padding inside outer box
-	MAX=$(max ${BOX_W} ${LH} ${LF} ${LM} ${_EXIT_BOX}) 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${LH} LIST_FTR:${LF} LIST_MAP:${LM} _EXIT_BOX:${_EXIT_BOX}" 
+	# Widest decoration - inner box, header, footer, map, paging, or exit msg
+	MAX=$(max ${BOX_W} ${#NM_H} ${#NM_F} ${MH} ${PH} ${_EXIT_BOX}) # Add padding for MAP
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${#NM_H} LIST_FTR:${#NM_F} LIST_MAP:${MH} PAGE_HDR:${PH} _EXIT_BOX:${_EXIT_BOX}" 
 
 	# Handle outer box coords
 	if [[ ${HAS_OB} == 'true' ]];then
@@ -217,29 +244,35 @@ sel_list () {
 	# Store OUTER_BOX coords
 	box_coords_set OUTER_BOX HAS_OB ${HAS_OB} X ${OB_X} Y ${OB_Y} W ${OB_W} H ${OB_H} COLOR ${OB_COLOR}
 
+	BOX_BOT=$(( BOX_X + BOX_H)) # Store coordinate
+
 	# Set coords for list decorations
 	if [[ ${HAS_OB} == 'true' ]];then
 		HDR_X=$(( BOX_X - 3 ))
-		HDR_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_HDR}))
+		HDR_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) ${NM_H})
 		MAP_X=${BOX_BOT}
-		MAP_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_MAP}))
+		MAP_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) ${NM_M})
 		FTR_X=$(( BOX_BOT + 2 ))
-		FTR_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_FTR}))
+		FTR_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) ${NM_F})
+		PGH_X=$(( BOX_X - 1 ))
+		PGH_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) ${NM_P})
 	else
 		HDR_X=$(( BOX_X - 1 ))
-		HDR_Y=$(sel_box_center ${BOX_Y} ${BOX_W} $(msg_nomarkup ${LIST_HDR}))
-		MAP_X=${BOX_BOT}
-		MAP_Y=$(sel_box_center ${BOX_Y} ${BOX_W} $(msg_nomarkup ${LIST_MAP}))
-		[[ -n ${LIST_MAP} ]] && FTR_X=$(( BOX_BOT + 1 )) || FTR_X=${BOX_BOT}
-		FTR_Y=$(sel_box_center ${BOX_Y} ${BOX_W} $(msg_nomarkup ${LIST_FTR}))
+		HDR_Y=$(sel_box_center ${BOX_Y} ${BOX_W} ${NM_H})
+		[[ -n ${PAGE_HDR} ]] && MAP_X=$(( BOX_BOT + 1 )) || MAP_X=${BOX_BOT} # Move map down if blocked
+		MAP_Y=$(sel_box_center ${BOX_Y} ${BOX_W} ${NM_M})
+		[[ -n ${LIST_MAP} || -n ${PAGE_HDR} ]] && FTR_X=$(( MAP_X + 1 )) || FTR_X=${BOX_BOT} # Move footer down if blocked
+		FTR_Y=$(sel_box_center ${BOX_Y} ${BOX_W} ${NM_F})
+		PGH_X=${BOX_BOT}
+		PGH_Y=$(sel_box_center ${BOX_Y} ${BOX_W} ${NM_P})
 	fi
 
 	# Store DECOR coords
 	box_coords_set DECOR HAS_HDR ${HAS_HDR} HDR_X ${HDR_X} HDR_Y ${HDR_Y} HAS_MAP ${HAS_MAP} MAP_X ${MAP_X} MAP_Y ${MAP_Y} HAS_FTR ${HAS_FTR} FTR_X ${FTR_X} FTR_Y ${FTR_Y}
 
-	local R_H=$(( $(max $(( FTR_X - BOX_X )) $(( MAP_X - BOX_X )) ${BOX_H}) + 1))
-	local R_Y=$(min ${HDR_Y} ${MAP_Y} ${FTR_Y} ${BOX_Y})
-	local R_W=$(max ${#LIST_HDR} ${#LIST_MAP} ${#LIST_FTR} ${BOX_W})
+	local R_H=$(max $(( FTR_X - BOX_X )) $(( MAP_X - BOX_X )) $(( PGH_X - BOX_X )) ${BOX_H}) 
+	local R_Y=$(min ${HDR_Y} ${MAP_Y} ${FTR_Y} ${PGH_Y} ${BOX_Y})
+	local R_W=$(max ${#LIST_HDR} ${#LIST_MAP} ${#LIST_FTR} ${#PAGE_HDR} ${BOX_W})
 
 	# Store REGION clearing coords
 	box_coords_set REGION X ${HDR_X} Y ${R_Y} W ${R_W} H ${R_H} OB_W ${OB_W} OB_Y ${OB_Y} # For display region clearing if needed
@@ -252,18 +285,19 @@ sel_list () {
 	LIST_Y=$(( BOX_Y + 1 ))
 
 	# Save data for future reference
+	_LIST_DATA[BOX_W]=${BOX_W}
+	_LIST_DATA[BOX_Y]=${BOX_Y}
+	_LIST_DATA[CLEAR_REGION]=${CLEAR_REGION}
 	_LIST_DATA[FTR]=${LIST_FTR}
 	_LIST_DATA[HDR]=${LIST_HDR}
+	_LIST_DATA[H]=${LIST_H}
 	_LIST_DATA[MAP]=${LIST_MAP}
+	_LIST_DATA[PAGING]=${PAGING}
+	_LIST_DATA[PGH_X]=${PGH_X}
+	_LIST_DATA[PGH_Y]=${PGH_Y}
 	_LIST_DATA[X]=${LIST_X}
 	_LIST_DATA[Y]=${LIST_Y}
-	_LIST_DATA[H]=${LIST_H}
-	_LIST_DATA[BOX_W]=${BOX_W}
-	_LIST_DATA[BOX_Y]=${BOX_Y}
-	_LIST_DATA[MAX]=${#_LIST}
-	_LIST_DATA[CLEAR_REGION]=${CLEAR_REGION}
 
-	sel_set_pages # Create table of page top indexes
 	sel_scroll 1 # Display list and handle user inputs
 }
 
@@ -288,29 +322,25 @@ sel_norm () {
 
 sel_scroll () {
 	local PAGE=${1}
+	local -A D_COORDS=($(box_coords_get DECOR))
+	local -A I_COORDS=($(box_coords_get INNER_BOX))
+	local -A O_COORDS=($(box_coords_get OUTER_BOX))
 	local BOT_X=0
 	local KEY=''
+	local LIST_X=0
 	local NAV=''
 	local NDX=0
 	local NORM_NDX=0
 	local SCROLL=''
 	local TAG_NDX=0
 	local X_OFF=0
-	local PAGING=''
-	local PAGING_INFO=''
-	local MAP_INFO=''
-	local PGR_X=0
-	local PGR_Y=0
-	local MAP_X=0
-	local MAP_Y=0
-	local -A I_COORDS=($(box_coords_get INNER_BOX))
-	local -A O_COORDS=($(box_coords_get OUTER_BOX))
-	local -A D_COORDS=($(box_coords_get DECOR))
+	local LAST_TAG=?
 	
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	cursor_off
-	[[ ${_LIST_DATA[CLEAR_REGION]} == 'true' ]] && clear_region # Clear space around list if indicated
+
+	[[ ${_LIST_DATA[CLEAR_REGION]} == 'true' ]] && sel_clear_region # Clear space around list if indicated
 
 	LIST_X=${_LIST_DATA[X]} # First row
 	BOT_X=$(( _LIST_DATA[X] + _LIST_DATA[H] - 1 )) # Last row
@@ -326,50 +356,37 @@ sel_scroll () {
 			tcup ${D_COORDS[HDR_X]} ${D_COORDS[HDR_Y]};echo $(msg_markup ${_LIST_DATA[HDR]})
 		fi
 
-		if [[ ${D_COORDS[HAS_MAP]} == 'true' ]];then
-			tcup ${D_COORDS[MAP_X]} ${D_COORDS[MAP_Y]};echo $(msg_markup ${_LIST_DATA[MAP]})
-		fi
-
 		if [[ ${D_COORDS[HAS_FTR]} == 'true' ]];then
 			tcup ${D_COORDS[FTR_X]} ${D_COORDS[FTR_Y]};echo $(msg_markup ${_LIST_DATA[FTR]})
 		fi
 
-		# Display list items
+		if [[ ${D_COORDS[HAS_MAP]} == 'true' ]];then
+			tcup ${D_COORDS[MAP_X]} ${D_COORDS[MAP_Y]};echo $(msg_markup ${_LIST_DATA[MAP]})
+		fi
+
 		sel_load_page ${PAGE} # Sets _CURRENT_PAGE
 		PAGE=${_CURRENT_PAGE}
 
-		# Display paging information if multiple pages detected
-		if [[ ${_MAX_PAGE} -gt 1 ]];then
-			[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: PAGING_INFO:${PAGING_INFO} MAP_INFO:${MAP_INFO}"
-
-			if [[ ${O_COORDS[HAS_OB]} == 'true' ]];then
-				PAGING_INFO="<w>Page<N> <w>${_CURRENT_PAGE}<N> of <w>${_MAX_PAGE}<N>"
-				MAP_INFO="(<w>N<N>)ext page (<w>P<N>)revious page"
-				PGR_X=$(( _LIST_DATA[X] - 2 ))
-				PGR_Y=$(sel_box_center ${_LIST_DATA[BOX_Y]} ${_LIST_DATA[BOX_W]} $(msg_nomarkup ${PAGING_INFO}))
-				tcup ${PGR_X} ${PGR_Y};echo $(msg_markup ${PAGING_INFO})
-			else
-				MAP_INFO="Page<N> <w>${_CURRENT_PAGE}<N> of <w>${_MAX_PAGE}<N> - (<w>N<N>)ext page (<w>P<N>)revious page <w>"
-			fi
-			MAP_Y=$(sel_box_center ${_LIST_DATA[BOX_Y]} ${_LIST_DATA[BOX_W]} $(msg_nomarkup ${MAP_INFO}))
-			tcup ${D_COORDS[MAP_X]} ${MAP_Y};echo $(msg_markup ${MAP_INFO})
-			box_coords_upd REGION X ${PGR_X} Y ${PGR_Y}
+		if [[ ${_LIST_DATA[PAGING]} == 'true' ]];then
+			tcup ${_LIST_DATA[PGH_X]} ${_LIST_DATA[PGH_Y]};echo -n $(msg_markup "Page <w>${PAGE}<N> of <w>${_PAGE_TOPS[MAX]}<N> <m>${_DMD}<N> (<w>N<N>)ext (<w>P<N>)rev")
 		fi
 
 		sel_disp_page # Display list items
 
 		if [[ -e ${_TAG_FILE}  ]];then
 			read TAG_NDX < ${_TAG_FILE} # Retrieve any stored menu positions
+			LAST_TAG=${_TAG_FILE}
 		fi
 
-		[[ ${TAG_NDX} -ne 0 ]] && NDX=${TAG_NDX} || NDX=1 # Initialize index
+		[[ ${_DEBUG} -gt 0 ]] && dbg "_TAG_FILE:${_TAG_FILE}  LAST_TAG:${LAST_TAG}"
+
+		[[ ${TAG_NDX} -ne 0 && ${LAST_TAG} != ${_TAG_FILE} ]] && NDX=${TAG_NDX} || NDX=1 # Initialize index
 		_SEL_VAL=${_PAGE[${NDX}]} # Initialize return value
 
 		sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]} # Initial item hilite
 
 		while true;do
 			KEY=$(get_keys)
-
 			_SEL_KEY='?'
 
 			# Reserved application key breaks from navigation
@@ -384,7 +401,6 @@ sel_scroll () {
 			fi
 
 			NAV=true # Return only menu selections
-			PAGING=''
 
 			case ${KEY} in
 				0) break 2;;
@@ -399,29 +415,34 @@ sel_scroll () {
 				*) NAV=false;;
 			esac
 
+			# Handle navigation
 			if [[ ${SCROLL} == 'U' ]];then
 				NORM_NDX=${NDX} && ((NDX--))
-				[[ ${NDX} -lt 1 ]] && NDX=${_LIST_DATA[H]}
+				[[ ${NDX} -lt 1 ]] && NDX=${#_PAGE}
 				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'D' ]];then
 				NORM_NDX=${NDX} && ((NDX++))
-				[[ ${NDX} -gt ${_LIST_DATA[H]} ]] && NDX=1
+				[[ ${NDX} -gt ${#_PAGE} ]] && NDX=1
 				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'T' ]];then
 				NORM_NDX=${NDX} && NDX=1
 				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'B' ]];then
 				NORM_NDX=${NDX} && NDX=${_LIST_DATA[H]}
 				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
 				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+				# [[ ${_DEBUG} -gt 0 ]] && dbg "SCROLL:${SCROLL} NDX:${NDX} NORM_NDX:${NORM_NDX} _LIST_DATA[H]:${_LIST_DATA[H]} _PAGE[NORM_NDX]:${_PAGE[${NORM_NDX}]} _PAGE[NDX]:${_PAGE[${NDX}]} #_PAGE:${#_PAGE}"
 			elif [[ ${SCROLL} == 'N' ]];then
 				((PAGE++))
 				break
 			elif [[ ${SCROLL} == 'P' ]];then
-				[[ ${_CURRENT_PAGE} -eq 1 ]] && PAGE=${_MAX_PAGE} || ((PAGE--))
+				[[ ${PAGE} -eq 1 ]] && PAGE=${_PAGE_TOPS[MAX]} || ((PAGE--))
 				break
 			fi
 
@@ -474,7 +495,7 @@ sel_set_list () {
 	_LIST=(${LIST})
 }
 
-clear_region () {
+sel_clear_region () {
 	local -A R_COORDS
 	local X_ARG=0
 	local Y_ARG=0
@@ -490,6 +511,8 @@ clear_region () {
 	if [[ -z ${R_COORDS} ]];then
 		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: R_COORDS is null - returning"
 		return -1
+	else
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: R_COORDS: ${(kv)R_COORDS}"
 	fi
 
 	X_ARG=${R_COORDS[X]}
@@ -501,17 +524,17 @@ clear_region () {
 
 	if	[[ ${R_COORDS[OB_W]} -ne 0 ]];then
 		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: HAS OUTER BOX"
-		X_ARG=$(( R_COORDS[X] - 2 ))
+		((X_ARG-=1))
 		Y_ARG=$(( R_COORDS[OB_Y] - 4 ))
 		W_ARG=$(( R_COORDS[OB_W] + 8 ))
-		H_ARG=$(( H_ARG + 3 ))
+		((H_ARG+=5))
 	else
-		((X_ARG-=2))
+		((X_ARG-=1))
 		((Y_ARG-=2))
 		((W_ARG+=4))
 		((H_ARG+=2))
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
 	fi
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
 
 	local STR=$(str_rep_char "#" ${W_ARG})
 	for (( R=0; R <= ${H_ARG}; R++ ));do
@@ -523,27 +546,34 @@ clear_region () {
 }
 
 sel_set_pages () {
-	local REM
+	local LIST_MAX=${1}
+	local LIST_HEIGHT=${2}
+	local MAX_PAGE=0
+	local -A PAGE_TOPS=()
+	local PAGE=0
+	local PG_TOP=0
+	local REM=0
 	local P
-	local PAGE
-	local PG_TOP
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
-	PAGE=$(( _LIST_DATA[MAX] / _LIST_DATA[H] ))
-	REM=$(( _LIST_DATA[MAX] % _LIST_DATA[H] ))
+	PAGE=$(( LIST_MAX / LIST_HEIGHT ))
+	REM=$(( LIST_MAX % LIST_HEIGHT ))
 	[[ ${REM} -ne 0 ]] && (( PAGE++ ))
 
-	_MAX_PAGE=${PAGE} # Page boundary
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: _MAX_PAGE:${_MAX_PAGE} PAGE:${PAGE}"
+	MAX_PAGE=${PAGE} # Page boundary
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: MAX_PAGE:${MAX_PAGE} PAGE:${PAGE}"
 
-	_PAGE_TOPS=()
 	for (( P=1; P<=PAGE; P++ ));do
-		[[ ${P} -eq 1 ]] && PG_TOP=1 || PG_TOP=$(( _PAGE_TOPS[$(( P-1 ))] + _LIST_DATA[H] ))
-		_PAGE_TOPS[${P}]=${PG_TOP}
+		[[ ${P} -eq 1 ]] && PG_TOP=1 || PG_TOP=$(( PAGE_TOPS[$(( P-1 ))] + LIST_HEIGHT ))
+		PAGE_TOPS[${P}]=${PG_TOP}
 	done
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_PAGE_TOPS:${(kv)_PAGE_TOPS}"
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_PAGE_TOPS:${(kv)PAGE_TOPS}"
+
+	PAGE_TOPS[MAX]=${MAX_PAGE}
+
+	echo ${(kv)PAGE_TOPS}
 }
 
 sel_load_page () {
@@ -567,14 +597,12 @@ sel_load_page () {
 	for (( NDX=1; NDX <= _LIST_DATA[H]; NDX++ ));do
 		[[ -z ${_LIST[$(( NDX + TOP_ROW - 1 ))]} ]] && continue # No blank rows
 		_PAGE+=${_LIST[$(( NDX + TOP_ROW - 1 ))]}
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "ADDED ROW:${_LIST[$(( NDX + TOP_ROW - 1 ))]}"
 		[[ ${NDX} -eq ${#_LIST} ]] && break
 	done
-
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE}"
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "ADDED NDX ROWS"
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE} PAGE:${PAGE}"
 
 	_CURRENT_PAGE=${PAGE} # Set the currently displayed page
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "SET: _CURRENT_PAGE:${_CURRENT_PAGE}"
 }
 
 sel_disp_page () {
3921151 205 commit 392115191c41ce34e24b78de49716a0797529c31
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Tue Jan 21 01:39:07 2025 +0100

    01-21-2025-01:39:06

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 52a799c..0417d36 100644
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -1,6 +1,12 @@
 # LIB Dependencies
 _DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh STR.zsh TPUT.zsh ./UTILS.zsh VALIDATE.zsh"
 
+# Constants
+_SEL_LIB_DBG=4
+_EXIT_BOX=32
+_HILITE=${WHITE_ON_GREY}
+_PAGE_MAX_ROWS=$(( _MAX_ROWS - 15 )) # Longest list that fits the available display
+
 # LIB Declarations
 typeset -A _CAT_COLS=()
 typeset -A _LIST_DATA=()
@@ -11,14 +17,10 @@ typeset -a _PAGE=()
 
 # LIB Vars
 _CURRENT_PAGE=0
-_EXIT_BOX=32
 _HAS_CAT=false
-_HILITE=${WHITE_ON_GREY}
 _HILITE_X=0
 _MAX_PAGE=0
-_PAGE_MAX_ROWS=$(( _MAX_ROWS - 15 )) # Longest list that fits the available display
 _SEL_KEY=''
-_SEL_LIB_DBG=4
 _SEL_VAL=''
 _TAG=''
 _TAG_FILE=''
@@ -166,25 +168,25 @@ sel_list () {
 	# If no X,Y coords are passed default to center
 	LIST_W=$(arr_long_elem_len ${_LIST})
 	[[ ${#_LIST} -gt ${_PAGE_MAX_ROWS} ]] && LIST_H=${_PAGE_MAX_ROWS} || LIST_H=${#_LIST}
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: LIST_W:${LIST_W} LIST_H:${LIST_H}"
 
-	BOX_H=$((LIST_H+2))
-	[[ ${X_COORD_ARG} -eq 0 ]] && BOX_X=$(coord_center $(( _MAX_ROWS - 1 )) ${BOX_H}) || BOX_X=${X_COORD_ARG}
+	BOX_H=$((LIST_H+2)) # Box height based on list count
+	[[ ${_HAS_CAT} == 'true' ]] && BOX_W=$(( LIST_W + 6 )) || BOX_W=$(( LIST_W + 2 )) # Categories get extra padding
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: INNER BOX SET: BOX_W:${BOX_W} BOX_H:${BOX_H}"
 
-	[[ ${_HAS_CAT} == 'true' ]] && BOX_W=$(( LIST_W + 6 )) || BOX_W=$(( LIST_W + 2 ))
+	[[ ${X_COORD_ARG} -eq 0 ]] && BOX_X=$(coord_center $(( _MAX_ROWS - 1 )) ${BOX_H}) || BOX_X=${X_COORD_ARG}
 	[[ ${Y_COORD_ARG} -eq 0 ]] && BOX_Y=$(coord_center $(( _MAX_COLS - 1 )) ${BOX_W}) || BOX_Y=${Y_COORD_ARG}
 
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: LIST_W:${LIST_W} LIST_H:${LIST_H}"
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: INNER BOX - BOX_W:${BOX_W} BOX_H:${BOX_H}"
-
 	# Set field widths for lists having categories
 	if [[ ${_HAS_CAT} == 'true' ]];then
-		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _HAS_CAT:${_HAS_CAT}"
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: CATEGORIES DETECTED"
 		for L in ${_LIST};do
 			F1=$(cut -d: -f1 <<<${L})
 			F2=$(cut -d: -f2 <<<${L})
 			[[ ${#F1} -gt ${_CAT_COLS[1]} ]] && _CAT_COLS[1]=${#F1}
 			[[ ${#F2} -gt ${_CAT_COLS[2]} ]] && _CAT_COLS[2]=${#F2}
 		done
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: SET category field widths: F1:${F1} F2:${F2}"
 		_LIST=(${(o)_LIST}) # Sort categories
 	else
 		_CAT_COLS=()
@@ -192,12 +194,12 @@ sel_list () {
 
 	BOX_BOT=$(( BOX_X + BOX_H)) # Store coordinate
 
-	# Widest element - inner box, header, footer, map, or exit msg
+	# Widest decoration - inner box, header, footer, map, or exit msg
 	((LM+=6)) #Add MAP padding inside outer box
 	MAX=$(max ${BOX_W} ${LH} ${LF} ${LM} ${_EXIT_BOX}) 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${LH} LIST_FTR:${LF} LIST_MAP:${LM} _EXIT_BOX:${_EXIT_BOX}" 
 
-	# Handle outer box
+	# Handle outer box coords
 	if [[ ${HAS_OB} == 'true' ]];then
 		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: OUTER BOX DETECTED"
 		OB_X=$(( BOX_X - OB_X_OFFSET ))
@@ -212,6 +214,7 @@ sel_list () {
 		fi
 	fi
 
+	# Store OUTER_BOX coords
 	box_coords_set OUTER_BOX HAS_OB ${HAS_OB} X ${OB_X} Y ${OB_Y} W ${OB_W} H ${OB_H} COLOR ${OB_COLOR}
 
 	# Set coords for list decorations
@@ -231,15 +234,17 @@ sel_list () {
 		FTR_Y=$(sel_box_center ${BOX_Y} ${BOX_W} $(msg_nomarkup ${LIST_FTR}))
 	fi
 
+	# Store DECOR coords
 	box_coords_set DECOR HAS_HDR ${HAS_HDR} HDR_X ${HDR_X} HDR_Y ${HDR_Y} HAS_MAP ${HAS_MAP} MAP_X ${MAP_X} MAP_Y ${MAP_Y} HAS_FTR ${HAS_FTR} FTR_X ${FTR_X} FTR_Y ${FTR_Y}
 
 	local R_H=$(( $(max $(( FTR_X - BOX_X )) $(( MAP_X - BOX_X )) ${BOX_H}) + 1))
 	local R_Y=$(min ${HDR_Y} ${MAP_Y} ${FTR_Y} ${BOX_Y})
 	local R_W=$(max ${#LIST_HDR} ${#LIST_MAP} ${#LIST_FTR} ${BOX_W})
 
+	# Store REGION clearing coords
 	box_coords_set REGION X ${HDR_X} Y ${R_Y} W ${R_W} H ${R_H} OB_W ${OB_W} OB_Y ${OB_Y} # For display region clearing if needed
 
-	# Inner box
+	# Store INNER_BOX coords
 	box_coords_set INNER_BOX X ${BOX_X} Y ${BOX_Y} W ${BOX_W} H ${BOX_H} COLOR ${IB_COLOR} OB_W ${OB_W} OB_Y ${OB_Y}
 
 	# List coords w/ box offset
@@ -258,8 +263,8 @@ sel_list () {
 	_LIST_DATA[MAX]=${#_LIST}
 	_LIST_DATA[CLEAR_REGION]=${CLEAR_REGION}
 
-	sel_set_pages
-	sel_scroll 1
+	sel_set_pages # Create table of page top indexes
+	sel_scroll 1 # Display list and handle user inputs
 }
 
 sel_norm () {
@@ -305,13 +310,14 @@ sel_scroll () {
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	cursor_off
-	[[ ${_LIST_DATA[CLEAR_REGION]} == 'true' ]] && clear_region
+	[[ ${_LIST_DATA[CLEAR_REGION]} == 'true' ]] && clear_region # Clear space around list if indicated
 
 	LIST_X=${_LIST_DATA[X]} # First row
 	BOT_X=$(( _LIST_DATA[X] + _LIST_DATA[H] - 1 )) # Last row
 	X_OFF=$(( _LIST_DATA[X] - 1 )) # Cursor offset
 
 	while true;do
+		# Display decorations
 		[[ ${O_COORDS[HAS_OB]} == 'true' ]] && msg_unicode_box ${O_COORDS[X]} ${O_COORDS[Y]} ${O_COORDS[W]} ${O_COORDS[H]} ${O_COORDS[COLOR]}
 		msg_unicode_box ${I_COORDS[X]} ${I_COORDS[Y]} ${I_COORDS[W]} ${I_COORDS[H]} ${I_COORDS[COLOR]}
 
@@ -332,29 +338,34 @@ sel_scroll () {
 		sel_load_page ${PAGE} # Sets _CURRENT_PAGE
 		PAGE=${_CURRENT_PAGE}
 
+		# Display paging information if multiple pages detected
 		if [[ ${_MAX_PAGE} -gt 1 ]];then
-			PAGING_INFO="<w>Page<N> <w>${_CURRENT_PAGE}<N> of <w>${_MAX_PAGE} pages<N>"
-			MAP_INFO="(<w>N<N>)ext page (<w>P<N>)revious page"
 			[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: PAGING_INFO:${PAGING_INFO} MAP_INFO:${MAP_INFO}"
 
-			PGR_X=$(( _LIST_DATA[X] - 2 ))
-			PGR_Y=$(sel_box_center ${_LIST_DATA[BOX_Y]} ${_LIST_DATA[BOX_W]} $(msg_nomarkup ${PAGING_INFO}))
+			if [[ ${O_COORDS[HAS_OB]} == 'true' ]];then
+				PAGING_INFO="<w>Page<N> <w>${_CURRENT_PAGE}<N> of <w>${_MAX_PAGE}<N>"
+				MAP_INFO="(<w>N<N>)ext page (<w>P<N>)revious page"
+				PGR_X=$(( _LIST_DATA[X] - 2 ))
+				PGR_Y=$(sel_box_center ${_LIST_DATA[BOX_Y]} ${_LIST_DATA[BOX_W]} $(msg_nomarkup ${PAGING_INFO}))
+				tcup ${PGR_X} ${PGR_Y};echo $(msg_markup ${PAGING_INFO})
+			else
+				MAP_INFO="Page<N> <w>${_CURRENT_PAGE}<N> of <w>${_MAX_PAGE}<N> - (<w>N<N>)ext page (<w>P<N>)revious page <w>"
+			fi
 			MAP_Y=$(sel_box_center ${_LIST_DATA[BOX_Y]} ${_LIST_DATA[BOX_W]} $(msg_nomarkup ${MAP_INFO}))
-			tcup ${PGR_X} ${PGR_Y};echo $(msg_markup ${PAGING_INFO})
 			tcup ${D_COORDS[MAP_X]} ${MAP_Y};echo $(msg_markup ${MAP_INFO})
 			box_coords_upd REGION X ${PGR_X} Y ${PGR_Y}
 		fi
 
-		sel_disp_page
+		sel_disp_page # Display list items
 
 		if [[ -e ${_TAG_FILE}  ]];then
-			read TAG_NDX < ${_TAG_FILE}
+			read TAG_NDX < ${_TAG_FILE} # Retrieve any stored menu positions
 		fi
 
 		[[ ${TAG_NDX} -ne 0 ]] && NDX=${TAG_NDX} || NDX=1 # Initialize index
 		_SEL_VAL=${_PAGE[${NDX}]} # Initialize return value
 
-		sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]} # Initial hilite
+		sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]} # Initial item hilite
 
 		while true;do
 			KEY=$(get_keys)
@@ -414,10 +425,10 @@ sel_scroll () {
 				break
 			fi
 
-			if [[ ${NAV} == 'true' ]];then # Return (populate) menu selection
+			if [[ ${NAV} == 'true' ]];then # Set key pressed and item selected
 				_SEL_KEY=${KEY}
 				_SEL_VAL=${_PAGE[${NDX}]}
-				[[ -n ${_TAG_FILE} ]] && echo "${NDX}" >${_TAG_FILE}
+				[[ -n ${_TAG_FILE} ]] && echo "${NDX}" >${_TAG_FILE} # Save menu position if indicated
 			fi
 		done
 	done
@@ -517,6 +528,8 @@ sel_set_pages () {
 	local PAGE
 	local PG_TOP
 
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+
 	PAGE=$(( _LIST_DATA[MAX] / _LIST_DATA[H] ))
 	REM=$(( _LIST_DATA[MAX] % _LIST_DATA[H] ))
 	[[ ${REM} -ne 0 ]] && (( PAGE++ ))
c0db94a 643 commit c0db94aba664721bbd6c18d690b07206d49ba3ed
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Mon Jan 20 20:13:14 2025 +0100

    01-20-2025-20:13:13

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
index 1f3008f..52a799c 100644
--- a/ZSH_LIB/SELECT.zsh
+++ b/ZSH_LIB/SELECT.zsh
@@ -1,17 +1,22 @@
 # LIB Dependencies
-_DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh STR.zsh TPUT.zsh UTILS.zsh VALIDATE.zsh"
+_DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh STR.zsh TPUT.zsh ./UTILS.zsh VALIDATE.zsh"
 
 # LIB Declarations
 typeset -A _CAT_COLS=()
 typeset -A _LIST_DATA=()
+typeset -A _PAGE_TOPS=()
 typeset -a _APP_KEYS=()
 typeset -a _LIST=()
+typeset -a _PAGE=()
 
 # LIB Vars
+_CURRENT_PAGE=0
 _EXIT_BOX=32
 _HAS_CAT=false
 _HILITE=${WHITE_ON_GREY}
 _HILITE_X=0
+_MAX_PAGE=0
+_PAGE_MAX_ROWS=$(( _MAX_ROWS - 15 )) # Longest list that fits the available display
 _SEL_KEY=''
 _SEL_LIB_DBG=4
 _SEL_VAL=''
@@ -30,30 +35,32 @@ sel_box_center () {
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
-	if validate_is_integer ${TXT};then
+	if validate_is_integer ${TXT};then # Accept either strings or integers
 		TXT_LEN=${TXT}
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: GOT INTEGER FOR TXT_LEN"
 	else
 		TXT_LEN=${#TXT}
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: GOT STRING FOR TXT_LEN"
 	fi
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TXT:${TXT} TXT_LEN:${TXT_LEN}"
 
-	CTR=$(( TXT_LEN / 2 )) && REM=$((CTR % 2))
+	CTR=$(( TXT_LEN / 2 )) && REM=$((TXT_LEN % 2))
 	[[ ${REM} -ne 0 ]] && TXT_CTR=$((CTR+1)) || TXT_CTR=${CTR}
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( TXT_LEN / 2 )) && REM=$((CTR % 2))'
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "CTR:${CTR} REM:${REM}"
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} CTR:$(( TXT_LEN / 2 )) && REM:$((CTR % 2))"
 
-	CTR=$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))
+	CTR=$(( BOX_WIDTH / 2 )) && REM=$((BOX_WIDTH % 2))
 	[[ ${REM} -ne 0 ]] && BOX_CTR=$((CTR+1)) || BOX_CTR=${CTR}
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))'
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "CTR:${CTR} REM:${REM}"
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} CTR:$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))"
 
 	CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))'
-	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "CTR:${CTR}"
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0} CTR:$(( BOX_LEFT + BOX_CTR - TXT_CTR )) BOX_LEFT:${BOX_LEFT} BOX_CTR:${BOX_CTR} TXT_CTR:${TXT_CTR}"
 
 	echo ${CTR}
 }
@@ -85,53 +92,67 @@ sel_list () {
 	local BOX_BOT=0
 	local BOX_H=0
 	local BOX_W=0
-	local BOX_X_COORD=0
-	local BOX_Y_COORD=0
+	local BOX_X=0
+	local BOX_Y=0
+	local DIFF=0
 	local F1=''
 	local F2=''
+	local FTR_X=0
+	local FTR_Y=0
+	local HDR_X=0
+	local HDR_Y=0
 	local LIST_H=0
 	local LIST_NDX=0
 	local LIST_W=0
 	local LIST_X=0
 	local LIST_Y=0
+	local MAP_X=0
+	local MAP_Y=0
+	local MAX=0
 	local OB_H=0
 	local OB_W=0
 	local OB_X=0
-	local OB_Y=0
 	local OB_X_OFFSET=2
+	local OB_Y=0
 	local OB_Y_OFFSET=4
-	local PAD=0
-	local DIFF=0
 	local L
 
 	local OPTION=''
-	local OPTSTR=":CF:H:I:M:O:T:x:y:"
+	local OPTSTR=":CF:H:I:M:O:T:W:x:y:c"
 	OPTIND=0
 
+	local CLEAR_REGION=false
+	local HAS_FTR=false
+	local HAS_HDR=false
+	local HAS_MAP=false
 	local HAS_OB=false
+	local IB_COLOR=${RESET}
+	local LF=0
+	local LH=0
 	local LIST_FTR=''
 	local LIST_HDR=''
 	local LIST_MAP=''
-	local IB_COLOR=''
-	local OB_COLOR=''
+	local LM=0
+	local OB_COLOR=${RESET}
+	local OB_PAD=0
 	local X_COORD_ARG=0
 	local Y_COORD_ARG=0
-	local HAS_HDR=false
-	local HAS_FTR=false
-	local HAS_MAP=false
 	local _HAS_CAT=false
+	local STR=''
 
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
 	while getopts ${OPTSTR} OPTION;do
 		case $OPTION in
 	   C) _HAS_CAT=true;;
-		F) HAS_FTR=true;LIST_FTR=${OPTARG};;
-		H) HAS_HDR=true;LIST_HDR=${OPTARG};;
+		F) HAS_FTR=true;LIST_FTR=${OPTARG};STR=$(msg_nomarkup ${LIST_FTR});LF=${#STR};;
+		H) HAS_HDR=true;LIST_HDR=${OPTARG};STR=$(msg_nomarkup ${LIST_HDR});LH=${#STR};;
 	   I) IB_COLOR=${OPTARG};;
-		M) HAS_MAP=true;LIST_MAP=${OPTARG};;
+		M) HAS_MAP=true;LIST_MAP=${OPTARG};STR=$(msg_nomarkup ${LIST_MAP});LM=${#STR};;
 	   O) HAS_OB=true;OB_COLOR=${OPTARG};;
 	   T) _TAG=${OPTARG};;
+	   W) OB_PAD=${OPTARG};;
+	   c) CLEAR_REGION=true;;
 	   x) X_COORD_ARG=${OPTARG};;
 	   y) Y_COORD_ARG=${OPTARG};;
 	   :) exit_leave "${RED_FG}${0}${RESET}: option: -${OPTARG} requires an argument";;
@@ -142,95 +163,103 @@ sel_list () {
 
 	[[ -n ${_TAG}  ]] && _TAG_FILE="/tmp/$$.${_TAG}.state"
 
+	# If no X,Y coords are passed default to center
 	LIST_W=$(arr_long_elem_len ${_LIST})
-	LIST_H=${#_LIST}
+	[[ ${#_LIST} -gt ${_PAGE_MAX_ROWS} ]] && LIST_H=${_PAGE_MAX_ROWS} || LIST_H=${#_LIST}
 
-	BOX_W=$((LIST_W+2))
 	BOX_H=$((LIST_H+2))
+	[[ ${X_COORD_ARG} -eq 0 ]] && BOX_X=$(coord_center $(( _MAX_ROWS - 1 )) ${BOX_H}) || BOX_X=${X_COORD_ARG}
+
+	[[ ${_HAS_CAT} == 'true' ]] && BOX_W=$(( LIST_W + 6 )) || BOX_W=$(( LIST_W + 2 ))
+	[[ ${Y_COORD_ARG} -eq 0 ]] && BOX_Y=$(coord_center $(( _MAX_COLS - 1 )) ${BOX_W}) || BOX_Y=${Y_COORD_ARG}
 
-	# Parse columns for lists having categories
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: LIST_W:${LIST_W} LIST_H:${LIST_H}"
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: INNER BOX - BOX_W:${BOX_W} BOX_H:${BOX_H}"
+
+	# Set field widths for lists having categories
 	if [[ ${_HAS_CAT} == 'true' ]];then
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _HAS_CAT:${_HAS_CAT}"
 		for L in ${_LIST};do
 			F1=$(cut -d: -f1 <<<${L})
 			F2=$(cut -d: -f2 <<<${L})
 			[[ ${#F1} -gt ${_CAT_COLS[1]} ]] && _CAT_COLS[1]=${#F1}
 			[[ ${#F2} -gt ${_CAT_COLS[2]} ]] && _CAT_COLS[2]=${#F2}
 		done
+		_LIST=(${(o)_LIST}) # Sort categories
 	else
 		_CAT_COLS=()
 	fi
 
-	# If no coords are passed default to center
-	[[ ${X_COORD_ARG} -eq 0 ]] && BOX_X_COORD=$(coord_center $(( _MAX_ROWS - 1 )) ${BOX_H}) || BOX_X_COORD=${X_COORD_ARG}
-	[[ ${Y_COORD_ARG} -eq 0 ]] && BOX_Y_COORD=$(coord_center $(( _MAX_COLS - 1 )) ${BOX_W}) || BOX_Y_COORD=${Y_COORD_ARG}
+	BOX_BOT=$(( BOX_X + BOX_H)) # Store coordinate
 
-	BOX_BOT=$((BOX_X_COORD+BOX_H)) # Store coordinate
+	# Widest element - inner box, header, footer, map, or exit msg
+	((LM+=6)) #Add MAP padding inside outer box
+	MAX=$(max ${BOX_W} ${LH} ${LF} ${LM} ${_EXIT_BOX}) 
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "MAX:${MAX} BOX_W:${BOX_W} LIST_HDR:${LH} LIST_FTR:${LF} LIST_MAP:${LM} _EXIT_BOX:${_EXIT_BOX}" 
 
 	# Handle outer box
 	if [[ ${HAS_OB} == 'true' ]];then
-		OB_X=$(( BOX_X_COORD - OB_X_OFFSET ))
-		OB_Y=$(( BOX_Y_COORD - OB_Y_OFFSET ))
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: OUTER BOX DETECTED"
+		OB_X=$(( BOX_X - OB_X_OFFSET ))
+		OB_Y=$(( BOX_Y - OB_Y_OFFSET ))
 		OB_W=$(( BOX_W + OB_Y_OFFSET * 2 ))
 		OB_H=$(( BOX_H + OB_X_OFFSET * 2 ))
-		PAD=$(max ${#LIST_HDR} ${#LIST_FTR} ${#LIST_MAP} ${_EXIT_BOX} ) # Longest text - header, footer, map, or exit msg
 
-		if [[ ${PAD} -gt ${OB_W} ]];then
-			DIFF=$(( (PAD - OB_W) / 2 ))
+		if [[ ${MAX} -gt ${OB_W} ]];then
+			DIFF=$(( (MAX - OB_W) / 2 ))
 			(( OB_Y-=DIFF ))
 			(( OB_W+=DIFF * 2 ))
 		fi
+	fi
+
+	box_coords_set OUTER_BOX HAS_OB ${HAS_OB} X ${OB_X} Y ${OB_Y} W ${OB_W} H ${OB_H} COLOR ${OB_COLOR}
 
-		msg_unicode_box ${OB_X} ${OB_Y} ${OB_W} ${OB_H} ${OB_COLOR}
-		box_coords_set OUTER_BOX X ${OB_X} Y ${OB_Y} W ${OB_W} H ${OB_H}
+	# Set coords for list decorations
+	if [[ ${HAS_OB} == 'true' ]];then
+		HDR_X=$(( BOX_X - 3 ))
+		HDR_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_HDR}))
+		MAP_X=${BOX_BOT}
+		MAP_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_MAP}))
+		FTR_X=$(( BOX_BOT + 2 ))
+		FTR_Y=$(sel_box_center $(( BOX_Y - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_FTR}))
+	else
+		HDR_X=$(( BOX_X - 1 ))
+		HDR_Y=$(sel_box_center ${BOX_Y} ${BOX_W} $(msg_nomarkup ${LIST_HDR}))
+		MAP_X=${BOX_BOT}
+		MAP_Y=$(sel_box_center ${BOX_Y} ${BOX_W} $(msg_nomarkup ${LIST_MAP}))
+		[[ -n ${LIST_MAP} ]] && FTR_X=$(( BOX_BOT + 1 )) || FTR_X=${BOX_BOT}
+		FTR_Y=$(sel_box_center ${BOX_Y} ${BOX_W} $(msg_nomarkup ${LIST_FTR}))
 	fi
 
-	# TODO: inner box width needs longest list item to determine minimum width
-	# TODO: categories, if present, need sorting
-	# Handle inner box for list
-	msg_unicode_box ${BOX_X_COORD} ${BOX_Y_COORD} ${BOX_W} ${BOX_H} ${IB_COLOR}
-	box_coords_set INNER_BOX X ${BOX_X_COORD} Y ${BOX_Y_COORD} W ${BOX_W} H ${BOX_H} OB_W ${OB_W} OB_Y ${OB_Y}
+	box_coords_set DECOR HAS_HDR ${HAS_HDR} HDR_X ${HDR_X} HDR_Y ${HDR_Y} HAS_MAP ${HAS_MAP} MAP_X ${MAP_X} MAP_Y ${MAP_Y} HAS_FTR ${HAS_FTR} FTR_X ${FTR_X} FTR_Y ${FTR_Y}
 
-	# List inside box coords
-	LIST_X=$(( BOX_X_COORD+1 ))
-	LIST_Y=$(( BOX_Y_COORD+1 ))
+	local R_H=$(( $(max $(( FTR_X - BOX_X )) $(( MAP_X - BOX_X )) ${BOX_H}) + 1))
+	local R_Y=$(min ${HDR_Y} ${MAP_Y} ${FTR_Y} ${BOX_Y})
+	local R_W=$(max ${#LIST_HDR} ${#LIST_MAP} ${#LIST_FTR} ${BOX_W})
+
+	box_coords_set REGION X ${HDR_X} Y ${R_Y} W ${R_W} H ${R_H} OB_W ${OB_W} OB_Y ${OB_Y} # For display region clearing if needed
+
+	# Inner box
+	box_coords_set INNER_BOX X ${BOX_X} Y ${BOX_Y} W ${BOX_W} H ${BOX_H} COLOR ${IB_COLOR} OB_W ${OB_W} OB_Y ${OB_Y}
+
+	# List coords w/ box offset
+	LIST_X=$(( BOX_X + 1 ))
+	LIST_Y=$(( BOX_Y + 1 ))
 
 	# Save data for future reference
+	_LIST_DATA[FTR]=${LIST_FTR}
+	_LIST_DATA[HDR]=${LIST_HDR}
+	_LIST_DATA[MAP]=${LIST_MAP}
 	_LIST_DATA[X]=${LIST_X}
 	_LIST_DATA[Y]=${LIST_Y}
+	_LIST_DATA[H]=${LIST_H}
+	_LIST_DATA[BOX_W]=${BOX_W}
+	_LIST_DATA[BOX_Y]=${BOX_Y}
 	_LIST_DATA[MAX]=${#_LIST}
+	_LIST_DATA[CLEAR_REGION]=${CLEAR_REGION}
 
-	# Display list
-	cursor_off
-	for (( LIST_NDX=1;LIST_NDX <= LIST_H;LIST_NDX++ ));do
-		sel_norm $((LIST_X++)) ${LIST_Y} ${_LIST[${LIST_NDX}]}
-	done
-
-	# Display header, map, and footer
-	if [[ ${HAS_HDR} == 'true' ]];then
-		if [[ ${HAS_OB} == 'true' ]];then
-			tcup $(( BOX_X_COORD -3 )) $(sel_box_center $(( BOX_Y_COORD - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_HDR}));echo $(msg_markup ${LIST_HDR})
-		else
-			tcup $(( BOX_X_COORD - 1 )) $(sel_box_center ${BOX_Y_COORD} ${BOX_W} $(msg_nomarkup ${LIST_HDR}));echo $(msg_markup ${LIST_HDR})
-		fi
-	fi
-
-	if [[ ${HAS_MAP} == 'true' ]];then
-		if [[ ${HAS_OB} == 'true' ]];then
-			tcup ${BOX_BOT} $(sel_box_center $(( BOX_Y_COORD - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_MAP}));echo $(msg_markup ${LIST_MAP})
-		else
-			tcup ${BOX_BOT} $(sel_box_center ${BOX_Y_COORD} ${BOX_W} $(msg_nomarkup ${LIST_MAP}));echo $(msg_markup ${LIST_MAP})
-		fi
-	fi
-
-	if [[ ${HAS_FTR} == 'true' ]];then
-		if [[ ${HAS_OB} == 'true' ]];then
-			tcup $(( BOX_BOT + 2 )) $(sel_box_center $(( BOX_Y_COORD - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_FTR}));echo $(msg_markup ${LIST_FTR})
-		else
-			tcup $(( BOX_BOT + 2 )) $(sel_box_center ${BOX_Y_COORD} ${BOX_W} $(msg_nomarkup ${LIST_FTR}));echo $(msg_markup ${LIST_FTR})
-		fi
-	fi
-
-	sel_scroll
+	sel_set_pages
+	sel_scroll 1
 }
 
 sel_norm () {
@@ -253,6 +282,7 @@ sel_norm () {
 }
 
 sel_scroll () {
+	local PAGE=${1}
 	local BOT_X=0
 	local KEY=''
 	local NAV=''
@@ -261,75 +291,135 @@ sel_scroll () {
 	local SCROLL=''
 	local TAG_NDX=0
 	local X_OFF=0
+	local PAGING=''
+	local PAGING_INFO=''
+	local MAP_INFO=''
+	local PGR_X=0
+	local PGR_Y=0
+	local MAP_X=0
+	local MAP_Y=0
+	local -A I_COORDS=($(box_coords_get INNER_BOX))
+	local -A O_COORDS=($(box_coords_get OUTER_BOX))
+	local -A D_COORDS=($(box_coords_get DECOR))
 	
 	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
 
-	LIST_X=${_LIST_DATA[X]}
-	BOT_X=$(( _LIST_DATA[X] + _LIST_DATA[MAX] - 1 ))
-	X_OFF=$(( _LIST_DATA[X] - 1 ))
-
-	if [[ -e ${_TAG_FILE}  ]];then
-		read TAG_NDX < ${_TAG_FILE}
-	fi
-
-	[[ ${TAG_NDX} -ne 0 ]] && NDX=${TAG_NDX} || NDX=1 # Initialize index
-	_SEL_VAL=${_LIST[${NDX}]} # Initialize return value
+	cursor_off
+	[[ ${_LIST_DATA[CLEAR_REGION]} == 'true' ]] && clear_region
 
-	sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]} # Initial hilite
+	LIST_X=${_LIST_DATA[X]} # First row
+	BOT_X=$(( _LIST_DATA[X] + _LIST_DATA[H] - 1 )) # Last row
+	X_OFF=$(( _LIST_DATA[X] - 1 )) # Cursor offset
 
 	while true;do
-		KEY=$(get_keys)
-
-		_SEL_KEY='?'
-
-		# Reserved application key breaks from navigation
-		if [[ ${_APP_KEYS[(i)${KEY}]} -le ${#_APP_KEYS} ]];then # App key was pressed
-			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"
+		[[ ${O_COORDS[HAS_OB]} == 'true' ]] && msg_unicode_box ${O_COORDS[X]} ${O_COORDS[Y]} ${O_COORDS[W]} ${O_COORDS[H]} ${O_COORDS[COLOR]}
+		msg_unicode_box ${I_COORDS[X]} ${I_COORDS[Y]} ${I_COORDS[W]} ${I_COORDS[H]} ${I_COORDS[COLOR]}
 
-			_SEL_KEY=${KEY} 
+		# Display list decorations
+		if [[ ${D_COORDS[HAS_HDR]} == 'true' ]];then
+			tcup ${D_COORDS[HDR_X]} ${D_COORDS[HDR_Y]};echo $(msg_markup ${_LIST_DATA[HDR]})
+		fi
 
-			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"
+		if [[ ${D_COORDS[HAS_MAP]} == 'true' ]];then
+			tcup ${D_COORDS[MAP_X]} ${D_COORDS[MAP_Y]};echo $(msg_markup ${_LIST_DATA[MAP]})
+		fi
 
-			break # Quit navigation
+		if [[ ${D_COORDS[HAS_FTR]} == 'true' ]];then
+			tcup ${D_COORDS[FTR_X]} ${D_COORDS[FTR_Y]};echo $(msg_markup ${_LIST_DATA[FTR]})
 		fi
 
-		NAV=true # Return only menu selections
+		# Display list items
+		sel_load_page ${PAGE} # Sets _CURRENT_PAGE
+		PAGE=${_CURRENT_PAGE}
+
+		if [[ ${_MAX_PAGE} -gt 1 ]];then
+			PAGING_INFO="<w>Page<N> <w>${_CURRENT_PAGE}<N> of <w>${_MAX_PAGE} pages<N>"
+			MAP_INFO="(<w>N<N>)ext page (<w>P<N>)revious page"
+			[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: PAGING_INFO:${PAGING_INFO} MAP_INFO:${MAP_INFO}"
+
+			PGR_X=$(( _LIST_DATA[X] - 2 ))
+			PGR_Y=$(sel_box_center ${_LIST_DATA[BOX_Y]} ${_LIST_DATA[BOX_W]} $(msg_nomarkup ${PAGING_INFO}))
+			MAP_Y=$(sel_box_center ${_LIST_DATA[BOX_Y]} ${_LIST_DATA[BOX_W]} $(msg_nomarkup ${MAP_INFO}))
+			tcup ${PGR_X} ${PGR_Y};echo $(msg_markup ${PAGING_INFO})
+			tcup ${D_COORDS[MAP_X]} ${MAP_Y};echo $(msg_markup ${MAP_INFO})
+			box_coords_upd REGION X ${PGR_X} Y ${PGR_Y}
+		fi
 
-		case ${KEY} in
-			0) break;;
-			q) exit_request $(sel_set_ebox);break;;
-			1|u|k) SCROLL="U";;
-			2|d|j) SCROLL="D";;
-			3|t|h) SCROLL="T";;
-			4|b|l) SCROLL="B";;
-			*) NAV=false;;
-		esac
+		sel_disp_page
 
-		if [[ ${SCROLL} == 'U' ]];then
-			NORM_NDX=${NDX} && ((NDX--))
-			[[ ${NDX} -lt 1 ]] && NDX=${_LIST_DATA[MAX]}
-			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
-			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
-		elif [[ ${SCROLL} == 'D' ]];then
-			NORM_NDX=${NDX} && ((NDX++))
-			[[ ${NDX} -gt ${_LIST_DATA[MAX]} ]] && NDX=1
-			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
-			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
-		elif [[ ${SCROLL} == 'T' ]];then
-			NORM_NDX=${NDX} && NDX=1
-			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
-			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
-		elif [[ ${SCROLL} == 'B' ]];then
-			NORM_NDX=${NDX} && NDX=${_LIST_DATA[MAX]}
-			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
-			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
+		if [[ -e ${_TAG_FILE}  ]];then
+			read TAG_NDX < ${_TAG_FILE}
 		fi
 
-		if [[ ${NAV} == 'true' ]];then # Return (populate) menu selection
-			_SEL_KEY=${KEY}
-			_SEL_VAL=${_LIST[${NDX}]}
-			[[ -n ${_TAG_FILE} ]] && echo "${NDX}" >${_TAG_FILE}
-		fi
+		[[ ${TAG_NDX} -ne 0 ]] && NDX=${TAG_NDX} || NDX=1 # Initialize index
+		_SEL_VAL=${_PAGE[${NDX}]} # Initialize return value
+
+		sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]} # Initial hilite
+
+		while true;do
+			KEY=$(get_keys)
+
+			_SEL_KEY='?'
+
+			# Reserved application key breaks from navigation
+			if [[ ${_APP_KEYS[(i)${KEY}]} -le ${#_APP_KEYS} ]];then # App key was pressed
+				[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"
+
+				_SEL_KEY=${KEY} 
+
+				[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"
+
+				break 2 # Quit navigation
+			fi
+
+			NAV=true # Return only menu selections
+			PAGING=''
+
+			case ${KEY} in
+				0) break 2;;
+				q) exit_request $(sel_set_ebox);break;;
+				27) return -1;;
+				1|u|k) SCROLL="U";;
+				2|d|j) SCROLL="D";;
+				3|t|h) SCROLL="T";;
+				4|b|l) SCROLL="B";;
+				5|p) SCROLL="P";;
+				6|n) SCROLL="N";;
+				*) NAV=false;;
+			esac
+
+			if [[ ${SCROLL} == 'U' ]];then
+				NORM_NDX=${NDX} && ((NDX--))
+				[[ ${NDX} -lt 1 ]] && NDX=${_LIST_DATA[H]}
+				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
+				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+			elif [[ ${SCROLL} == 'D' ]];then
+				NORM_NDX=${NDX} && ((NDX++))
+				[[ ${NDX} -gt ${_LIST_DATA[H]} ]] && NDX=1
+				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
+				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+			elif [[ ${SCROLL} == 'T' ]];then
+				NORM_NDX=${NDX} && NDX=1
+				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
+				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+			elif [[ ${SCROLL} == 'B' ]];then
+				NORM_NDX=${NDX} && NDX=${_LIST_DATA[H]}
+				sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NORM_NDX}]}
+				sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+			elif [[ ${SCROLL} == 'N' ]];then
+				((PAGE++))
+				break
+			elif [[ ${SCROLL} == 'P' ]];then
+				[[ ${_CURRENT_PAGE} -eq 1 ]] && PAGE=${_MAX_PAGE} || ((PAGE--))
+				break
+			fi
+
+			if [[ ${NAV} == 'true' ]];then # Return (populate) menu selection
+				_SEL_KEY=${KEY}
+				_SEL_VAL=${_PAGE[${NDX}]}
+				[[ -n ${_TAG_FILE} ]] && echo "${NDX}" >${_TAG_FILE}
+			fi
+		done
 	done
 	return 0
 }
@@ -342,7 +432,7 @@ sel_set_app_keys () {
 
 sel_set_ebox () {
 	local -A I_COORDS
-	local MSG_LEN=28
+	local MSG_LEN=$(( _EXIT_BOX - 4 ))
 	local X_ARG=0
 	local Y_ARG=0
 	local W_ARG=0
@@ -356,7 +446,7 @@ sel_set_ebox () {
 
 	if	[[ ${I_COORDS[OB_W]} -ne 0 ]];then
 		Y_ARG=$(( I_COORDS[OB_Y] + 2 ))
-		W_ARG=$(( I_COORDS[OB_W] -2 ))
+		W_ARG=$(( I_COORDS[OB_W] - 2 ))
 	elif [[ ${MSG_LEN} -gt ${I_COORDS[W]}  ]];then
 		DIFF=$(( (MSG_LEN - I_COORDS[W]) / 2 ))
 		Y_ARG=$(( I_COORDS[Y] - DIFF ))
@@ -373,3 +463,113 @@ sel_set_list () {
 	_LIST=(${LIST})
 }
 
+clear_region () {
+	local -A R_COORDS
+	local X_ARG=0
+	local Y_ARG=0
+	local W_ARG=0
+	local H_ARG=0
+	local DIFF=0
+	local R=0
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+
+	R_COORDS=($(box_coords_get REGION))
+
+	if [[ -z ${R_COORDS} ]];then
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: R_COORDS is null - returning"
+		return -1
+	fi
+
+	X_ARG=${R_COORDS[X]}
+	Y_ARG=${R_COORDS[Y]}
+	W_ARG=${R_COORDS[W]}
+	H_ARG=${R_COORDS[H]}
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
+
+	if	[[ ${R_COORDS[OB_W]} -ne 0 ]];then
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: HAS OUTER BOX"
+		X_ARG=$(( R_COORDS[X] - 2 ))
+		Y_ARG=$(( R_COORDS[OB_Y] - 4 ))
+		W_ARG=$(( R_COORDS[OB_W] + 8 ))
+		H_ARG=$(( H_ARG + 3 ))
+	else
+		((X_ARG-=2))
+		((Y_ARG-=2))
+		((W_ARG+=4))
+		((H_ARG+=2))
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: ADJUSTMENTS X_ARG:${X_ARG}  Y_ARG:${Y_ARG} W_ARG:${W_ARG} H_ARG:${H_ARG}"
+	fi
+
+	local STR=$(str_rep_char "#" ${W_ARG})
+	for (( R=0; R <= ${H_ARG}; R++ ));do
+		tcup $(( X_ARG + R )) ${Y_ARG};tput ech ${W_ARG}
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && tcup $(( X_ARG + R )) ${Y_ARG} && echo -n ${STR}
+	done
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: Cleared ${H_ARG} rows starting from row:${X_ARG}, col:${Y_ARG} for:${W_ARG} columns"
+}
+
+sel_set_pages () {
+	local REM
+	local P
+	local PAGE
+	local PG_TOP
+
+	PAGE=$(( _LIST_DATA[MAX] / _LIST_DATA[H] ))
+	REM=$(( _LIST_DATA[MAX] % _LIST_DATA[H] ))
+	[[ ${REM} -ne 0 ]] && (( PAGE++ ))
+
+	_MAX_PAGE=${PAGE} # Page boundary
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${0}: _MAX_PAGE:${_MAX_PAGE} PAGE:${PAGE}"
+
+	_PAGE_TOPS=()
+	for (( P=1; P<=PAGE; P++ ));do
+		[[ ${P} -eq 1 ]] && PG_TOP=1 || PG_TOP=$(( _PAGE_TOPS[$(( P-1 ))] + _LIST_DATA[H] ))
+		_PAGE_TOPS[${P}]=${PG_TOP}
+	done
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_PAGE_TOPS:${(kv)_PAGE_TOPS}"
+}
+
+sel_load_page () {
+	local PAGE=${1}
+	local NDX=0
+	local TOP_ROW=1
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} ARGV:${@}"
+
+	# Evaluate/validate PAGE arg
+	if [[ -n ${_PAGE_TOPS[${PAGE}]} ]];then
+		TOP_ROW=${_PAGE_TOPS[${PAGE}]}
+	else
+		TOP_ROW=1
+		PAGE=1
+	fi
+	 
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "TOP_ROW:${TOP_ROW}"
+
+	_PAGE=()
+	for (( NDX=1; NDX <= _LIST_DATA[H]; NDX++ ));do
+		[[ -z ${_LIST[$(( NDX + TOP_ROW - 1 ))]} ]] && continue # No blank rows
+		_PAGE+=${_LIST[$(( NDX + TOP_ROW - 1 ))]}
+		[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "ADDED ROW:${_LIST[$(( NDX + TOP_ROW - 1 ))]}"
+		[[ ${NDX} -eq ${#_LIST} ]] && break
+	done
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "_LIST ROWS:${#_LIST} _PAGE ROWS:${#_PAGE}"
+
+	_CURRENT_PAGE=${PAGE} # Set the currently displayed page
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "SET: _CURRENT_PAGE:${_CURRENT_PAGE}"
+}
+
+sel_disp_page () {
+	local NDX=0
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}"
+
+	for (( NDX=1; NDX <= ${#_PAGE}; NDX++ ));do
+		sel_norm $(( _LIST_DATA[X] + NDX - 1 )) ${_LIST_DATA[Y]} ${_PAGE[${NDX}]}
+	done
+}
08334e8 387 commit 08334e89f017b25c9de6d3d35ceaa955a2fb0464
Author: Kurt Miller <miller_kurt_e@yahoo.com>
Date:   Wed Jan 15 16:12:52 2025 +0100

    01-15-2025-16:12:52

diff --git a/ZSH_LIB/SELECT.zsh b/ZSH_LIB/SELECT.zsh
new file mode 100644
index 0000000..1f3008f
--- /dev/null
+++ b/ZSH_LIB/SELECT.zsh
@@ -0,0 +1,375 @@
+# LIB Dependencies
+_DEPS_+="ARRAY.zsh DBG.zsh MSG.zsh STR.zsh TPUT.zsh UTILS.zsh VALIDATE.zsh"
+
+# LIB Declarations
+typeset -A _CAT_COLS=()
+typeset -A _LIST_DATA=()
+typeset -a _APP_KEYS=()
+typeset -a _LIST=()
+
+# LIB Vars
+_EXIT_BOX=32
+_HAS_CAT=false
+_HILITE=${WHITE_ON_GREY}
+_HILITE_X=0
+_SEL_KEY=''
+_SEL_LIB_DBG=4
+_SEL_VAL=''
+_TAG=''
+_TAG_FILE=''
+
+sel_box_center () {
+	local BOX_LEFT=${1};shift # Box Y coord
+	local BOX_WIDTH=${1};shift # Box W coord
+	local TXT=${@} # Text to center
+	local TXT_LEN=0
+	local BOX_CTR=0
+	local CTR=0
+	local REM=0
+	local TXT_CTR=0
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+
+	if validate_is_integer ${TXT};then
+		TXT_LEN=${TXT}
+	else
+		TXT_LEN=${#TXT}
+	fi
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@} TXT:${TXT} TXT_LEN:${TXT_LEN}"
+
+	CTR=$(( TXT_LEN / 2 )) && REM=$((CTR % 2))
+	[[ ${REM} -ne 0 ]] && TXT_CTR=$((CTR+1)) || TXT_CTR=${CTR}
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( TXT_LEN / 2 )) && REM=$((CTR % 2))'
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "CTR:${CTR} REM:${REM}"
+
+	CTR=$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))
+	[[ ${REM} -ne 0 ]] && BOX_CTR=$((CTR+1)) || BOX_CTR=${CTR}
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( BOX_WIDTH / 2 )) && REM=$((CTR % 2))'
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "CTR:${CTR} REM:${REM}"
+
+	CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg 'CTR=$(( BOX_LEFT + BOX_CTR - TXT_CTR ))'
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "CTR:${CTR}"
+
+	echo ${CTR}
+}
+
+sel_hilite () {
+	local X=${1}
+	local Y=${2}
+	local TEXT=${3}
+	local F1 F2
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
+
+	tcup ${X} ${Y}
+
+	do_smso
+	if [[ ${_HAS_CAT} == 'true' ]];then
+		F1=$(cut -d: -f1 <<<${TEXT})
+		F2=$(cut -d: -f2 <<<${TEXT})
+		printf "${WHITE_FG}%-*s${RESET} ${_HILITE}%-*s${RESET}
" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
+	else
+		echo ${TEXT}
+	fi
+	do_rmso
+
+	_HILITE_X=${X}
+}
+
+sel_list () {
+	local BOX_BOT=0
+	local BOX_H=0
+	local BOX_W=0
+	local BOX_X_COORD=0
+	local BOX_Y_COORD=0
+	local F1=''
+	local F2=''
+	local LIST_H=0
+	local LIST_NDX=0
+	local LIST_W=0
+	local LIST_X=0
+	local LIST_Y=0
+	local OB_H=0
+	local OB_W=0
+	local OB_X=0
+	local OB_Y=0
+	local OB_X_OFFSET=2
+	local OB_Y_OFFSET=4
+	local PAD=0
+	local DIFF=0
+	local L
+
+	local OPTION=''
+	local OPTSTR=":CF:H:I:M:O:T:x:y:"
+	OPTIND=0
+
+	local HAS_OB=false
+	local LIST_FTR=''
+	local LIST_HDR=''
+	local LIST_MAP=''
+	local IB_COLOR=''
+	local OB_COLOR=''
+	local X_COORD_ARG=0
+	local Y_COORD_ARG=0
+	local HAS_HDR=false
+	local HAS_FTR=false
+	local HAS_MAP=false
+	local _HAS_CAT=false
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+
+	while getopts ${OPTSTR} OPTION;do
+		case $OPTION in
+	   C) _HAS_CAT=true;;
+		F) HAS_FTR=true;LIST_FTR=${OPTARG};;
+		H) HAS_HDR=true;LIST_HDR=${OPTARG};;
+	   I) IB_COLOR=${OPTARG};;
+		M) HAS_MAP=true;LIST_MAP=${OPTARG};;
+	   O) HAS_OB=true;OB_COLOR=${OPTARG};;
+	   T) _TAG=${OPTARG};;
+	   x) X_COORD_ARG=${OPTARG};;
+	   y) Y_COORD_ARG=${OPTARG};;
+	   :) exit_leave "${RED_FG}${0}${RESET}: option: -${OPTARG} requires an argument";;
+	  \?) exit_leave "${RED_FG}${0}${RESET}: unknown option -${OPTARG}";;
+		esac
+	done
+	shift $(( OPTIND - 1 ))
+
+	[[ -n ${_TAG}  ]] && _TAG_FILE="/tmp/$$.${_TAG}.state"
+
+	LIST_W=$(arr_long_elem_len ${_LIST})
+	LIST_H=${#_LIST}
+
+	BOX_W=$((LIST_W+2))
+	BOX_H=$((LIST_H+2))
+
+	# Parse columns for lists having categories
+	if [[ ${_HAS_CAT} == 'true' ]];then
+		for L in ${_LIST};do
+			F1=$(cut -d: -f1 <<<${L})
+			F2=$(cut -d: -f2 <<<${L})
+			[[ ${#F1} -gt ${_CAT_COLS[1]} ]] && _CAT_COLS[1]=${#F1}
+			[[ ${#F2} -gt ${_CAT_COLS[2]} ]] && _CAT_COLS[2]=${#F2}
+		done
+	else
+		_CAT_COLS=()
+	fi
+
+	# If no coords are passed default to center
+	[[ ${X_COORD_ARG} -eq 0 ]] && BOX_X_COORD=$(coord_center $(( _MAX_ROWS - 1 )) ${BOX_H}) || BOX_X_COORD=${X_COORD_ARG}
+	[[ ${Y_COORD_ARG} -eq 0 ]] && BOX_Y_COORD=$(coord_center $(( _MAX_COLS - 1 )) ${BOX_W}) || BOX_Y_COORD=${Y_COORD_ARG}
+
+	BOX_BOT=$((BOX_X_COORD+BOX_H)) # Store coordinate
+
+	# Handle outer box
+	if [[ ${HAS_OB} == 'true' ]];then
+		OB_X=$(( BOX_X_COORD - OB_X_OFFSET ))
+		OB_Y=$(( BOX_Y_COORD - OB_Y_OFFSET ))
+		OB_W=$(( BOX_W + OB_Y_OFFSET * 2 ))
+		OB_H=$(( BOX_H + OB_X_OFFSET * 2 ))
+		PAD=$(max ${#LIST_HDR} ${#LIST_FTR} ${#LIST_MAP} ${_EXIT_BOX} ) # Longest text - header, footer, map, or exit msg
+
+		if [[ ${PAD} -gt ${OB_W} ]];then
+			DIFF=$(( (PAD - OB_W) / 2 ))
+			(( OB_Y-=DIFF ))
+			(( OB_W+=DIFF * 2 ))
+		fi
+
+		msg_unicode_box ${OB_X} ${OB_Y} ${OB_W} ${OB_H} ${OB_COLOR}
+		box_coords_set OUTER_BOX X ${OB_X} Y ${OB_Y} W ${OB_W} H ${OB_H}
+	fi
+
+	# TODO: inner box width needs longest list item to determine minimum width
+	# TODO: categories, if present, need sorting
+	# Handle inner box for list
+	msg_unicode_box ${BOX_X_COORD} ${BOX_Y_COORD} ${BOX_W} ${BOX_H} ${IB_COLOR}
+	box_coords_set INNER_BOX X ${BOX_X_COORD} Y ${BOX_Y_COORD} W ${BOX_W} H ${BOX_H} OB_W ${OB_W} OB_Y ${OB_Y}
+
+	# List inside box coords
+	LIST_X=$(( BOX_X_COORD+1 ))
+	LIST_Y=$(( BOX_Y_COORD+1 ))
+
+	# Save data for future reference
+	_LIST_DATA[X]=${LIST_X}
+	_LIST_DATA[Y]=${LIST_Y}
+	_LIST_DATA[MAX]=${#_LIST}
+
+	# Display list
+	cursor_off
+	for (( LIST_NDX=1;LIST_NDX <= LIST_H;LIST_NDX++ ));do
+		sel_norm $((LIST_X++)) ${LIST_Y} ${_LIST[${LIST_NDX}]}
+	done
+
+	# Display header, map, and footer
+	if [[ ${HAS_HDR} == 'true' ]];then
+		if [[ ${HAS_OB} == 'true' ]];then
+			tcup $(( BOX_X_COORD -3 )) $(sel_box_center $(( BOX_Y_COORD - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_HDR}));echo $(msg_markup ${LIST_HDR})
+		else
+			tcup $(( BOX_X_COORD - 1 )) $(sel_box_center ${BOX_Y_COORD} ${BOX_W} $(msg_nomarkup ${LIST_HDR}));echo $(msg_markup ${LIST_HDR})
+		fi
+	fi
+
+	if [[ ${HAS_MAP} == 'true' ]];then
+		if [[ ${HAS_OB} == 'true' ]];then
+			tcup ${BOX_BOT} $(sel_box_center $(( BOX_Y_COORD - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_MAP}));echo $(msg_markup ${LIST_MAP})
+		else
+			tcup ${BOX_BOT} $(sel_box_center ${BOX_Y_COORD} ${BOX_W} $(msg_nomarkup ${LIST_MAP}));echo $(msg_markup ${LIST_MAP})
+		fi
+	fi
+
+	if [[ ${HAS_FTR} == 'true' ]];then
+		if [[ ${HAS_OB} == 'true' ]];then
+			tcup $(( BOX_BOT + 2 )) $(sel_box_center $(( BOX_Y_COORD - OB_Y )) $(( BOX_W + OB_Y * 2 )) $(msg_nomarkup ${LIST_FTR}));echo $(msg_markup ${LIST_FTR})
+		else
+			tcup $(( BOX_BOT + 2 )) $(sel_box_center ${BOX_Y_COORD} ${BOX_W} $(msg_nomarkup ${LIST_FTR}));echo $(msg_markup ${LIST_FTR})
+		fi
+	fi
+
+	sel_scroll
+}
+
+sel_norm () {
+	local X=${1}
+	local Y=${2}
+	local TEXT=${3}
+	local F1 F2
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: X:${X} Y:${Y} TEXT:${TEXT}"
+
+	tcup ${X} ${Y}
+	do_rmso
+	if [[ ${_HAS_CAT} == 'true' ]];then
+		F1=$(cut -d: -f1 <<<${TEXT})
+		F2=$(cut -d: -f2 <<<${TEXT})
+		printf "${WHITE_FG}%-*s${RESET} %-*s
" ${_CAT_COLS[1]} ${F1} ${_CAT_COLS[2]} ${F2}
+	else
+		echo ${TEXT}
+	fi
+}
+
+sel_scroll () {
+	local BOT_X=0
+	local KEY=''
+	local NAV=''
+	local NDX=0
+	local NORM_NDX=0
+	local SCROLL=''
+	local TAG_NDX=0
+	local X_OFF=0
+	
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+
+	LIST_X=${_LIST_DATA[X]}
+	BOT_X=$(( _LIST_DATA[X] + _LIST_DATA[MAX] - 1 ))
+	X_OFF=$(( _LIST_DATA[X] - 1 ))
+
+	if [[ -e ${_TAG_FILE}  ]];then
+		read TAG_NDX < ${_TAG_FILE}
+	fi
+
+	[[ ${TAG_NDX} -ne 0 ]] && NDX=${TAG_NDX} || NDX=1 # Initialize index
+	_SEL_VAL=${_LIST[${NDX}]} # Initialize return value
+
+	sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]} # Initial hilite
+
+	while true;do
+		KEY=$(get_keys)
+
+		_SEL_KEY='?'
+
+		# Reserved application key breaks from navigation
+		if [[ ${_APP_KEYS[(i)${KEY}]} -le ${#_APP_KEYS} ]];then # App key was pressed
+			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}KEYPRESS IS APP KEY${RESET}: KEY:${KEY} _APP_KEYS:${_APP_KEYS}"
+
+			_SEL_KEY=${KEY} 
+
+			[[ ${_DEBUG} -gt 0 ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ${WHITE_FG}_SEL_KEY:${_SEL_KEY} _SEL_VAL:${_SEL_VAL}"
+
+			break # Quit navigation
+		fi
+
+		NAV=true # Return only menu selections
+
+		case ${KEY} in
+			0) break;;
+			q) exit_request $(sel_set_ebox);break;;
+			1|u|k) SCROLL="U";;
+			2|d|j) SCROLL="D";;
+			3|t|h) SCROLL="T";;
+			4|b|l) SCROLL="B";;
+			*) NAV=false;;
+		esac
+
+		if [[ ${SCROLL} == 'U' ]];then
+			NORM_NDX=${NDX} && ((NDX--))
+			[[ ${NDX} -lt 1 ]] && NDX=${_LIST_DATA[MAX]}
+			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
+			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
+		elif [[ ${SCROLL} == 'D' ]];then
+			NORM_NDX=${NDX} && ((NDX++))
+			[[ ${NDX} -gt ${_LIST_DATA[MAX]} ]] && NDX=1
+			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
+			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
+		elif [[ ${SCROLL} == 'T' ]];then
+			NORM_NDX=${NDX} && NDX=1
+			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
+			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
+		elif [[ ${SCROLL} == 'B' ]];then
+			NORM_NDX=${NDX} && NDX=${_LIST_DATA[MAX]}
+			sel_norm $((NORM_NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NORM_NDX}]}
+			sel_hilite $((NDX+X_OFF)) ${_LIST_DATA[Y]} ${_LIST[${NDX}]}
+		fi
+
+		if [[ ${NAV} == 'true' ]];then # Return (populate) menu selection
+			_SEL_KEY=${KEY}
+			_SEL_VAL=${_LIST[${NDX}]}
+			[[ -n ${_TAG_FILE} ]] && echo "${NDX}" >${_TAG_FILE}
+		fi
+	done
+	return 0
+}
+
+sel_set_app_keys () {
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: _APP_KEYS:${_APP_KEYS}"
+
+	_APP_KEYS=(${@})
+}
+
+sel_set_ebox () {
+	local -A I_COORDS
+	local MSG_LEN=28
+	local X_ARG=0
+	local Y_ARG=0
+	local W_ARG=0
+	local DIFF=0
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+
+	I_COORDS=($(box_coords_get INNER_BOX))
+	X_ARG=$(( I_COORDS[X] + 1 ))
+	Y_ARG=$(( I_COORDS[Y] - 2 ))
+
+	if	[[ ${I_COORDS[OB_W]} -ne 0 ]];then
+		Y_ARG=$(( I_COORDS[OB_Y] + 2 ))
+		W_ARG=$(( I_COORDS[OB_W] -2 ))
+	elif [[ ${MSG_LEN} -gt ${I_COORDS[W]}  ]];then
+		DIFF=$(( (MSG_LEN - I_COORDS[W]) / 2 ))
+		Y_ARG=$(( I_COORDS[Y] - DIFF ))
+	fi
+
+	echo ${X_ARG} ${Y_ARG} ${W_ARG} 
+}
+
+sel_set_list () {
+	local -a LIST=(${@})
+
+	[[ ${_DEBUG} -ge ${_SEL_LIB_DBG} ]] && dbg "${functrace[1]} called ${0}:${LINENO}: ARGC:${#@}"
+
+	_LIST=(${LIST})
+}
+
