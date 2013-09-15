#!/bin/sh

# a script to check for new mail and notify the user.

PROG=`basename "$0"`
PID=$$

parse_mail () {
  local from=
  local to=
  local subject=
  for arg; do
    from=`sed -n '/^From:/{s/^From:[[:space:]]*//;s/[[:space:]]*<.*$//;p;}' \
      $arg`
    subject=`sed -n '/^Subject:/s/^Subject:\s*//p' $arg`
    echo "$from: $subject"
  done
}

send_note () {
  growlnotify \
    --icon eml \
    --identifier "$PROG" \
    --name "$PROG" \
    --sticky \
    --message "${1:--}" \
    --title "New Mail"
}

daemon () {
  local new=
  while true; do
    new=`find ~/mail -path '*/new/*' -o -regex '.*/cur/.*,[^,S]*' | \
      grep -v ~/mail/spam`
    #find ~/mail -name spam -prune -path '*/new/*' -o -regex '.*/cur/.*,[^,S]*'
    if [ -n "$new" ]; then
      parse_mail $new | send_note
    fi
    sleep 60
  done
}

case "$1" in
  start)
    if psgrep -no pid,ppid,args "$PROG" 2>&1 | grep -qv $PID; then
      echo Already running. >&2
      exit
    else
      echo Starting daemon with PID $$. >&2
      daemon &
    fi
    ;;
  stop)
    process=`psgrep -no pid,ppid,args "$PROG" | grep -v '^\([0-9]\+ \)\?'$PID`
    if [ -z "$process" ]; then
      echo Daemon not running. >&2
      exit 1
    else
      kill ${process%% *}
      exit
    fi
    ;;
  *)
    echo You must say \'start\' or \'stop\'. >&2
    exit 2
    ;;
esac
