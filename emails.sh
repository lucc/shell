#!/bin/sh

# This script will take exactly one argument, search the Mac OS X
# AddressBook.app database for matching contacts and display the results.

# FIXME what is the best format to use tabs and newline?

help () {
  local prog=`basename "$0"`
  echo "Usage: $prog [-l|-m] querry-string"
  echo "       $prog -h"
  echo
  echo "List all email addresses matching querry-string from the Mac OSX"
  echo "AddressBook.app.  With -m format output for mutt, with -l like in"
  echo "email headers.  The default is -l."
}

sqlite_query () {
  # $1 needs to be a sql select format.  e has the table ZABCDEMAILADDRESS and
  # r holds the table ZABCDRECORD.
  if echo "$2" | grep "'"; then
    echo Single quotes are not supported in the querry. >&2
    exit 3
  fi
  local db=~/Library/Application\ Support/AddressBook/AddressBook-v22.abcddb
  local query="select $1 from ZABCDRECORD r join ZABCDEMAILADDRESS e
		 on r.Z_PK = e.ZOWNER
	       where r.ZFIRSTNAME like '%$2%' or r.ZLASTNAME like '%$2%' or
		 e.ZADDRESS like '%$2%'
	       order by r.ZFIRSTNAME,r.ZLASTNAME,e.ZADDRESS collate nocase"
  sqlite3 "$db" "$query"
}

email_list_sqlite_query () {
  local format="'\"'||r.ZFIRSTNAME||' '||r.ZLASTNAME||'\" <'||e.ZADDRESS||'>'"
  sqlite_query "$format" "$1"
}

mutt_sqlite_query () {
  local format=$'e.ZADDRESS || "\t" || r.ZFIRSTNAME || " " || r.ZLASTNAME'
  # Mutt expects the first line to be a header line
  echo $'Email\tName'
  sqlite_query "$format" "$1"
}

applescript_query () {
  echo Not yet implemented. >&2

  # TODO Some notes:

  # FIRST TRY
  #
  ##!/usr/bin/osascript
  #on run argv
  #  tell app "Address Book"
  #    properties of emails of (every person whose name contains item 1 of argv)
  #  end tell
  #end run
  # EOF (FIRST TRY)

  # SECOND TRY
  #
  ##!/usr/bin/osascript
  #(*on find_me(the_name)
  #        tell application "Address Book"
  #      	  repeat with thisPerson in (every person whose name contains the_name or emails contains the_name)
  #      		  if name of thisPerson contains the_name or emails of thisPerson contains the_name then
  #      			  set result to name of thisPerson & "
  #"
  #      			  repeat with e_info in emails of thisPerson
  #      				  set result to result & value of e_info & " "
  #      			  end repeat
  #      			  set result to result & "
  #"
  #      			  repeat with p_info in phones of thisPerson
  #      				  set result to result & value of p_info & " "
  #      			  end repeat
  #      			  return result
  #      		  end if
  #      	  end repeat
  #        end tell
  #end find_me
  #*)
  #on myFunc(arg)
  #        tell application "Address Book"
  #      	  repeat with thisPerson in every person
  #      		  if name of thisPerson contains arg or emails of thisPerson contains arg then
  #      			  return name of thisPerson
  #      		  end if
  #      	  end repeat
  #      	  --		set theList to (every person whose name contains arg)
  #      	  --		(*or item in emails contains arg*)
  #        end tell
  #end myFunc
  #
  #on run argv
  #        tell application "Address Book"
  #      	  set theList to every person whose name contains "Lucas"
  #      	  set theEmails to properties of emails of (every person whose name contains "Lucas")
  #      	  set theNames to name of (every person whose name contains "Lucas")
  #      	  --		repeat with theID in theList
  #      	  --			set mails to properties of emails of theID
  #      	  --		end repeat
  #        end tell
  #        myFunc("riegelonl")
  #end run
  # EOF (SECOND TRY)
}

mutt_applescript_query () {
  applescript_query
}

email_list_applescript_query () {
  applescript_query
}

contacts_query () {
  # give exactly two arguments: a format string and a querry string
  contacts -HSsf "$@"
  # -H    supress headers
  # -S    strict formating (no extra space)
  # -s    sort
  # -f    format string
}

sort_function () {
  # Only display entrys which have a email and sort the output
  grep @ | sort --ignore-case --unique "$@"
}

mutt_contacts_query () {
  # query the AddressBook.app database for all possible email addresses
  # mutt expects the first line to be a header line.
  echo $'Email\tName'
  # The format for mutt is <email-address><tab><name>
  contacts_query $'%he\t%n\n%we\t%n\n%%oe\t%n' "$1" | \
    sort_function --field-separator=$'\t' --key=1
}

email_list_contacts_query () {
  contacts_query $'"%n" <%he>\n"%n" <%we>\n"%n" <%oe>' "$1" | sort_function
}

engine=sqlite
format=email_list

while getopts hacslm FLAG; do
  case $FLAG in
    h) help; exit;;
    a) engine=applescript;;
    c) engine=contacts;;
    s) engine=sqlite;;
    m) format=mutt;;
    l) format=email_list;;
    *) echo ERROR >&2; exit 2;;
  esac
done
shift $((OPTIND-1))

eval ${format}_${engine}_query '"$1"'
