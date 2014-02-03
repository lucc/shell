#!/usr/bin/env python3
# vim: foldmethod=marker

# imports {{{1
# TODO: use try ... except ... to handle missing packages
import argparse
import datetime
import inspect
import os
import re
import signal
import sys
import _thread
import threading
import traceback
import urllib.request

from bs4 import BeautifulSoup

# constants {{{1
MAIOR_VERSION = 1
MINOR_VERSION = 0
PROG = os.path.basename(sys.argv[0])
VERSION_STRING = PROG + ' ' + str(MAIOR_VERSION) + '.' + str(MINOR_VERSION)

# variables {{{1
threads = []

# global functions {{{1
def start_thread(function, arguments): #{{{2
    #t = _thread.start_new_thread(function, arguments)
    #return
    t = threading.Thread(target=function, args=arguments)
    t.start()
    threads.append(t)

def timestring(): #{{{2
    return datetime.datetime.now().strftime('%H:%M:%S')


def debug_info(string): #{{{2
    if args.debug:
        print('Debug:', string)


def download_image(key, url, filename, logger): #{{{2
    debug_info('Entering download_image ...')
    #raise NotImplementedError()
    try:
        urllib.request.urlretrieve(url, filename)
    except urllib.error.ContentTooShortError:
        os.remove(filename)
        print(PROG + ':', timestring(), 'downloading failed:',
                ' '.join(logger.log[key]))
        logger.remove(key)
        return
    logger.remove(key)


def prepare_output_dir(directory, string): #{{{2
    # or should we used a named argument and detect the manga name
    # automatically if it is not given.
    '''Find the correct directory to save output files to and set
    directory'''
    debug_info('Entering prepare_output_dir ...')

    #mangadir = os.path.join(os.getenv("HOME"), "manga")
    #if directory == '.':
    #    if os.path.exists(os.path.join(mangadir, string)):
    #        directory = os.path.exists(os.path.join(mangadir, string))
    #    elif is_url(string):

    mangadir = '.'
    if not os.path.sep in directory:
        mangadir = os.getenv("MANGADIR")
        if mangadir is None or mangadir == "":
            mangadir = os.path.join(os.getenv("HOME"), "manga")
        mangadir = os.path.realpath(mangadir)
    directory = os.path.realpath(os.path.join(mangadir, directory))
    if os.path.exists(directory):
        if not os.path.isdir(directory):
            raise EnvironmentError("Path exists but is not a directory.")
    else:
        os.mkdir(directory)
    # We change to the directory. We could only just return its path an let
    # the caller handle the rest (this is the aim for the future)
    os.chdir(directory)
    if not args.quiet:
        print('Working in ' + os.path.realpath(os.path.curdir) + '.')
    return os.path.curdir
    return directory


def find_class_from_url(url): #{{{2
    '''
    Parse the given url and try to find a class that can load from that
    domain.  Return the class.
    '''
    debug_info('Entering find_class_from_url ...')
    url = urllib.parse.urlparse(url)
    debug_info(str(url))
    defined_classes = SiteHandler.__subclasses__()
    debug_info(str(defined_classes))
    if url.netloc is None or url.netloc == '':
        raise BaseException('This url is no good.')
    for cls in defined_classes:
        debug_info(str(cls))
        debug_info(cls.DOMAIN.split('.')[-2:])
        debug_info(url.netloc.split('.')[-2:])
        if url.netloc.split('.')[-2:] == cls.DOMAIN.split('.')[-2:]:
            debug_info('Found it!')
            return cls
    raise NotImplementedError(
            'There is no class available to work with this url.')


def resume(directory, logfile): #{{{2
    debug_info('Entering resume ...')
    log = open(logfile, 'r')
    line = log.readlines()[-1]
    log.close()
    url = line.split()[0]
    debug_info('Found url for resumeing: ' + url)
    cls = find_class_from_url(url)
    worker = cls(directory, logfile)
    worker.start_after(url)


def automatic(string):
    if os.path.exists(os.path.join(args.directory, string)):
        pass
    else:
        try:
            l = url.parse.urlparse(string)
        except:
            print('The fucking ERROR!')


