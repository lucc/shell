#!/bin/sh

# from http://reviews.cnet.com/8301-13727_7-57598167-263/how-to-encrypt-a-file-from-the-os-x-command-line/

hdiutil create -srcfolder SOURCEPATH -encryption AES-128 DESTINATIONDMG

# AES-256 does also work
