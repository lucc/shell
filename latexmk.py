#!/usr/bin/env python3

import argparse
import os.path
import subprocess

import fs

def latexmk(filename):
    directory = fs.find_base_dir(filename, indicator_files=('latexmkrc',),
            indicator_dirs=[])
    if directory == '/':
        directory = os.path.dirname(filename)
    subprocess.call(['latexmk', '-pdf', '-silent',
        os.path.basename(filename)], cwd=directory)

def check(string):
    if os.path.exists(string) and os.path.isfile(string):
        return string
    else:
        raise OSError('The file does not exist or is not a regular file.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('file', type=check)
    args = parser.parse_args()
    latexmk(args.file)
