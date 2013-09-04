#!/usr/bin/env python3

# TODO list {{{1
# 1. use try ... except ... to handle missing packages
# 2. docstrings & comments
# 3. better logging mechanism
# 4. understanding threading
# 5. handle more pages

# imports {{{1
import argparse
import datetime
import inspect
import os
import re
import signal
import sys
# see file:///Users/luc/tmp/python-3.3.0-docs-html/library/concurrency.html
import threading, queue
import traceback
import urllib.request

from bs4 import BeautifulSoup

# a new start (from scratch?) {{{1
class Manager(): #{{{2
    '''
    The Manager class manages the downloading and saving of images and writes
    the log file.  It uses other classes to do the actual parsing of the html.
    '''

    # variables {{{3
    log = {}
    logfile = None
    dir = ''
    threads = []

    # classmethods/staticmethods {{{3


# constants {{{1
MAIOR_VERSION = 1
MINOR_VERSION = 0
PROG = os.path.basename(sys.argv[0])
VERSION_STRING = PROG + ' ' + str(MAIOR_VERSION) + '.' + str(MINOR_VERSION)

# variables {{{1
quiet = True
debug = False
global_mangadir = os.getenv("MANGADIR")
if global_mangadir is None or global_mangadir == "":
    global_mangadir = os.path.join(os.getenv("HOME"), "comic")
global_mangadir = os.path.realpath(global_mangadir)

def noop(*args): #{{{1
    pass


def timestring(): #{{{1
    return datetime.datetime.now().strftime('%H:%M:%S')


def debug_info(*strings): #{{{1
    if debug:
        print('Debug:', *strings)


def debug_enter(cls, *strings): #{{{1
    if debug:
        name = 'of ' + cls.__name__ if type(cls) is type else ''
        #if type(cls) is type:
        #    name = 'of ' + cls.__name__
        #else:
        #    name = ''
        stack = inspect.stack(context=0)
        print('Debug: Entering', stack[1][3], name)
        if strings is not None and len(strings) > 0:
            print('Debug:', *strings)


def print_info(string, *strings): #{{{1
    if not quiet:
        print(string, *strings)

def start_thread(function, arguments): #{{{1
    #t = _thread.start_new_thread(function, arguments)
    #return
    t = threading.Thread(target=function, args=arguments)
    t.start()
    #threads.append(t)

def download_image(key, url, filename, logger): #{{{1
    debug_enter(None)
    #raise NotImplementedError()
    try:
        urllib.request.urlretrieve(url, filename)
    except urllib.error.ContentTooShortError:
        os.remove(filename)
        print_info(PROG + ':', timestring(), 'downloading failed:',
                ' '.join(logger.log[key]))
        logger.remove(key)
        return
    logger.remove(key)


def find_class_from_url(url): #{{{1
    '''
    Parse the given url and try to find a class that can load from that
    domain.  Return the class.
    '''
    debug_enter(None)
    url = urllib.parse.urlparse(url)
    #debug_info(str(url))
    defined_classes = SiteHandler.__subclasses__()
    #debug_info(str(defined_classes))
    if url.netloc is None or url.netloc == '':
        raise BaseException('This url is no good.')
    for cls in defined_classes:
        if url.netloc.split('.')[-2:] == cls.DOMAIN.split('.')[-2:]:
            debug_info('Found correct subclass:', cls)
            return cls
    raise NotImplementedError(
            'There is no class available to work with this url.')


def download_missing(directory, logfile): #{{{1
    '''
    Load all images which are mentioned in the logfile but not present in the
    directory.
    '''
    logfile = open(logfile, 'r')
    logger = BaseLogger('/dev/null', quiet)
    for index, line in enumerate(logfile.readlines()):
        url, img, filename = line.split(' ', 2)
        if not os.path.exists(filename):
            start_thread(download_image, (index, img, filename, logger))


