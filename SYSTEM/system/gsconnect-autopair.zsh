#!/usr/bin/zsh

# Constants
AUTOPAIR_CFG=~/.local/share/gsconnect-autopair
AUTOPAIR_LOG=${AUTOPAIR_CFG}/gsconnect-autopair.log
_DEVICE_IS_PAIRED=false
_TARGET_ID=''
_TARGET_IP="192.168.18.105"
_TARGET_NAME="Xiaomi 14T"

# Functions
execution_section () {
  if target_is_device; then
    pair_phone ${_TARGET_ID}
  fi
  return 0 # Always return success
}

logit () {
    local -a MSG=(${@})
    local STAMP=$(date +'%Y-%m-%d_%H:%M:')
    echo "${STAMP} ${MSG}" >> ${AUTOPAIR_LOG}
}

pair_phone () {
  local TARGET_ID=${1}
  local MSG=''

  [[ ${_DEVICE_IS_PAIRED} == 'true' ]] && return

  logit "Attempting to pair ${TARGET_ID}..."

  MSG=$(kdeconnect-cli --pair -d "${TARGET_ID}" 2>&1)

  logit ${MSG}
}

target_is_device () {
  local LIST=("${(f)$(kdeconnect-cli -l 2>/dev/null | sed -e 's/\x2D\x20//' -e 's/\x3A\x20/\x3A/' -e 's/\x20\x28/\x3A\x28/')}")
  local NAME=''
  local ID=''
  local STATE=''
  local L

  for L in ${LIST};do
    IFS=':';read NAME ID STATE <<<${L};IFS=' '
    if [[ ${NAME:l} == ${_TARGET_NAME:l} ]];then
      logit "kdeconnect found device:${NAME}, ID:${ID}, STATE:${STATE}"
      _TARGET_ID=${ID}
      [[ ${STATE:l} =~ 'paired' ]] && _DEVICE_IS_PAIRED=true || _DEVICE_IS_PAIRED=false
      return 0
    fi
  done

  logit "Device:${_TARGET_NAME} not visible to kdeconnect"
  return 1
}

# Clean systemd shutdown handler
cleanup () {
  logit "Stopping script via systemd request. Exiting cleanly."
  exit 0
}

# Capture termination signals from systemd (SIGINT/SIGTERM)
trap cleanup SIGINT SIGTERM

# Execution
mkdir -p ${AUTOPAIR_CFG}
/bin/rm -f ${AUTOPAIR_LOG}

logit "Starting GSConnect auto-pair daemon..."

while true;do
  execution_section
  sleep 5
done
