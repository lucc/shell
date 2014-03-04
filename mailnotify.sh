#!/bin/sh

# a script to check for new mail and notify the user.

PROG=`basename "$0"`
sender=growl

parse_sed () {
  sed -nEe \
    '
     # parse the From: field
     /^From:/{
       # clean up the From: field
       s/^From:[[:space:]]*//
       s/[[:space:]]*<.*$//
       s/^"//
       s/"$//
       s/$/:/
       # look for a saved Subject: field in the hold space
       x
       # without a saved Subject: field go for the next line (From: field was
       # saved)
       /^$/ b
       # else append the Subject: filed to the hold space (From: field)
       H
       # retrive the hold space, print everything and quit
       g;p;q
     }
     # parse the Subject: field
     /^Subject:/{
       # clean up the Subject: field
       s/^Subject:[[:space:]]*((AW|Aw|Re|Fwd|FWD):[[:space:]])*//
       # look for a saved From: field in the hold space
       x
       # without a saved From: field go for the next line (Subject: field was
       # saved)
       /^$/ b
       # else append the Subject: filed to the pattern (From: field)
       G
       # print everything and quit
       p;q
     }
     # stop at the end of the email header
     /^$/{
       # print the contents of the hold space befor quitting
       g;p
       q
     }
    '
}

parse_awk () {
  awk \
  '
  BEGIN {
    from = ""
    subject = ""
  }
  /^Subject:/ {
    sub("^Subject:[[:space:]]*((AW|Aw|Re|Fwd|FWD):[[:space:]])*", "")
    subject = $0
  }
  /^From:/ {
    sub("^From:[[:space:]]*", "")
    sub("[[:space:]]*<.*$", "")
    sub("^\"", "")
    sub("\"$", "")
    from = $0
  }
  {
    if (from != "" && subject != "") {
      print from ":\n" subject "\n"
      from = ""
      subject = ""
      if (ARGC == 0) {
	exit
      } else {
        ARGC--
	nextfile
      }
    }
  }
  '
}

parse_from_field_sed () {
  sed -n -E -e \
    '# Clean up the From: field.
    /^(From|FROM):/{
       # remove field name
       s/^(From|FROM):[[:space:]]*//

       # remove email address in angle brackets at the end
       s/[[:space:]]*<.*$//
       # remove quotes
       s/^"//
       s/"$//

       # print the result
       p
     }'
}

# s/(("|')?)(.*)\1

parse_subject_field_sed () {
  sed -n -E -e \
    '# Clean up the Subject: filed.
    /^(Subject|SUBJECT):/{
      s/^(Subject|SUBJECT):[[:space:]]*((AW|Aw|Re|Fwd|FWD):[[:space:]])*//
       p
     }'
}

parse_mail () {
  local from=
  local to=
  local subject=
  for arg; do
    from=`parse_from_field_sed <"$arg"`
    subject=`parse_subject_field_sed <"$arg"`
    if [ $((${#from} + ${#subject} + 2)) -le 20 ]; then
      echo "$from: $subject"
    else
      echo "$from:"
      echo "$subject"
    fi
    echo
  done
}

parse_mail2 () {
  if [ $# -ge 1 ]; then
    parse_sed < "$1"
    shift
  fi
  for arg; do
    echo
    parse_sed < "$arg"
  done
}

terminal_notify_wrapper () {
  terminal-notifier                                            \
    -sender com.apple.mail                                     \
    -group "$PROG"                                             \
    -title "New Mail"                                          \
    -execute "$HOME/src/shell/iterm-session.scpt Default mutt" \
    "$@"
}
send_note_apple () {
  if [ $# -eq 0 ]; then
    terminal_notify_wrapper -message -
  else
    terminal_notify_wrapper -message "$*"
  fi
}

send_note_growl () {
  growlnotify            \
    --icon eml           \
    --identifier "$PROG" \
    --name "$PROG"       \
    --message "${1:--}"  \
    --title "New Mail"

  #  --sticky \
}

send_general_notification () {
  send_note_apple "You have $1 unread messages."
}

remove_general_notification () {
  terminal-notifier                                            \
    -sender com.apple.mail                                     \
    -remove "$PROG"
}

debug_stuff () {
  local logfile=~/log/mailnotify.log
  date +%F-%T\ new=$new >> $logfile
  ls -Tld                        \
    ~/mail                       \
    ~/mail/gmx/new               \
    ~/mail/inbox/new             \
    ~/mail/landheim/new          \
    ~/mail/lists/grillchill/new  \
    ~/mail/lists/tanzhans/new    \
    ~/mail/sammersee/current/new \
    ~/mail/uni/mathe/new         \
  >> $logfile
  date +%F-%T\ new=$new >> $logfile.pstree
  /usr/local/bin/pstree >> $logfile.pstree
}

find_new_mail () {
  # old version
  #find ~/mail -path '*/new/*' -o -regex '.*/cur/.*,[^,S]*' | \
  #  grep -v ~/mail/spam | grep -v ~/mail/lists/zsh

  # new version
  find ~/mail                   \
    \(                          \
      -type d                   \
      -name spam -o             \
      -name draft -o            \
      -path ~/mail/lists/zsh    \
    \)                          \
    -prune -o                   \
    \(                          \
      -path '*/new/*' -o        \
      -regex '.*/cur/.*,[^,S]*' \
    \)                          \
    -print
}

while getopts aghm: FLAG; do
  case $FLAG in
    a) sender=apple;;
    g) sender=growl;;
    h) help; exit;;
    m) MAIL_DIR="$OPTARG";;
  esac
done

# new version
new=`find_new_mail`


if [ -n "$new" ]; then
  parse_mail $new | send_note_$sender
  send_general_notification `echo "$new" | wc -l`
  new=true
else
  #remove_general_notification
  new=false
fi
#debug_stuff
# # this script will now be called by a launchd job, so we already know that
# # there are mails and do not need to test.
# parse_mail $new | send_note
