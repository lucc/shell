#!/bin/sh

# This script will take exactly one argument, search the Mac OS X
# AddressBook.app database for matching contacts and display all results in
# the default format for emails:
#       "Name <email-address>"

# BUG? sort complains:
#      sort: string comparison failed: Illegal byte sequence
#      sort: Set LC_ALL='C' to work around the problem.
# so we have to set the environment variable here.
# FIXME: Will this mess up the sorting?
export LC_ALL=C

# query the AddressBook.app database for all possible email addresses
(
  contacts -HSsf '"%n <%he>"' "$1"
  contacts -HSsf '"%n <%we>"' "$1"
  contacts -HSsf '"%n <%oe>"' "$1"
) | grep @ | sort -i
