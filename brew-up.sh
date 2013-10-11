#!/bin/sh

# update the brew program and the formulas
if brew update > /dev/null; then
  for formula in `brew outdated`; do
    brew fetch --deps $formula >/dev/null || \
      echo "Faild to load $formula." >&2
  done
fi
