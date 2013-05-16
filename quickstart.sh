#!/bin/sh
# A script to quickly start several programs.

STARTGUI=true

ask_terminal () {
  local answer=
  echo "Do you want a full start? [Y|n]"
  read answer
  [ "$answer" = "" -o "$answer" = y -o "$answer" = Y ]
}

case `uname` in
  Darwin)
    ask_gui () {
      osascript -e 'tell application "System Events" 
	activate
	-- If the user does not answer for 60 secs, assume "yes".
	display dialog "Do you want a full start?" giving up after 60
	end tell'
    }
    guis () {
      open -ga iTerm
      open -ga MacVim
      open -g  http://luc42.lima-city.de
      open -ga iTunes
      open -ga iCal
      osascript -e 'tell application "Skype"
	send command "SET USERSTATUS INVISIBLE" script name "quickstart.sh"
	delay 2
	close every window
	end tell'
    }
    ;;
  *)
    ask () {
      :
    }
    guis () {
      :
    }
    ;;
esac

# start several daemons

# start the torrent daemon
if ! tmux has-session -t daemon; then
  # TODO: try screen or dtach instead of tmux
  tmux new-session -d -n torrent -s daemon rtorrent
  #tmux new-window -t daemon -n music mpg123
fi

# mount the netrc file and then start the fetchmail daemon to retrieve mail
( secure.sh -gm && fetchmail ) &

# ask the user if we should start some programs for him
if [ "$1" = --ask ]; then
  if [ -t 0 ]; then
    ask=ask_terminal
  else
    ask=ask_gui
  fi
else
  ask=true
fi

# start gui stuff
if $ask; then guis; fi
