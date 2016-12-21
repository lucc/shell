#!/bin/sh

# A small script to handle urls for urxvt.  All it does is to prepend
# "http://" to urls that start with "www." as urxvt considers them urls but
# xdg-open considers them to be file names and can not find them.

case $1 in
  *://*) xdg-open "$1";;
  www.*) xdg-open "http://$1";;
  *) echo "Unknown url type: $1" >&2; exit 2;;
esac
