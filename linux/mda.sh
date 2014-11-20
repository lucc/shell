#!/bin/sh -x

maildrop ~/.homesick/repos/mail/mailfilter/main

ret=$?

if [ $ret -eq 0 ]; then
  # notify the user
  ~/src/mailtools/check.py -e zsh -e draft -e spam -e header.bak ~/mail | \
    sed 's/^/mytextmailcheckwidget:set_text("/;s/$/")/' | \
    awesome-client
fi

exit $ret
