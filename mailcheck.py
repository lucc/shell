#!/usr/bin/env python3

import argparse
import mailbox
import netrc
import os
import glob

config_file
netrc_file
homedir

def check_mailbox_object(obj):
    if args.verbose is True:
        return [(x[1].get('From'), x[1].get('Subject')) for x in obj.items()
                if "S" not in x[1].get_flags()]
    else:
        return len([x[0] for x in obj.items() if "S" not in x[1].get_flags()])

def read_rc(fname):
    with open(fname, 'r') as rcfile:
        for line in rcfile.readlines():
            line = line.lstrip()
            if line[0] != '#':
                if line[0] == '~':
                    # TODO
                    #special = os.path.split(line)[0]
                    #if special == '~':
                    #    special = os.getenv('HOME')
                    #else:
                    #    raise NotImplementedError('What to do?')
                    #line = os.path.join(os.getenv('HOME'), line[
                args.path.append(*glob.glob(line))

def read_netrc(fname):
    pass

def check_mailbox(fname):
    pass

def check_pop3(url):
    pass

def check_imap(url):
    pass

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--verbose', default=False, action='store_true', help='hans')
    parser.add_argument('-f', '--config-file', default=None, help='hans')
    parser.add_argument('-n', '--netrc', default=None, help='hans')
    parser.add_argument('path', default=None, nargs='*', help='hans')
    pass
