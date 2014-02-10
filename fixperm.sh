#!/bin/sh
#
# change the permissions and extendet file attributes for the given files and
# directories or the current directory.  Always work recursivly.

# if no arguments are given work on the current directory
if [ $# -eq 0 ]; then set .; fi

# set unix file permissions
find "$@"                                \
  \( -type f -exec chmod 600 {} + \) -or \
  \( -type d -exec chmod 700 {} + \)

# delete apples extendet file attributes
for attribute in com.apple.quarantine com.apple.FinderInfo; do
  xattr -rd $attribute "$@"
done
