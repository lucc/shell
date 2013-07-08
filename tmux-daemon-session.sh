#!/bin/sh

# bla
#

sessionname=daemon

new_window  () { tmux new-window  -d "$@"; }
new_session () { tmux new-session -d -s $sessionname "$@"; }

if tmux has-session -t $sessionname >/dev/null 2>&1; then
  windows=`tmux list-windows -t $sessionname | cut -f 2 -d ' ' | sed 's/[*-]$//g'`
  if ! echo "$windows" | grep -q torrent; then
    tmux new-window -d -n torrent rtorrent
  fi
  if ! echo "$windows" | grep -q music; then
    tmux new-window -d -n music 'mpd --no-daemon'
  fi
else
  tmux new-session -d -n torrent -s $sessionname rtorrent
  # FIXME: this does not work. The window exits right away but mpd is
  # still there.
  tmux new-window -t $sessionname -n music 'mpd --no-daemon'
fi

