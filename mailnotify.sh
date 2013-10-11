#!/bin/sh

# a script to check for new mail and notify the user.

PROG=`basename "$0"`

parse () {
  sed -nEe \
    '
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
       x;p;q
     }
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
    '
}

parse2 () {
  sed -nEe \
    '
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
       x;p
       q
     }
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
       p
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

parse_from_field () {
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
#
# s/(("|')?)(.*)\1
#
#
#
#
#

parse_subject_field () {
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
    from=`parse_from_field <"$arg"`
    subject=`parse_subject_field <"$arg"`
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
    parse < "$1"
    shift
  fi
  for arg; do
    echo
    parse < "$arg"
  done
}

send_note () {
  growlnotify \
    --icon eml \
    --identifier "$PROG" \
    --name "$PROG" \
    --message "${1:--}" \
    --title "New Mail"

  #  --sticky \
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

new=`find ~/mail -path '*/new/*' -o -regex '.*/cur/.*,[^,S]*' | \
  grep -v ~/mail/spam`
#find ~/mail -name spam -prune -path '*/new/*' -o -regex '.*/cur/.*,[^,S]*'


if [ -n "$new" ]; then
  parse_mail $new | send_note
  new=true
else
  new=false
fi
debug_stuff
# # this script will now be called by a launchd job, so we already know that
# # there are mails and do not need to test.
# parse_mail $new | send_note