class BaseLogger(): #{{{1

    def __init__(self, logfile, quiet=False): #{{{2
        self.log = dict()
        self.logfile = open(logfile, 'a')
        self.quiet = quiet

    def __del__(self): #{{{2
        self.cleanup()

    def add(self, key, url, img, filename): #{{{2
        self.log[key] = (url, img, filename)
        self.logfile.write(' '.join(self.log[key]) + '\n')
        if not self.quiet:
            print_info(PROG + ': ' + timestring() + ' downloading ' + img +
                    ' -> ' + filename)

    def remove(self, key): #{{{2
        del self.log[key]

    def cleanup(self): #{{{2
        debug_enter(BaseLogger)
        self.logfile.close()
        for item in self.log:
            os.remove(item[2])


class Logger(BaseLogger): #{{{1

    #def __init__(self, logfile, quiet=False): #{{{2
    #    logfile = open(logfile, 'r')
    #    self.log = [line.split(' ', 2) for line in logfile.readlines()]
    #    logfile.close()
    #    for item in self.log:
    #        if os.path.exists(item[2]):
    #            item.append(True)
    #        else:
    #            item.append(False)
    #            _thread.start_new_thread(
    #                    download_image, (item[1], item[2], self))

    def __del__(self): #{{{2
        self.write_logfile()
        self.super().__del__()
        # Do I need to del these manually?
        #del self.logfile
        #del self.log
        #del self.quiet

    def add(self, chap, count, nr=None, url=None, img=None, filename=None): #{{{2
        debug_enter(Logger)
        if nr is None and url is None and img is None and filename is None:
            if chap in self.log:
                if count != self.log[chap][0]:
                    raise BaseException(
                            'Adding chapter twice with different length!')
                else:
                    # It is ok to add the chapter agoin with the same length.
                    return
            else:
                self.log[chap] = [count for i in range(count+1)]
        elif nr is None or url is None or img is None or filename is None:
            raise BaseException('Missing parameter!')
        elif chap in self.log:
            if self.log[chap][0] != count:
                raise BaseException('Inconsistend parameter!')
            elif self.log[chap][nr] != count and self.log[chap][nr][0:3] != \
                    [url, img, filename]:
                raise BaseException('Adding item twice.')
            else:
                self.log[chap][nr] = [url, img, filename, None]
        else:
            self.log[chap] = [count for i in range(count+1)]
            self.log[chap][nr] = [url, img, filename, None]
        if not self.quiet:
            print_info(PROG + ': ' + timestring() + ' downloading ' + img +
                    ' -> ' + filename)

    def success(self, chap, nr): #{{{2
        debug_enter(Logger)
        if chap not in self.log:
            raise BaseException('This key was not present:', chap)
        self.log[chap][nr][3] = True
        ## By now we only remove the item maybe we will do more in the future.
        #for item in self.log:
        #    if item[2] == filename:
        #        self.log.remove(item)
        #        return

    def failed(self, chap, nr): #{{{2
        debug_enter(Logger)
        if chap not in self.log:
            raise BaseException('This key was not present:', chap)
        self.log[chap][nr][3] = False
        ## By now we only remove the item maybe we will do more in the future.
        #for item in self.log:
        #    if item[2] == filename:
        #        self.log.remove(item)
        if not self.quiet:
            print_info(PROG + ': ' + timestring() + 'download failed: ' +
                    item[1] + ' -> ' + item[2])


