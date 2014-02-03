#!/bin/sh -e

while lpq|grep $USER > /dev/null ; do
  if [ `lpq -a|grep $USER` != `sleep 2 && lpq -a|grep $USER` ] && [ $((lpq|wc -l)) -lt 18 ]
  then lpq
  else lpq|grep $USER
  fi
done

