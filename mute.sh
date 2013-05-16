#!/bin/sh

if [ `uname` = Darwin ] && which osascript > /dev/null; then
  osascript -e "set Volume 0"
else
  echo 'I can not set the volume on your system!' >&2
  exit 1
fi
##############################################################################
# ERLÄUTERUNG:                                                               #
#                                                                            #
# Die erste Zeile sagt wer diese Datei lesen und verarbeiten soll            #
# In der zweiten Zeile steht der Name eines Programms: 'osascript'. Dieses   #
# Programm ist dazu da Apple-Skripte auszuführen. '-e' ist eine Option die   #
# dem Programm sagt was es machen soll nämlich 'execute' also ausführen.     #
# Und was? Natürlich den Ausdruck in Anführungsstrichen. Der ist jetzt in    #
# der Apple-Skript-Sprache geschrieben.                                      #
##############################################################################

##############################################################################
# AKTIVIERUNG:                                                               #
# sudo defaults read com.apple.loginwindow                                   #
# sudo defaults write com.apple.loginwindow LogoutHook /Users/lucas/mute.sh  #
##############################################################################
