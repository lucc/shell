#!/usr/bin/python

import argparse
import subprocess
import sys

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers()
decode = subparsers.add_parser('decode', help='decode stdin')
decode.set_defaults(command='-d')
encode = subparsers.add_parser('encode', help='encode stdin')
decode.set_defaults(command='-e')
sign = subparsers.add_parser('sing', help='sign stdin')
decode.set_defaults(command='-s')
import_ = subparsers.add_parser(
    'import',
    help='import a new key from a file or a key server')
decode.set_defaults(command='--import')
update = subparsers.add_parser('update', help='update the keyring')
decode.set_defaults(command='--update-keys')

args = parser.parse_args()
the_args = []

ret = subprocess.call('gpg', args.command, *the_args)
sys.exit(ret)
