#! /usr/bin/python2

import sys
from os.path import dirname, basename, join as path_join
from os import listdir, stat, unlink, mkdir
from errno import ENOENT, EEXIST
from shutil import copy

def makedirs(_dirname):
    """ Better replacement for os.makedirs():
        doesn't fails if some intermediate dir already exists.
    """
    dirs = _dirname.split('/')
    i = ''
    while len(dirs):
        i += dirs.pop(0)+'/'
        try:
            mkdir(i)
        except OSError, e:
            if e.args[0]!=EEXIST:
                raise e

def file_newer (src, dst):
    try:
        src_stat= stat (src)
    except OSError, e:
        if e.errno==ENOENT:
            return False
        else:
            raise e

    try:
        dst_stat= stat (dst)
    except OSError, e:
        if e.errno==ENOENT:
            return True
        else:
            raise e

    return src_stat.st_mtime>dst_stat.st_mtime

def process_dir (src, dst, path, wanted):
    try:
        present= set (listdir (path_join (dst, path)))
    except OSError, e:
        if e.errno==ENOENT:
            present= set ()
        else:
            raise e

    to_delete= present-wanted
    to_copy= (f for f in wanted
                if (f not in present or
                    file_newer (path_join (src, path, f),
                                path_join (dst, path, f))))

    # print present, wanted, to_delete, tuple (to_copy)

    for f in to_delete:
        f= path_join (dst, path, f)
        unlink (f)
        print "D: %s" % f

    for f in to_copy:
        f1= path_join (src, path, f)
        f2= path_join (dst, path, f)
        makedirs (path_join (dst, path))
        try:
            copy (f1, f2)
            print "C: %s -> %s" % (f1, f2)
        except IOError, e:
            if e.errno==ENOENT:
                # we want the file but it's not actually there
                pass
            else:
                raise e

src, dst= sys.argv[1:]

d1= None
files= set ()
for line in sys.stdin:
    d2= dirname (line)
    # remove the trailing \n
    f= basename (line)[:-1]
    if d2!=d1 and d1 is not None:
        process_dir (src, dst, d1, files)
        files= set ((f,))
    else:
        files.add (f)

    d1= d2

if d1 is not None:
    process_dir (src, dst, d1, files)
