#!/bin/sh

# This script will take exactly one argument, search the Mac OS X
# AddressBook.app database for matching contacts and display all results in
# the default format for mutt:
# <email-address><tab><name>

# FIXME what is the best format to use tabs and newline?
#TAB="`printf '\t'`"
#NL="`printf '\n'`"

querry () {
  # give exactly two arguments: a format string and a querry string
  contacts -HSsf "$@"
  # -H    supress headers
  # -S    strict formating (no extra space)
  # -s    sort
  # -f    format string
}

sort_function () { grep @ | sort --ignore-case --unique "$@"; }

mutt_querry () {
  # query the AddressBook.app database for all possible email addresses
  # mutt expects the first line to be a header line.
  echo $'Email\tName'
  querry $'%he\t%n\n%we\t%n\n%%oe\t%n' "$1" | \
    sort_function --field-separator=$'\t' --key=1
}

email_list () {
  querry $'"%n" <%he>\n"%n" <%we>\n"%n" <%oe>' | sort_function
}
