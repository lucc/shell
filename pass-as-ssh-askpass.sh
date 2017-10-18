#!/bin/sh

file=$*
file=${file%: }
file=${file#Enter passphrase for }
if [ ! -f "$file" ]; then
  file=${file#Bad passphrase, try again for }
fi
id=${file##*/}
id=${id%.id_rsa}

pass show ssh/"$id" 2>/dev/null || pass show ssh/id
