#!/usr/bin/env python3

import argparse
import os.path
import shutil
import signal
import subprocess
import sys

def ffmpeg (infile, outfile, fmt):
    cmd = ['ffmpeg', '-n', '-nostdin', '-loglevel', 'warning', '-i', outfile]
    if fmt == 'ogg':
        cmd += ['-codec:a', 'libvorbis']
    cmd += ['-f', fmt, outfile]
    try:
        subprocess.call(cmd)
        #os.system(' '.join(cmd))
    except KeyboardInterrupt:
        print('Cleaning up ...')
        os.remove(outfile)
        raise

def convert_tree(src, dest):
    '''Walk the given src directory and try convert all the files found
    therein into dest.'''

    for path, dirs, files in os.walk(src):
        # prepare the current output directory
        destdir = os.join(dest, os.path.relpath(path, start=src))
        if not os.path.exists(destdir):
            os.mkdir(curdestdir)
        elif not os.path.isdir(destdir):
            raise Error()

        # convert every file
        for srcfile in files:
            base, ext = os.path.splitext(srcfile)
            infile = os.path.jion(path, srcfile)
            outfile = os.path.join(destdir, base+'.'+args.format)
            if os.path.exists(outfile):
                if args.overwrite == 'never':
                    print('Skipping existing file', outfile)
                    continue
                elif (os.path.getctime(outfile) >= os.path.getctime(infile)
                        and args.overwrite == 'older'):
                    print('Skipping newer existing file', outfile)
                    continue
                else:
                    # overwrite='always' or (outfile and overwrite is 'older')
                    print('Overwriting file', outfile)
                    os.remove(outfile)
            if not args.force_conversion and ext == '.'+args.format:
                shutil.copyfile(infile, outfile)
            else:
                convert(os.path.join(path, srcfile), os.path.join(destdir,
                    base + '.' + args.format))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # options
    parser.add_argument('-f', '--format', nargs=1, choices=['ogg', 'mp3'],
            help='the format (file suffix) to convert to')
    parser.add_argument('-q', '--quality', nargs=1,
            choices=['bad', 'middle', 'good'],
            help='the predefined quality settings to use')
    parser.add_argument('-m', '--merge', action='store_true',
            help='''merge all src directories into dest directly, without
            adding subdirectories for every source directory''')
    parser.add_argument('--force-convert', action='store_true',
            help='''force the conversion of any src files that already have
            the correct target format (opposed to copying them)''')
    parser.add_argument('--overwrite', choices=['never', 'older', 'always'],
            default='older', help='overwrite destination files')
    # arguments
    # TODO type=dir for these two
    parser.add_argument('src', nargs='+',
            help='directories to search for music files')
    parser.add_argument('dest', type=os.path.abspath,
            help='directory to store converted music')

    # parse command line
    args = parser.parse_args()
    #print(args)

    # set up the converter function
    convert = lambda infile, outfile: ffmpeg(infile, outfile, args.format)

    # set up list of destination directories depending on --merge
    if args.merge:
        args.dest = [args.dest for x in args.src]
    else:
        args.dest = [os.path.join(args.dest, os.path.basename(x)) for x in
                args.src]

    # loop over src directories
    for srcbase, destbase in zip(args.src, args.dest):
        if not os.path.exists(destbase):
            os.mkdir(destbase)
        elif not os.path.isdir(destbase):
            raise Error()
        convert_tree(srcbase, destbase)