def download_missing(directory, logfile): #{{{2
    '''
    Load all images which are mentioned in the logfile but not present in the
    directory.
    '''
    logfile = open(logfile, 'r')
    logger = BaseLogger('/dev/null', args.quiet)
    for index, line in enumerate(logfile.readlines()):
        if not os.path.exists(line.split(' ', 2)):
            start_thread(download_image, (index, line[1], line[2], logger))


# classes for logging {{{1
class BaseLogger(): #{{{2

    def __init__(self, logfile, quiet=False): #{{{3
        self.log = dict()
        self.logfile = open(logfile, 'a')
        self.quiet = quiet

    def __del__(self): #{{{3
        self.cleanup()

    def add(self, key, url, img, filename): #{{{3
        self.log[key] = (url, img, filename)
        self.logfile.write(' '.join(self.log[key]) + '\n')
        if not self.quiet:
            print(PROG + ': ' + timestring() + ' downloading ' + img + ' -> '
                    + filename)

    def remove(self, key): #{{{3
        del self.log[key]

    def cleanup(self): #{{{3
        self.logfile.close()
        for item in self.log:
            os.remove(item[2])


class Logger(BaseLogger): #{{{2

    #def __init__(self, logfile, quiet=False): #{{{3
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

    def __del__(self): #{{{3
        self.write_logfile()
        self.super().__del__()
        # Do I need to del these manually?
        #del self.logfile
        #del self.log
        #del self.quiet

    def add(self, chap, count, nr=None, url=None, img=None, filename=None): #{{{3
        debug_info('Entering Logger.add ...')
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
            print(PROG + ': ' + timestring() + ' downloading ' + img + ' -> '
                    + filename)

    def success(self, chap, nr): #{{{3
        debug_info('Entering success ...')
        if chap not in self.log:
            raise BaseException('This key was not present:', chap)
        self.log[chap][nr][3] = True
        ## By now we only remove the item maybe we will do more in the future.
        #for item in self.log:
        #    if item[2] == filename:
        #        self.log.remove(item)
        #        return

    def failed(self, chap, nr): #{{{3
        debug_info('Entering failed ...')
        if chap not in self.log:
            raise BaseException('This key was not present:', chap)
        self.log[chap][nr][3] = False
        ## By now we only remove the item maybe we will do more in the future.
        #for item in self.log:
        #    if item[2] == filename:
        #        self.log.remove(item)
        if not self.quiet:
            print(PROG + ': ' + timestring() + 'download failed: ' +
                    item[1] + ' -> ' + item[2])


# site specific classes {{{1

class SiteHandler(): #{{{2

    # References to be implement in subclasses. {{{3
    def extract_key(html): raise NotImplementedError()
    def extract_next_url(html): raise NotImplementedError()
    def extract_img_url(html): raise NotImplementedError()
    def extract_filename(html): raise NotImplementedError()
    def load_intelligent(self, url): raise NotImplementedError()

    def __init__(self, directory, logfile): #{{{3
        debug_info('Entering SiteHandler.__init__ ...')
        logfile = os.path.realpath(os.path.join(directory, logfile))
        self.log = BaseLogger(logfile, args.quiet)
        signal.signal(signal.SIGTERM, self.log.cleanup)
        # We can also try to implement a fifo.  This idea is not yet fully
        # developed.
        #self.fifo = list()
        # This is not optimal: try to not change the dir.
        os.chdir(directory)

    @classmethod
    def expand_rel_url(cls, url): #{{{3
        if '://' in url:
            return url
        elif '//' == url[0:2]:
            return cls.PROTOCOL + ':' + url
        elif '/' == url[0]:
            return cls.PROTOCOL + '://' + cls.DOMAIN + url
        else:
            return cls.PROTOCOL + '://' + cls.DOMAIN + '/' + url


    @classmethod
    def extract_linear(html): #{{{3
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

    def load_image(self, html, url): #{{{3
        debug_info('Entering SiteHandler.load_image ...')
        cls = self.__class__
        try:
            key = cls.extract_key(html)
            img = cls.extract_img_url(html)
            filename = cls.extract_filename(html)
        except AttributeError:
            print(url, 'seems to be the last page.')
            return
        self.log.add(key, url, img, filename)
        download_image(key, img, filename, self.log)

    def load_linear(self, url): #{{{3
        '''
        This method loads all images starting at the specified url.  It will
        walk the sites in a linear manner.  The class with which this method
        is used needs to implement extract_img_url, extract_filename and
        extract_next_url.
        '''
        debug_info('Entering linear_load ...')
        while url is not None:
            html = BeautifulSoup(urllib.request.urlopen(url))
            try:
                nexturl = self.__class__.extract_next_url(html)
            except AttributeError:
                return
            start_thread(self.load_image, (html, url))
            url = nexturl

    def load_linear_fast(self, url): #{{{3
        '''
        This method loads all images starting at the specified url.  It will
        walk the sites in a linear manner.  The necessary information will be
        extracted in a faster way.
        '''
        debug_info('Entering load_linear_fast ...')
        while url is not None:
            html = BeautifulSoup(urllib.request.urlopen(url))
            try:
                key, nexturl, img, filename = \
                        self.__class__.extract_linear(html)
            except AttributeError:
                print('This should never happen!')
                #traceback.print_exception(*sys.exc_info())
                print('Hopefully the url', url, 'was the last one.',
                        'Otherwise an error occured.')
                print('We cought this but will return here.')
                return
            self.log.add(key, url, img, filename)
            start_thread(download_image,
                    (key, img, filename, self.log))
            url = nexturl


    def start_at(self, url): #{{{3
        'Load all images starting at a specific url.' 
        debug_info('Entering SiteHandler.start_at ...')
        try:
            self.load_intelligent(url)
        except NotImplementedError:
            try:
                self.load_linear_fast(url)
            except NotImplementedError:
                self.load_linear(url)

    def start_after(self, url): #{{{3
        'Load all images starting at the url after the one specified.'
        debug_info('Entering SiteHandler.start_after ...')
        request = urllib.request.urlopen(url)
        debug_info('Finished preloading.')
        html = BeautifulSoup(request)
        url = self.__class__.extract_next_url(html)
        self.start_at(url)

