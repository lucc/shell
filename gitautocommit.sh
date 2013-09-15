#!/bin/sh

alias git='git --work-tree="$arg" --git-dir="$arg"/.git'
pwd
for arg; do
  if [ -d "$arg" ]; then
    if [ "`git status --short --untracked-files=no`" != "" ]; then
      git commit --all --message=autocomit
    fi
  fi
done