class SiteHandler(): #{{{1

    # References to be implement in subclasses. {{{2
    def extract_key(html): raise NotImplementedError()
    def extract_next_url(html): raise NotImplementedError()
    def extract_img_url(html): raise NotImplementedError()
    def extract_filename(html): raise NotImplementedError()
    def load_intelligent(self, url): raise NotImplementedError()

    def __init__(self, directory, logfile): #{{{2
        debug_enter(SiteHandler)
        logfile = os.path.realpath(os.path.join(directory, logfile))
        self.log = BaseLogger(logfile, quiet)
        signal.signal(signal.SIGTERM, self.log.cleanup)
        # We can also try to implement a fifo.  This idea is not yet fully
        # developed.
        #self.fifo = list()
        # This is not optimal: try to not change the dir.
        os.chdir(directory)

    @classmethod
    def expand_rel_url(cls, url): #{{{2
        '''Expand the given string into a valid URL.  The string is assumed to
        be relative to the site handled by the class cls.'''
        if '://' in url:
            return url
        elif '//' == url[0:2]:
            return cls.PROTOCOL + ':' + url
        elif '/' == url[0]:
            return cls.PROTOCOL + '://' + cls.DOMAIN + url
        else:
            return cls.PROTOCOL + '://' + cls.DOMAIN + '/' + url


    @classmethod
    def extract_key(cls, html): #{{{2
        debug_enter(SiteHandler)
        debug_info('The class argument is', cls)
        return str(cls.extract_chapter_nr(html)) + '-' + str(
                cls.extract_page_nr(html))

    @classmethod
    def extract_linear(cls, html): #{{{2
        '''
        This method returns a tupel of the next url, the image url and the
        filename to downlowd to.  It will extract these information from the
        supplied html page inline.
        '''
        # This is just a dummy implementation which should be overwritten.
        # The actual implementation should extract these information inline.
        key = cls.extract_key(html)
        nexturl = cls.extract_next_url(html)
        img = cls.extract_img_url(html)
        filename = cls.extract_filename(html)
        return (key, nexturl, img, filename)

    def load_image(self, html, url): #{{{2
        debug_enter(SiteHandler)
        cls = self.__class__
        try:
            key = cls.extract_key(html)
            img = cls.extract_img_url(html)
            filename = cls.extract_filename(html)
        except AttributeError:
            print_info(url, 'seems to be the last page.')
            return
        self.log.add(key, url, img, filename)
        download_image(key, img, filename, self.log)

    def load_linear(self, url): #{{{2
        '''
        This method loads all images starting at the specified url.  It will
        walk the sites in a linear manner.  The class with which this method
        is used needs to implement extract_img_url, extract_filename and
        extract_next_url.
        '''
        debug_enter(SiteHandler)
        while url is not None:
            html = BeautifulSoup(urllib.request.urlopen(url))
            try:
                nexturl = self.__class__.extract_next_url(html)
            except AttributeError:
                return
            start_thread(self.load_image, (html, url))
            url = nexturl

    def load_linear_fast(self, url): #{{{2
        '''
        This method loads all images starting at the specified url.  It will
        walk the sites in a linear manner.  The necessary information will be
        extracted in a faster way.
        '''
        debug_enter(SiteHandler)
        while url is not None:
            html = BeautifulSoup(urllib.request.urlopen(url))
            try:
                key, nexturl, img, filename = \
                        self.__class__.extract_linear(html)
            except AttributeError:
                #print_info('This should never happen!')
                #traceback.print_exception(*sys.exc_info())
                print_info(url, 'seems to be the last page.')
                #print_info('We cought this but will return here.')
                return
            self.log.add(key, url, img, filename)
            start_thread(download_image,
                    (key, img, filename, self.log))
            url = nexturl


    def start_at(self, url): #{{{2
        'Load all images starting at a specific url.'
        debug_enter(SiteHandler)
        try:
            self.load_intelligent(url)
        except NotImplementedError:
            try:
                self.load_linear_fast(url)
            except NotImplementedError:
                self.load_linear(url)

    def start_after(self, url): #{{{2
        'Load all images starting at the url after the one specified.'
        debug_enter(SiteHandler)
        request = urllib.request.urlopen(url)
        debug_info('Finished preloading.')
        html = BeautifulSoup(request)
        url = self.__class__.extract_next_url(html)
        self.start_at(url)


