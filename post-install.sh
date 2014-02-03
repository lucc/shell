#!/bin/sh

# Variables to use
XORG=
MEDIA=
BROWSER=
CLI_APPS=
DEVEL=
EDITOR=
CMD=

case `uname` in
  Darwin)
    CMD_UPDATE="brew update"
    CMD_UPGRADE="brew upgrade"
    CMD_INSTALL="brew install"
    ;;
  Linux)
    # debian
    CMD_UPDATE="apt-get update"
    CMD_UPGRADE="apt-get upgrade"
    CMD_INSTALL="apt-get install"
    # arch
    CMD_UPDATE="pacman -Sy"
    CMD_UPGRADE="pacman -Su"
    CMD_INSTALL="pacman -S"
    ;;
esac

echo "Outline:"
echo "1. X.org server and related stuff"
echo "2. Editors"
echo "3. CLI apps"
echo "4. Development (compilers etc)"
echo "5. Browsers"
echo "6. Media stuff"
echo "7. config files"
echo "8. 