class Mangareader(SiteHandler): #{{{2

    # class constants {{{3
    PROTOCOL = 'http'
    DOMAIN = 'www.mangareader.net'

    def __init__(self, directory, logfile): #{{{3
        debug_info('Entering Mangareader.__init__ ...')
        super().__init__(directory, logfile)

    def extract_key(html): #{{{3
        debug_info('Entering Mangareader.extract_key ...')
        return str(Mangareader.extract_chapter_nr(html)) + '-' + str(
                Mangareader.extract_page_nr(html))

    def extract_next_url(html): #{{{3
        debug_info('Entering Mangareader.extract_next_url ...')
        return Mangareader.expand_rel_url(html.find(id='img').parent['href'])

    def extract_img_url(html): #{{{3
        debug_info('Entering Mangareader.extract_img_url ...')
        return html.find(id='img')['src']

    def extract_filename(html): #{{{3
        debug_info('Entering Mangareader.extract_filename ...')
        return re.sub(r'[ -]+', '-', html.find(id="img")["alt"]).lower() + \
                '.' + Mangareader.extract_img_url(html).split('.')[-1]

    def extract_chapter_nr(html): #{{{3
        debug_info('Entering Mangareader.extract_chapter_nr ...')
        return int(html.find(id='mangainfo').h1.string.split()[-1])

    def extract_page_nr(html): #{{{3
        debug_info('Entering Mangareader.extract_page_nr ...')
        return int(html.find(id='mangainfo').span.string.split()[1])

    def extract_page_count(html): #{{{3
        debug_info('Entering Mangareader.extract_page_count ...')
        return len(html.find(id='pageMenu').find_all('option'))

    def extract_page_urls(html): #{{{3
        debug_info('Entering Mangareader.extract_page_urls ...')
        return [Mangareader.expand_rel_url(o['value']) for o in
                html.find(id='pageMenu').find_all('option')]

    def extract_main_page(html): #{{{3
        debug_info('Entering Mangareader.extract_main_page ...')
        return Mangareader.expand_rel_url(
                html.find(id='mangainfo').h2.a['href'])

    def extract_chapter_count(html): #{{{3
        # This should be called with the html for the main page.
        return len(html.find(id='chapterlist').find_all('a'))

    def extract_manga_name(html): #{{{3
        debug_info('Entering Mangareader.extract_manga_name ...')
        c= re.sub(r'(.*) [0-9]+$', r'\1', html.find(id='mangainfo').h1.string)
        print("so: |" + c + '|')
        return c

    def extract_linear(html): #{{{3
        debug_info('Entering Mangareader.extract_linear ...')
        img_tag = html.find(id='img')
        mangainfo = html.find(id='mangainfo')
        key = mangainfo.h1.string.split()[-1] + \
                mangainfo.span.string.split()[1]
        nexturl = Mangareader.expand_rel_url(img_tag.parent['href'])
        img = img_tag['src']
        filename = re.sub(r'[ -]+', '-', img_tag["alt"]).lower() + '.' + \
                img.split('.')[-1]
        return (key, nexturl, img, filename)

    def helper_load_chapter(url, startpage=1): #{{{3
        debug_info('Entering Mangareader.helper_load_chapter ...')
        raise NotImplementedError()

    def helper_load_chapter_2(self, manga, chapter, startpage=1, count=0): #{{{3
        debug_info('Entering Mangareader.helper_load_chapter_2 ...')
        if count == 0:
            # we need the count so we will look it up if it was not given
            html = BeautifulSoup(urllib.request.urlopen(
                    Mangareader.expand_rel_url(manga + '/' + str(chapter))))
            count = self.extract_page_count(html)
        for page in range(startpage, count+1):
            print('xxx',Mangareader.expand_rel_url(manga + '/' + str(chapter) +
                    '/' + str(page))+'|')
            self.helper_load_page_and_image(
                    Mangareader.expand_rel_url(manga + '/' + str(chapter) +
                    '/' + str(page)))

    def helper_load_page_and_image(self, url): #{{{3
        # TODO Can we push this in the superclass?
        debug_info('Entering Mangareader.helper_load_page_and_image ...')
        html = BeautifulSoup(urllib.request.urlopen(url))
        try:
            img = Mangareader.extract_img_url(html)
            filename = Mangareader.extract_filename(html)
        except AttributeError:
            print('This should never happen!',
                    '(Comming from Mangareader.helper_load_page_and_image)')
            traceback.print_exception(*sys.exc_info())
            return
        self.log.add(url, img, filename)
        download_image(img, filename)

    def load_intelligent_1(self, url): #{{{3
        raise NotImplementedError("TODO")
        debug_info('Entering Mangareader.intelligent_load_1 ...')
        while url is not None:
            html = BeautifulSoup(urllib.request.urlopen(url))
            try:
                pagenr = Mangareader.extract_page_nr(html)
                pagecount = Mangareader.extract_page_count(html)
                chapternr = Mangareader.extract_chapter_nr(html)
                nexturl = Mangareader.extract_next_url(html)
            except AttributeError:
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

    def load_intelligent_2(self, url): #{{{3
        debug_info('Entering Mangareader.intelligent_load_2 ...')
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