class Mangareader(SiteHandler): #{{{1

    # class constants {{{2
    PROTOCOL = 'http'
    DOMAIN = 'www.mangareader.net'

    def __init__(self, directory, logfile): #{{{2
        debug_enter(Mangareader)
        super().__init__(directory, logfile)

    def extract_key(html): #{{{2
        debug_enter(Mangareader)
        return str(Mangareader.extract_chapter_nr(html)) + '-' + str(
                Mangareader.extract_page_nr(html))

    def extract_next_url(html): #{{{2
        debug_enter(Mangareader)
        return Mangareader.expand_rel_url(html.find(id='img').parent['href'])

    def extract_img_url(html): #{{{2
        debug_enter(Mangareader)
        return html.find(id='img')['src']

    def extract_filename(html): #{{{2
        debug_enter(Mangareader)
        return re.sub(r'[ -]+', '-', html.find(id="img")["alt"]).lower() + \
                '.' + Mangareader.extract_img_url(html).split('.')[-1]

    def extract_chapter_nr(html): #{{{2
        debug_enter(Mangareader)
        return int(html.find(id='mangainfo').h1.string.split()[-1])

    def extract_page_nr(html): #{{{2
        debug_enter(Mangareader)
        return int(html.find(id='mangainfo').span.string.split()[1])

    def extract_page_count(html): #{{{2
        debug_enter(Mangareader)
        return len(html.find(id='pageMenu').find_all('option'))

    def extract_page_urls(html): #{{{2
        debug_enter(Mangareader)
        return [Mangareader.expand_rel_url(o['value']) for o in
                html.find(id='pageMenu').find_all('option')]

    def extract_main_page(html): #{{{2
        debug_enter(Mangareader)
        return Mangareader.expand_rel_url(
                html.find(id='mangainfo').h2.a['href'])

    def extract_chapter_count(html): #{{{2
        # This should be called with the html for the main page.
        return len(html.find(id='chapterlist').find_all('a'))

    def extract_manga_name(html): #{{{2
        debug_enter(Mangareader)
        c= re.sub(r'(.*) [0-9]+$', r'\1', html.find(id='mangainfo').h1.string)
        print_info("so: |" + c + '|')
        return c

    def extract_linear(html): #{{{2
        debug_enter(Mangareader)
        img_tag = html.find(id='img')
        mangainfo = html.find(id='mangainfo')
        key = mangainfo.h1.string.split()[-1] + \
                mangainfo.span.string.split()[1]
        nexturl = Mangareader.expand_rel_url(img_tag.parent['href'])
        img = img_tag['src']
        filename = re.sub(r'[ -]+', '-', img_tag["alt"]).lower() + '.' + \
                img.split('.')[-1]
        return (key, nexturl, img, filename)

    def helper_load_chapter(url, startpage=1): #{{{2
        debug_enter(Mangareader)
        raise NotImplementedError()

    def helper_load_chapter_2(self, manga, chapter, startpage=1, count=0): #{{{2
        debug_enter(Mangareader)
        if count == 0:
            # we need the count so we will look it up if it was not given
            html = BeautifulSoup(urllib.request.urlopen(
                    Mangareader.expand_rel_url(manga + '/' + str(chapter))))
            count = self.extract_page_count(html)
        for page in range(startpage, count+1):
            print_info('xxx',Mangareader.expand_rel_url(manga + '/' +
                    str(chapter) + '/' + str(page))+'|')
            self.helper_load_page_and_image(
                    Mangareader.expand_rel_url(manga + '/' + str(chapter) +
                    '/' + str(page)))

    def helper_load_page_and_image(self, url): #{{{2
        # TODO Can we push this in the superclass?
        debug_enter(Mangareader)
        html = BeautifulSoup(urllib.request.urlopen(url))
        try:
            img = Mangareader.extract_img_url(html)
            filename = Mangareader.extract_filename(html)
        except AttributeError:
            print_info('This should never happen!',
                    '(Comming from Mangareader.helper_load_page_and_image)')
            traceback.print_exception(*sys.exc_info())
            return
        self.log.add(url, img, filename)
        download_image(img, filename)

    def load_intelligent_1(self, url): #{{{2
        raise NotImplementedError("TODO")
        debug_enter(Mangareader)
        while url is not None:
            html = BeautifulSoup(urllib.request.urlopen(url))
            try:
                pagenr = Mangareader.extract_page_nr(html)
                pagecount = Mangareader.extract_page_count(html)
                chapternr = Mangareader.extract_chapter_nr(html)
                nexturl = Mangareader.extract_next_url(html)
            except AttributeError:
                print_info(url, 'seems to be the last page.')
                return
            self.log.add
            url = nexturl
            #self.log.add(url, img, filename)
            #for pnr in range(pagenr, pagecount):
            #    _thread.start_new_thread(Mangareader.intelligent_load_helper,
            #            (
            #_thread.start_new_thread(Mangareader.intelligent_load_helper,
            #        (chapternr, pagenr, pagecount))
        raise NotImplementedError()

    def load_intelligent_2(self, url): #{{{2
        debug_enter(Mangareader)
        html = BeautifulSoup(urllib.request.urlopen(url))
        chapternr = Mangareader.extract_chapter_nr(html)
        pagenr = Mangareader.extract_page_nr(html)
        pagecount = Mangareader.extract_page_count(html)
        manga = Mangareader.extract_manga_name(html)
        main = Mangareader.extract_main_page(html)
        main_html = BeautifulSoup(urllib.request.urlopen(main))
        #_thread.start_new_thread(Mangareader.helper_load_chapter_2, (manga,
        #        chapternr, pagenr, pagecount))
        self.helper_load_chapter_2(manga,chapternr,pagenr, pagecount)
        for chapter in range(chapternr+1,
                Mangareader.extract_chapter_count(main_html)+1):
        #    _thread.start_new_thread(Mangareader.helper_load_chapter_2,
        #            (manga, chapter))
            Mangareader.helper_load_chapter_2(manga, chapter )

