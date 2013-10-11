#!/bin/sh

# For each argument that is a directory with a git repository, commit
# all changes and label them "autocomit".

for arg; do
  git                     \
    --work-tree="$arg"    \
    --git-dir="$arg"/.git \
    commit                \
    --all                 \
    --message=autocomit
done
