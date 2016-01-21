#!/usr/bin/env python3

'''
module docstring
'''

# TODO is there a module to convert music between differnt formats?

import argparse
import logging
import fnmatch
import os.path
import queue
import shutil
import subprocess
import threading


logger = logging.getLogger(__file__)


class Worker():

    """A worker to start several threads and sync all files given."""

    def __init__(self, merge=True, flat=False, mapping=None):
        """TODO: to be defined1.

        :merge: TODO
        :flat: TODO
        :mapping: TODO

        """
        if merge:
            self.destination = self.merge_destination
        else:
            self.destination = self.seperate_destination
        if flat:
            self.destination = self.flat_destination
        if mapping is None:
            self.mapping = self.noop
        else:
            self.mapping = mapping
        self._thread_count = 1

    def start(self, queue, destination):
        """TODO: Docstring for start.

        :queue: TODO
        :returns: TODO

        """
        self.run = True
        self._destination = destination
        for _ in range(self._thread_count):
            threading.Thread(target=self.work).start()

    def work(self):
        """TODO: Docstring for work.
        :returns: TODO

        """
        while self.run:
            source, path, file = queue.get()
            dest = self.destination(source, path, file)
            dest = self.mapping(dest)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            if os.path.splitext(file)[-1] == os.path.splitext(dest)[-1]:
                self.copy(os.path.join(path, file), dest)
            else:
                self.convert(os.path.join(path, file), dest)
            queue.task_done()

    def merge_destination(self, source, path, file):
        """TODO: Docstring for merge_destination.

        :source: TODO
        :path: TODO
        :file: TODO
        :returns: TODO

        """
        return os.path.join(self._destination, path[len(source):], file)

    def seperate_destination(self, source, path, file):
        """TODO: Docstring for seperate_destination.

        :source: TODO
        :path: TODO
        :file: TODO
        :returns: TODO

        """
        return os.path.join(self._destination, path, file)

    def flat_destination(self, source, path, file):
        """TODO: Docstring for flat_destination.

        :source: TODO
        :path: TODO
        :file: TODO
        :returns: TODO

        """
        return os.path.join(self._destination, file)

    def noop(self, *args, **kwargs):
        """TODO: Docstring for noop.

        :*args: TODO
        :**kwargs: TODO
        :returns: None

        """
        pass

    def copy(self, source, destination):
        """TODO: Docstring for copy.

        :source: TODO
        :destination: TODO
        :returns: TODO

        """
        if os.stat(source).st_mtime > os.stat(destination).st_mtime:
            logger.debug('copy {} to {}.'.format(source, destination))
            # shutil.copy2(source, destination)

    def convert(self, source, destination):
        """TODO: Docstring for copy.

        :source: TODO
        :destination: TODO
        :returns: TODO

        """
        if os.stat(source).st_mtime > os.stat(destination).st_mtime:
            self.ffmpeg(source, destination, os.path.splitext[-1][1:])

    def ffmpeg(self, infile, outfile, fmt):
        """Read infile, convert it to fmt and write the result to outfile.  Use
        the external ffmpeg program to do the conversion.

        :infile: the input file path
        :outfile: the output file path
        :fmt: the music file format to convert to
        :returns: None

        """
        cmd = ['ffmpeg', '-n', '-nostdin', '-loglevel', 'warning', '-i',
               infile]
        if fmt == 'ogg':
            cmd += ['-codec:a', 'libvorbis']
        cmd += ['-f', fmt, outfile]
        try:
            logger.debug('convert {} to {} ({}).'.format(infile, outfile, cmd))
            # subprocess.call(cmd)
        except KeyboardInterrupt:
            print('Cleaning up ...')
            # os.remove(outfile)
            raise


def fnmatch_list(filename, pattern_list):
    """Match a filename against a list of glob patterns (with fnmatch.fnmatch).
    Return True if any pattern matches, False if all fail.

    :filename: a filename as a string
    :pattern_list: a list of patterns for fnmatch.fnmatch
    :returns: True or False

    """
    return any(fnmatch.fnmatch(filename, pattern) for pattern in pattern_list)