#assigning the current function
Mangareader.load_intelligent = Mangareader.load_intelligent_1


class Unixmanga(SiteHandler): #{{{1

    # class constants {{{2
    PROTOCOL = 'http'
    DOMAIN = 'unixmanga.com'

    def __init__(self, directory, logfile): #{{{2
        debug_enter(Unixmanga)
        suoer().__init__(directory, logfile)

    def extract_next_url(html): #{{{2
        debug_enter(Unixmanga)
        s = html.find_all(class_='navnext')[0].script.string.split('\n')[1]
        return re.sub(r'var nextlink = "(.*)";', r'\1', s)


class Mangafox(SiteHandler): #{{{1

    def __init__(self, directory, logfile): #{{{2
        debug_enter(Mangafox)
        suber().__init__(directory, logfile)

    def extract_next_url(html): #{{{2
        debug_enter(Mangafox)
        raise NotImplementedError()
        # TODO
        return html.find_all(class_='next_page')[0]['href']


if __name__ == '__main__': #{{{1

    def prepare_output_dir(directory, string): #{{{2
        # or should we used a named argument and detect the manga name
        # automatically if it is not given.
        '''Find the correct directory to save output files to and set
        directory'''
        debug_enter(None)

        #mangadir = os.path.join(os.getenv("HOME"), "comic")
        #if directory == '.':
        #    if os.path.exists(os.path.join(mangadir, string)):
        #        directory = os.path.exists(os.path.join(mangadir, string))
        #    elif is_url(string):

        mangadir = '.'
        if not directory == '.' and not os.path.sep in directory:
            mangadir = global_mangadir
            directory = os.path.realpath(os.path.join(mangadir, directory))
        if os.path.exists(directory):
            if not os.path.isdir(directory):
                raise EnvironmentError("Path exists but is not a directory.")
        else:
            os.mkdir(directory)
        # We change to the directory. We could only just return its path an let
        # the caller handle the rest (this is the aim for the future)
        os.chdir(directory)
        print_info('Working in ' + os.path.realpath(os.path.curdir) + '.')
        return os.path.curdir
        return directory


    def resume(directory, logfile): #{{{2
        debug_enter(None)
        log = open(logfile, 'r')
        line = log.readlines()[-1]
        log.close()
        url = line.split()[0]
        debug_info('Found url for resumeing: ' + url)
        cls = find_class_from_url(url)
        worker = cls(directory, logfile)
        worker.start_after(url)


    def resume_all(): #{{{2
        debug_enter(None)
        for d in [os.path.join(global_mangadir, dd) for dd in
                os.listdir(global_mangadir)]:
            os.chdir(d)
            print_info('Working in ' + os.path.realpath(os.path.curdir) + '.')
            resume(os.path.join(global_mangadir, d), 'manga.log')


    def automatic(string): #{{{2
        if os.path.exists(os.path.join(args.directory, string)):
            pass
        else:
            try:
                l = url.parse.urlparse(string)
            except:
                print_info('The fucking ERROR!')


    def parse_args_version_1(): #{{{2
        args.directory = prepare_output_dir(args.directory, args.url)
        #if args.auto:
        #    automatic(args.string)
        #el
        if args.resume and args.url is not None:
            parser.error('You can only use -r or give an url.')
        elif not args.resume and args.url is None:
            parser.error('You must specify -r or an url.')
        print(args)
        # running
        if args.resume:
            resume(args.directory, args.logfile)
        else:
            cls = find_class_from_url(args.url)
            worker = cls(args.directory, args.logfile)
            #worker = Mangareader(args.directory, args.logfile)
            #worker.run(args.url)
            worker.start_at(args.url)


    def parse_args_version_2(): #{{{2
        args.directory = prepare_output_dir(args.directory, args.name)
        #if args.auto:
        #    automatic(args.string)
        #el
        if args.resume and args.name is not None:
            parser.error('You can only use -r or give an url.')
        elif not args.resume and args.name is None:
            parser.error('You must specify -r or an url.')
        debug_info(args)
        # running
        if args.resume:
            resume(args.directory, args.logfile)
        else:
            cls = find_class_from_url(args.name)
            worker = cls(args.directory, args.logfile)
            #worker = Mangareader(args.directory, args.logfile)
            #worker.run(args.url)
            worker.start_at(args.name)


    def parse_args_version_3(): #{{{2
        # Define the base directory for the directory to load to.
        mangadir = '.'
        directory = args.directory
        if not os.path.sep in directory:
            mangadir = os.getenv("MANGADIR")
            if mangadir is None or mangadir == "":
                mangadir = os.path.join(os.getenv("HOME"), "comic")
            mangadir = os.path.realpath(mangadir)
        # Find the actual directory to work in.
        if directory == '.':
            # There was no directory given on command line.  Try to find the
            # directory in args.name.
            pass
        else:
            # We got a directory from the command line.
            directory = os.path.join(mangadir, directory)
        # Create the directory if necessary.
        if os.path.exists(directory):
            if not os.path.isdir(directory):
                raise EnvironmentError("Path exists but is not a directory.")
        else:
            os.mkdir(directory)
        os.chdir(directory)
        print_info('Working in ' + os.path.realpath(os.path.curdir) + '.')
        args.directory = prepare_output_dir(args.directory, args.string)
        #if args.auto:
        #    automatic(args.string)
        #el
        if args.resume and args.url is not None:
            parser.error('You can only use -r or give an url.')
        elif not args.resume and args.url is None:
            parser.error('You must specify -r or an url.')
        print_info(args)
        # running
        if args.resume:
            resume(args.directory, args.logfile)
        else:
            cls = find_class_from_url(args.url)
            worker = cls(args.directory, args.logfile)
            #worker = Mangareader(args.directory, args.logfile)
            #worker.run(args.url)
            worker.start_at(args.url)


    def parse_args_version_4(): #{{{2
        args.directory = prepare_output_dir(args.directory, args.name)
        #if args.auto:
        #    automatic(args.string)
        #el
        if args.resume_all:
            resume_all()
            sys.exit()
        elif args.resume and (args.name is not None or args.missing):
            parser.error('You can only use -r or -m or give an url.')
        elif not args.resume and args.name is None and not args.missing:
            parser.error('You must specify -r or -m or an url.')
        debug_info(args)
        # running
        if args.resume:
            resume(args.directory, args.logfile)
            print_info('args.missing was', args.missing)
        elif args.missing:
            download_missing(args.directory, args.logfile)
            print_info('args.resume was', args.resume)
        else:
            cls = find_class_from_url(args.name)
            worker = cls(args.directory, args.logfile)
            #worker = Mangareader(args.directory, args.logfile)
            #worker.run(args.url)
            worker.start_at(args.name)


    def join_threads(): #{{{2
        try:
            current = threading.current_thread()
            for thread in threading.enumerate():
                if thread != current:
                    thread.join()
            debug_info('All threads joined.')
        except:
            print_info('Could not get current thread.',
                    'Not waiting for other threads.')


    def interrupt_cleanup(): #{{{2
        """Stop all threads and write the logfile before exiting.  This
        function should be called when an interrupt signal is called."""
        pass


    # defining the argument parser {{{2
    parser = argparse.ArgumentParser(prog=PROG,
            description="Download manga from some websites.")

    # general group {{{3
    general = parser.add_argument_group(title='General options')
    general.add_argument('-b', '--background', action='store_true',
            help='fork to background')
    # can we hand a function to the parser to check the directory?
    general.add_argument('-d', '--directory', metavar='DIR', default='.',
            help='the directory to work in')
    general.add_argument('-f', '--logfile', metavar='LOG',
            default='manga.log', help='the filename of the logfile to use')
    general.add_argument('-q', '--quiet', dest='quiet', default=False,
            action='store_true', help='supress output')
    general.add_argument('-v', '--verbose', dest='quiet', default=False,
            action='store_false', help='verbose output')
    general.add_argument('-m', '--load-missing', action='store_true',
            dest='missing',
            help='Load all files which are stated in the logfile but ' +
            'are missing on disk.')

    # unimplemented group {{{3
    unimplemented = parser.add_argument_group('These are not yet implemented')
    # the idea for 'auto' was to find the manga name and the directory
    # automatically.
    unimplemented.add_argument('-a', '--auto', action='store_true',
            default=True, help='do everything automatically')
    unimplemented.add_argument('-x', '--debug', action='store_true',
            help='give verbose debugging output')
    # or use the logfile from within for downloading.
    ## idea for "archive": tar --wildcards -xOf "$OPTARG" "*/$LOGFILE"
    unimplemented.add_argument('-A', '--archive',
            help='display the logfile from within an archive')
    unimplemented.add_argument('--view', help='create a html page')

    unimplemented.add_argument('-r', '--resume', action='store_true',
            help='resume from a logfile')
    unimplemented.add_argument('-R', '--resume-all', action='store_true',
            help='visit all directorys in the manga dir and resume there')

    #general group {{{3
    parser.add_argument('-V', '--version', action='version',
            version=VERSION_STRING, help='print version information')
    #parser.add_argument('url', nargs='+')
    #parser.add_argument('url', nargs='?')
    parser.add_argument('name', nargs='?', metavar='url/name')


    # running everything {{{2
    args = parser.parse_args()
    # set global variables from cammand line values
    quiet = args.quiet
    debug = args.debug
    parse_args_version_4()
    join_threads()
    debug_info('Exiting ...')

# vim: foldmethod=marker
