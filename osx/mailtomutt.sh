#!/bin/sh -x

tmp=`mktemp -t mailtomutt.$$.XXXXXX`
echo '#!/bin/sh' > "$tmp"
echo "/usr/local/bin/mutt -H '$@'" >> "$tmp"

osascript -e "on run argv
  set filename to item 1 of argv
  tell application \"iTerm\"
    activate
    tell the first terminal to set mysession to ¬
      (make new session at the end of sessions)
    tell mysession
      set name to \"mutt\"
      exec command \"$file\"
    end tell
  end tell
end run"

rm -f "$tmp"
