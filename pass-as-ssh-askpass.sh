#!/bin/sh

set -e

# First extract the file name from the command line arguments.
file=$*
file=${file%: }
file=${file#Enter passphrase for }
if [ ! -f "$file" ]; then
  file=${file#Bad passphrase, try again for }
fi

# Check that we did find the file name.
if [ ! -f "$file" ]; then
  echo "Error: can not find file name of the key file in '$*'." >&2
  exit 1
fi

# Try the file name as the id in the password store.
id=${file##*/}
id=${id%.id_rsa}
if ! pass show ssh/"$id" 2>/dev/null; then
  # If that fails, extract the comment from the ssh key and try that as an id
  # in the password store.
  id=$(cut -f3- -d ' ' < "$file".pub)
  pass show ssh/"$id"
fi
