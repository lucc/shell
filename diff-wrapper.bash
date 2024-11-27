#!/usr/bin/env bash

# An intelligent wrapper around different diff versions.

prog=${0##*/}
version=0.2

usage () {
  echo "Usage: $prog [diff-options] [files]"
  echo "       $prog [git-diff-options] [git-diff-arguments]"
  echo "       $prog [hg-diff-options] [hg-diff-arguments]"
  echo "       $prog [svn-diff-options] [svn-diff-arguments]"
  echo "       $prog --help"
  echo "       $prog --version"
}
diff_wrapper () {
  if [[ $# -lt 2 && -t 0 ]]; then
    echo "Error: Please specify at least two files." >&2
    exit 2
  elif which colordiff &>/dev/null; then
    exec colordiff --nobanner "$@"
  else
    exec diff "$@"
  fi
}
is_git_dir () {
  [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == true ]]
}
is_mercurial_dir () {
  hg -q stat 2>/dev/null
}
is_subversion_dir () {
  false # TODO
}
if [[ "$1" == --help ]]; then
  usage
  exit
elif [[ "$1" == --version ]]; then
  echo "$prog $version"
fi
options=()
while [[ $# -ne 0 ]]; do
  case "$1" in
    --) shift; break;;
    -*) options+=("$1"); shift;;
    *) break;;
  esac
done

if [[ $# -eq 2 && -e "$1" && -e "$2" ]] || \
   [[ $# -eq 3 && -e "$1" && -e "$2" && -e "$3" ]]; then
  diff_wrapper "${options[@]}" "$@"
else
  # We are probably in a version control repository.
  if is_git_dir; then
    exec git diff --irreversible-delete "${options[@]}" "$@"
  elif is_mercurial_dir; then
    exec hg diff "${options[@]}" "$@"
  elif is_subversion_dir; then
    exec svn diff "${options[@]}" "$@"
  else  # Fallback to normal diff.
    diff_wrapper "${options[@]}" "$@"
  fi
fi
