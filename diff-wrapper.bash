#!/bin/bash

# An intelligent wrapper around different diff versions.

prog=${0##*/}
version=0.1

usage () {
  echo "Usage: $prog [diff-options] [files]"
  echo "       $prog [git-diff-options] [git-diff-arguments]"
  echo "       $prog [hg-diff-options] [hg-diff-arguments]"
  echo "       $prog [svn-diff-options] [svn-diff-arguments]"
  echo "       $prog --help"
  echo "       $prog --version"
}
help () {
  echo TOOD
}
diff_wrapper () {
  diff "$@"
}
git_diff_wrapper () {
  git diff "$@"
}
hg_diff_wrapper () {
  hg diff "$@"
}
svn_diff_wrapper () {
  svn diff "$@"
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
  help
  exit
elif [[ "$1" == --version ]]; then
  echo "$prog $version"
fi
options=()
while [[ $# -ne 0 ]]; do
  case "$1" in
    --) shift; break;;
    -*) options+="$1"; shift;;
    *) break;;
  esac
done

if [[ $# -eq 2 && -e "$1" && -e "$2" ]]; then
  diff_wrapper "${options[@]}" "$@"
elif [[ $# -eq 3 && -e "$1" && -e "$2" && -e "$3" ]]; then
  diff_wrapper "${options[@]}" "$@"
else
  # We are problably in a version control repository.
  if is_git_dir; then
    git_diff_wrapper "${options[@]}" "$@"
  elif is_mercurial_dir; then
    hg_diff_wrapper "${options[@]}" "$@"
  elif is_subversion_dir; then
    svn_diff_wrapper "${options[@]}" "$@"
  else  # Fallback to normal diff.
    diff_wrapper "${options[@]}" "$@"
  fi
fi
