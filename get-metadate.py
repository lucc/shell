#!/usr/bin/env python3
#

try:
    import mutagen
else:
    try:
        import mutagenx as mutagen
    else:
        raise Error()
import sys
import os
import argparse

def stuff():
    pass

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('dir', help='the directory to search')
    parser.add_argument('outfile', help='the file to write the index of tags to')
    args = parser.parse_args()
    for
