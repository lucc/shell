#!/bin/sh

# a script to check for new mail and notify the user.

PROG=`basename "$0"`
ID="$PROG-$$-$RANDOM"
PID=$$
TMP=`mktemp -t "$PROG".XXXXX`

new_mail () {
  find ~/mail -name spam -prune -path '*/new/*' -o -regex '.*/cur/.*,[^,S]*'
}

parse_mail () {
  local from=
  local to=
  local subject=
  for arg; do
    from=`sed -n '/^From:/{s/^From:[[:space:]]*//;s/[[:space:]]*<.*$//;p;}' $arg`
    subject=`sed -n '/^Subject:/s/^Subject:\s*//p' $arg`
    echo "$from: $subject"
  done
}

send_note () {
  growlnotify \
    --icon eml \
    --identifier "$ID" \
    --name "$PROG" \
    --sticky \
    --message "${1:--}" \
    --title "New Mail"
}

daemon () {
  local new=
  while true; do
    new=`new_mail`
    if [ -n "$new" ]; then
      parse_mail $new | send_note
    fi
    sleep 60
  done
}

running () {
  psgrep -no pid,ppid,args "$PROG" 2>&1 | grep -v $PID
}

start () {
  echo Starting daemon with PID $$ >&2
  daemon &
}

stop () {
  local string=`psgrep -no pid,ppid,args "$PROG" | \
    grep -v '^\([0-9]\+ \)\?'$PID`
  if [ -z "$string" ]; then
    echo Daemon not running. >&2
    exit 1
  else
    kill ${string%% *}
    exit
  fi
}

case "$1" in
  start)
    if psgrep -no pid,ppid,args "$PROG" 2>&1 | grep -v $PID; then
      echo Already running. >&2
      exit
    else
      start
    fi
    ;;
  stop)
    stop
    ;;
  *)
    echo You must say \'start\' or \'stop\'. >&2
    exit 2
    ;;
esac
