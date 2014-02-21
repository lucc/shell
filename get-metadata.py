#!/usr/bin/env python3
#

try:
    import mutagen
except:
    try:
        import mutagenx as mutagen
    except:
        raise Error()
import sys
import os
import argparse
import subprocess

def stuff():
    pass

def getMetadataWithFfmpeg(filename):
    # get the output from ffprobe
    output = subprocess.check_output(['ffprobe', '-loglevel', 'info',
            filename], stderr=subprocess.STDOUT)
    # convert it to a string
    output = output.decode()
    # remove all but the metadata
    output = output.split(sep='\n  Metadata:\n', maxsplit=1)[1]
    output = output.rsplit(sep='\n  Duration: ', maxsplit=1)[0]
    # split the output into lines containing the single fields and parse the
    # field name and value from the line, add all tags in the directory
    # metadata.
    metadata = {}
    for line in output.splitlines():
        key, val = line.lstrip().split(sep=' : ', maxsplit=1)
        key = key.strip()
        metadata[key] = val
    return metadata

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('dir', help='the directory to search')
    parser.add_argument('outfile', help='the file to write the index of tags to')
    args = parser.parse_args()
    # TODO