if __name__ == '__main__': #{{{1
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
    general.add_argument( '-v', '--verbose', dest='quiet', default=False,
            action='store_false', help='verbose output')
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
    #general group {{{3
    parser.add_argument('-V', '--version', action='version',
            version=VERSION_STRING, help='print version information')
    #parser.add_argument('url', nargs='+')
    parser.add_argument('url', nargs='?')
    #parser.add_argument('string', nargs='?', metavar='url/name')

    # parsing arguments {{{2
    args = parser.parse_args()
    args.directory = prepare_output_dir(args.directory, args.url)

    


    #if args.auto:
    #    automatic(args.string)
    #el
    if args.resume and args.url is not None:
        parser.error('You can only use -r or give an url.')
    elif not args.resume and args.url is None:
        parser.error('You must specify -r or an url.')

    print(args)


    # running {{{2
    if args.resume:
        resume(args.directory, args.logfile)
    else:
        cls = find_class_from_url(args.url)
        worker = cls(args.directory, args.logfile)
        #worker = Mangareader(args.directory, args.logfile)
        #worker.run(args.url)
        worker.start_at(args.url)


#with threading.current_thread() as cur:
#    for thread in threading.enumerate():
#        try:
#            if thread != cur:
#                thread.join()
#        except AttributeError:
#            print("AE")

#try:
#    current = threading.current_thread()
#    print(current)
#except:
#    print('Could not get current thread.')
#for thread in threads:
#    thread.join()

try:
    current = threading.current_thread()
    for thread in threading.enumerate():
        if thread != current:
            thread.join()
    print('All threads joined.')
except:
    print('Could not get current thread.  Not waiting for other threads.')
