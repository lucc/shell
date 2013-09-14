#!/bin/sh

alias git='git --work-tree=$HOME/.config --git-dir=$HOME/.config/.git'

if [ "`git status --silent --untracked-files=no`" != "" ]; then
  git commit --all --message=autocomit
fi
