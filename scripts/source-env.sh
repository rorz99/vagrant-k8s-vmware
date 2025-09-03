COLOR() {
  export RED='\033[1;31m'
  export GREEN='\033[1;32m'
  export YELLOW='\033[1;33m'
  export BLUE='\033[1;34m'
  export NC='\033[0m\n'
  export INFO='\033[0;34mINFO: \033[0m'
  export ERROR='\033[1;31mERROR: \033[0m'
  export SUCCESS='\033[1;32mSUCCESS: \033[0m'
  export DATE=$(date +%Y-%m-%d)
  export TIME=$(date +%Y%m%d_%H%M%S)
}
COLOR

LOGFILE() {
  #ST=`date +%Y%m%d_%H%M%S`
  st=$(date +%s)
  [[ -d /logs ]] || mkdir /logs
  LOGFILE="/logs/$(basename "$0")-$HOSTNAME-$TIME.log"
  chmod 1777 /logs
}
LOGFILE

LFON() {
  LOGFILE
  exec &> >(tee -ia "$LOGFILE") 2>&1
}

CMD() {
  comment=$1
  shift
  time=$(date +%Y-%m%d-%H:%M:%S)
  printf "%s${BLUE}$time Comment:$comment PATH:$PWD$NC     CMD:$GREEN$* $NC\n"
  eval "$*" && echo "$time $*" >>"/logs/command.history.$HOSTNAME.log"
}

AT() {
  printf "%s \n$GREEN$(date +%Y-%m%d-%H:%M:%S) Attention:$1 $NC"
}

YAT() {
  printf "%s \n$YELLOW$(date +%Y-%m%d-%H:%M:%S) Attention:$1 $NC\n"
}

ERR() {
  printf "%s \n$RED$(date +%Y-%m%d-%H:%M:%S) Error:$1\n $NC"
  exit 1
}

chk_add_if_not_exist() {
  file=$1
  key=$2
  update=$3
  grep "$key" "$file" &>/dev/null || echo "$update" >>"$file"
}

Prompt() {
  export PS1="\[\e[01;32m\]\u@\h\[\e[0m\]:\[\e[01;34m\]\w\[\e[1;31m\]\\$\[\e[0m\]"
}

Pscom() {
  export HISTTIMEFORMAT="%Z-%Y-%m%d-%H%M%S "
  WHO="$USER@$(who am i | awk -F[\(\)] '{print $2}')"
  export PROMPT_COMMAND='{ RC=$?; history 1 | { read s TIME PCMD; echo "$TIME ### $WHO RC=$RC ## $PCMD"; } |tee -a /var/log/command.log; } |logger -p local6.debug'
}

export -f COLOR CMD AT ERR YAT LOGFILE LFON chk_add_if_not_exist Prompt Pscom
