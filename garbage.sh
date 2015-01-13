#!/bin/sh

while ! read -t 1; do
  head -c 1000000 /dev/urandom | hexdump -C | grep --color=auto "42.*42.*42"
done
