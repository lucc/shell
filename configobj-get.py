#!/usr/bin/python

from configobj import ConfigObj
from os.path import expanduser
import logging
import argparse
import sys


def getter(config_object, element, *elements, fail=True):
    logging.debug('obj={}\nelm={}'.format(config_object, element))
    if element == '*':
        if len(elements) == 0:
            yield from config_object.values()
        else:
            for thing in config_object.values():
                yield from getter(thing, *elements, fail=False)
    elif element in config_object:
        if len(elements) == 0:
            yield config_object[element]
        else:
            yield from getter(config_object[element], *elements)
    elif fail:
        raise KeyError()


parser = argparse.ArgumentParser()
parser.add_argument('-d', '--debug', action='store_true',
                    help='print debugging info')
parser.add_argument('-e', '--expand', '--expanduser', action='store_true',
                    help="expand ~user strings in the result")
parser.add_argument('element', type=lambda x: x.split('.'),
                    help='the element to get')
parser.add_argument('file', type=argparse.FileType('r'), default=sys.stdin,
                    nargs='?', help='the config file to parse')
args = parser.parse_args()
if args.debug:
    logging.basicConfig(level=logging.DEBUG)
logging.debug(args)

config = ConfigObj(args.file)
for item in getter(config, *args.element):
    if args.expand:
        print(expanduser(item))
    else:
        print(item)
