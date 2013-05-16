#!/bin/sh

# This script will take exactly one argument, search the Mac OS X
# AddressBook.app database for matching contacts and display all results in
# the default format for mutt:
# <email-address><tab><name>

# mutt expects the first line to be a header line.
echo "Email	Name"

# query the AddressBook.app database for all possible email addresses
(
  contacts -HSsf '%he	%n' "$1"
  contacts -HSsf '%we	%n' "$1"
  contacts -HsSf '%oe	%n' "$1"
) | grep @ | sort --ignore-case --unique --field-separator='	' --key=1
