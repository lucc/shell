#!/bin/sh
for arg; do
  enc=`file --mime-encoding "$arg"| cut -f 2 -d :`
  new=`mktemp "$0".XXXX`
  iconv -f $enc -t utf8 < "$arg" > "$new"
  if [ `wc -c < "$new"` -ne 0 ]; then
    mv "$new" "$arg"
  else
    rm "$new"
  fi
done

exit

vim -e -s -c 'set backup' \
          -c 'set hidden' \
	  -c 'bufdo set nobomb filetype=utf8' \
	  -c wall \
	  -c quit \
	  "$@"

#!/usr/bin/env vim -e -s -S
#!/usr/bin/env vim -v -T dumb -u NONE -S
"set lazyredraw
set backup
set hidden
bufdo set nobomb filetype=utf8
wall
quit
