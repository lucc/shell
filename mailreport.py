#!/usr/bin/env python3

# a script to check for new mail and notify the user.

from email.header import decode_header
import email.parser
import sys
import os.path
import gntp.notifier
import re
def is_maildir(directory):
    isdir = os.path.isdir
    join = os.path.join
    return isdir(directory) and isdir(join(directory, 'new')) and \
            isdir(join(directory, 'cur')) and isdir(join(directory, 'tmp'))

def find_new_mail(directory):
    parser = email.parser.Parser()
    for item in os.walk(directory):
        if 'spam' in item[1]:
            item[1].remove('spam')
        elif set(item[1]) == {'cur', 'new', 'tmp'}:
            item[1].remove('cur')
            item[1].remove('tmp')
        if os.path.basename(item[0]) == 'new' and item[2] != []:
            for fname in item[2]:
                with open(os.path.join(item[0], fname)) as fp:
                    msg = parser.parse(fp)
                    from_list = decode_header(msg.get('from'))
                    subject_list = decode_header(msg.get('subject'))
                    From = ''
                    Subject = ''
                    for array, encoding in from_list:
                        if type(array) is type(str()):
                            From += array
                        elif encoding is None:
                            From += array.decode()
                        else:
                            From += array.decode(encoding)
                    for array, encoding in subject_list:
                        if type(array) is type(str()):
                            Subject += array
                        elif encoding is None:
                            Subject += array.decode()
                        else:
                            Subject += array.decode(encoding)
                    Subject = re.sub(r'^\s*((AW|Aw|RE|Re):)*\s*', '', Subject)
                    #From
                    yield (From, Subject)

for f,s in find_new_mail('/Users/luc/mail'):
    gntp.notifier.mini(f + ': ' +s)




#parse () {
#  sed -nEe \
#    '
#     /^From:/{
#       # clean up the From: field
#       s/^From:[[:space:]]*//
#       s/[[:space:]]*<.*$//
#       s/^"//
#       s/"$//
#       s/$/:/
#       # look for a saved Subject: field in the hold space
#       x
#       # without a saved Subject: field go for the next line (From: field was
#       # saved)
#       /^$/ b
#       # else append the Subject: filed to the hold space (From: field)
#       H
#       # retrive the hold space, print everything and quit
#       x;p;q
#     }
#     /^Subject:/{
#       # clean up the Subject: field
#       s/^Subject:[[:space:]]*((AW|Aw|Re|Fwd|FWD):[[:space:]])*//
#       # look for a saved From: field in the hold space
#       x
#       # without a saved From: field go for the next line (Subject: field was
#       # saved)
#       /^$/ b
#       # else append the Subject: filed to the pattern (From: field)
#       G
#       # print everything and quit
#       p;q
#     }
#    '
#}
#
#parse2 () {
#  sed -nEe \
#    '
#     /^From:/{
#       # clean up the From: field
#       s/^From:[[:space:]]*//
#       s/[[:space:]]*<.*$//
#       s/^"//
#       s/"$//
#       s/$/:/
#       # look for a saved Subject: field in the hold space
#       x
#       # without a saved Subject: field go for the next line (From: field was
#       # saved)
#       /^$/ b
#       # else append the Subject: filed to the hold space (From: field)
#       H
#       # retrive the hold space, print everything and quit
#       x;p
#       q
#     }
#     /^Subject:/{
#       # clean up the Subject: field
#       s/^Subject:[[:space:]]*((AW|Aw|Re|Fwd|FWD):[[:space:]])*//
#       # look for a saved From: field in the hold space
#       x
#       # without a saved From: field go for the next line (Subject: field was
#       # saved)
#       /^$/ b
#       # else append the Subject: filed to the pattern (From: field)
#       G
#       # print everything and quit
#       p
#       q
#     }
#    '
#}
#
#parse_awk () {
#  awk \
#  '
#  BEGIN {
#    from = ""
#    subject = ""
#  }
#  /^Subject:/ {
#    sub("^Subject:[[:space:]]*((AW|Aw|Re|Fwd|FWD):[[:space:]])*", "")
#    subject = $0
#  }
#  /^From:/ {
#    sub("^From:[[:space:]]*", "")
#    sub("[[:space:]]*<.*$", "")
#    sub("^\"", "")
#    sub("\"$", "")
#    from = $0
#  }
#  {
#    if (from != "" && subject != "") {
#      print from ":\n" subject "\n"
#      from = ""
#      subject = ""
#      if (ARGC == 0) {
#	exit
#      } else {
#        ARGC--
#	nextfile
#      }
#    }
#  }
#  '
#}
#
#parse_from_field () {
#  sed -n -E -e \
#    '# Clean up the From: field.
#    /^(From|FROM):/{
#       # remove field name
#       s/^(From|FROM):[[:space:]]*//
#
#       # remove email address in angle brackets at the end
#       s/[[:space:]]*<.*$//
#       # remove quotes
#       s/^"//
#       s/"$//
#
#       # print the result
#       p
#     }'
#}
##
## s/(("|')?)(.*)\1
##
##
##
##
##
#
#parse_subject_field () {
#  sed -n -E -e \
#    '# Clean up the Subject: filed.
#    /^(Subject|SUBJECT):/{
#      s/^(Subject|SUBJECT):[[:space:]]*((AW|Aw|Re|Fwd|FWD):[[:space:]])*//
#       p
#     }'
#}
#
#parse_mail () {
#  local from=
#  local to=
#  local subject=
#  for arg; do
#    from=`parse_from_field <"$arg"`
#    subject=`parse_subject_field <"$arg"`
#    if [ $((${#from} + ${#subject} + 2)) -le 20 ]; then
#      echo "$from: $subject"
#    else
#      echo "$from:"
#      echo "$subject"
#    fi
#    echo
#  done
#}
#
#parse_mail2 () {
#  if [ $# -ge 1 ]; then
#    parse < "$1"
#    shift
#  fi
#  for arg; do
#    echo
#    parse < "$arg"
#  done
#}
#
#send_note () {
#  growlnotify \
#    --icon eml \
#    --identifier "$PROG" \
#    --name "$PROG" \
#    --message "${1:--}" \
#    --title "New Mail"
#
#  #  --sticky \
#}
#
#debug_stuff () {
#  local logfile=~/log/mailnotify.log
#  date +%F-%T\ new=$new >> $logfile
#  ls -Tld                        \
#    ~/mail                       \
#    ~/mail/gmx/new               \
#    ~/mail/inbox/new             \
#    ~/mail/landheim/new          \
#    ~/mail/lists/grillchill/new  \
#    ~/mail/lists/tanzhans/new    \
#    ~/mail/sammersee/current/new \
#    ~/mail/uni/mathe/new         \
#  >> $logfile
#  date +%F-%T\ new=$new >> $logfile.pstree
#  /usr/local/bin/pstree >> $logfile.pstree
#}
#
#new=`find ~/mail -path '*/new/*' -o -regex '.*/cur/.*,[^,S]*' | \
#  grep -v ~/mail/spam`
##find ~/mail -name spam -prune -path '*/new/*' -o -regex '.*/cur/.*,[^,S]*'
#
#
#if [ -n "$new" ]; then
#  parse_mail $new | send_note
#  new=true
#else
#  new=false
#fi
#debug_stuff
## # this script will now be called by a launchd job, so we already know that
## # there are mails and do not need to test.
## parse_mail $new | send_note
