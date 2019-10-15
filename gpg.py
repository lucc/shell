#!/usr/bin/python

"""A small script to collect some usefull gpg commands in nice user
interface."""

import argparse
import logging
import subprocess
import sys

iofiles = argparse.ArgumentParser(add_help=False)
iofiles.add_argument('--input', default=sys.stdin, type=argparse.FileType('r'))
iofiles.add_argument('--output', default=sys.stdout,
                     type=argparse.FileType('w'))

parser = argparse.ArgumentParser()
parser.add_argument('--debug', '-d', action='store_true')
subparsers = parser.add_subparsers()
decode = subparsers.add_parser('decode', parents=[iofiles],
                               help='decode stdin')
decode.set_defaults(command='-d')

encode = subparsers.add_parser('encode', parents=[iofiles],
                               help='encode stdin')
encode.set_defaults(command='-e')
sign = subparsers.add_parser('sign', help='sign stdin')
sign.set_defaults(command='-s')
import_ = subparsers.add_parser('import', help='import a new key from a file '
                                'or a key server')
import_.set_defaults(command='--import')
export = subparsers.add_parser('export', help='export a key')
export.set_defaults(command='--export')
update = subparsers.add_parser('update', help='update the keyring')
update.set_defaults(command='--update-keys')
listkey = subparsers.add_parser('list', help='list key(s)')
listkey.set_defaults(command='--list-key')
listkey.add_argument('--all', help='list all (even expired) keys')
listkey.add_argument('args',  nargs='*')

args = parser.parse_args()

if args.debug:
    logging. basicConfig(level=logging.DEBUG)
    logging.debug(args)

cmd = ['gpg']
if 'command' in args and args.command:
    cmd += [args.command]
if 'args' in args and args.args:
    cmd += args.args

logging.debug(cmd)
ret = subprocess.call(cmd)
sys.exit(ret)