def find_files(sources, exclude_files=[], exclude_paths=[]):
    """Find all the files that should be converted in the given array of source
    locations.

    :sources: a list of paths (files or directories)
    :returns: a queue object with all files that should be synced

    """
    q = queue.Queue()
    for source in sources:
        # os.walk returns an empty iterator for files so they have to be
        # treated specially.
        if os.path.isfile(source):
            if not fnmatch_list(source, exclude_files+exclude_paths):
                q.add(('.', '.', source))
        # TODO the followlinks argument
        for path, dirs, files in os.walk(source):
            for directory in dirs:
                if fnmatch_list(directory, exclude_files) or fnmatch_list(
                        os.path.join(path, directory), exclude_paths):
                    dirs.remove(directory)
            for file in files:
                if fnmatch_list(file, exclude_files) or fnmatch_list(
                        os.path.join(path, file), exclude_paths):
                    files.remove(file)
            # The remaining files should be synced and can be put on the queue.
            for file in files:
                q.add((source, path, file))


def convert_tree(src, dest, format, force_convert=False, overwrite='never'):
    '''Walk the given src directory and try convert all the files found
    therein into dest.'''

    for path, dirs, files in os.walk(src):
        # prepare the current output directory
        destdir = os.path.join(dest, os.path.relpath(path, start=src))
        if not os.path.exists(destdir):
            os.mkdir(destdir)
        elif not os.path.isdir(destdir):
            raise OSError()

        # convert every file
        for srcfile in files:
            base, ext = os.path.splitext(srcfile)
            infile = os.path.join(path, srcfile)
            outfile = os.path.join(destdir, base+'.'+format)
            if os.path.exists(outfile):
                if overwrite == 'never':
                    print('Skipping existing file', outfile)
                    continue
                elif (os.path.getctime(outfile) >= os.path.getctime(infile) and
                        overwrite == 'older'):
                    print('Skipping newer existing file', outfile)
                    continue
                else:
                    # overwrite='always' or (outfile and overwrite is 'older')
                    print('Overwriting file', outfile)
                    os.remove(outfile)
            if not force_convert and ext == '.'+format:
                shutil.copyfile(infile, outfile)
            else:
                convert(os.path.join(path, srcfile),
                        os.path.join(destdir, base + '.' + format))


def parse_options():
    """Parse the comand line options.
    :returns: the argparse namespace

    """
    parser = argparse.ArgumentParser()
    # options
    parser.add_argument(
        '-f', '--format', choices=['ogg', 'mp3'],
        help='the format (file suffix) to convert to')
    parser.add_argument(
        '-q', '--quality', nargs=1, choices=['bad', 'middle', 'good'],
        help='the predefined quality settings to use')
    parser.add_argument(
        '-m', '--merge', action='store_true',
        help='''merge all src directories into dest directly, without adding
        subdirectories for every source directory''')
    parser.add_argument(
        '--flat', action='store_true', help="""don't create subdirectories in
        the destination at all""")
    parser.add_argument(
        '--map', nargs=2, action='append', help="""conversion map for specific
        file extensions""")
    parser.add_argument(
        '--copy', action='append', help="""file pattern which should be copied
        (no conversion)""")
    parser.add_argument(
        '--name-by-tags', action='store_true', help="""name files after
        metadata tags""")
    parser.add_argument(
        '--force-convert', action='store_true', help='''force the conversion of
        any src files that already have the correct target format (opposed to
        copying them)''')
    parser.add_argument(
        '--overwrite', choices=['never', 'older', 'always'], default='older',
        help='overwrite destination files')
    # arguments
    # TODO type=dir for these two
    parser.add_argument(
        'src', nargs='+', help='directories to search for music files')
    parser.add_argument(
        'dest', type=os.path.abspath,
        help='directory to store converted music')

    # parse command line
    args = parser.parse_args()
    return args


def main():
    args = parse_options()
    # set up the converter function

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
            raise OSError()
        convert_tree(srcbase, destbase, args.format, args.force_convert,
                     args.overwrite)


if __name__ == '__main__':
    main()
