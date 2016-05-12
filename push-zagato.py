#! /usr/bin/python3

import sys

import map_utils
from shutil import copy, rmtree
from os import listdir, stat, unlink, mkdir, walk, makedirs
from os.path import dirname, basename, join as path_join
from errno import ENOENT, EEXIST
import argparse

def file_newer (src, dst):
    try:
        src_stat= stat (src)
    except OSError as e:
        if e.errno==ENOENT:
            return False
        else:
            raise e

    try:
        dst_stat= stat (dst)
    except OSError as e:
        if e.errno==ENOENT:
            return True
        else:
            raise e

    # print src_stat.st_mtime, dst_stat.st_mtime
    return src_stat.st_mtime>dst_stat.st_mtime

parser= argparse.ArgumentParser ()
parser.add_argument ('-f', '--force',     dest='overwrite', action='store_true')
parser.add_argument ('-o', '--overwrite', dest='overwrite', action='store_true')
parser.add_argument ('-k', '--keep', action='store_true')
parser.add_argument ('-n', '--dry-run', action='store_true')
parser.add_argument ('src', metavar='SRC')
parser.add_argument ('dst', metavar='DST')
parser.add_argument ('maps', metavar='MAP', nargs='+')
opts= parser.parse_args ()

atlas= map_utils.Atlas (opts.maps)

# I assume I will want all the zoom levels
# so I don't have to check for dir contents
for z in range (atlas.minZoom, atlas.maxZoom+1):
    # print ("- z", (z, ))
    try:
        present_x= listdir (path_join (opts.dst, str (z)))
    except OSError as e:
        if e.errno!=ENOENT:
            raise e
    else:
        for x in ( int (x) for x in present_x ):
            # print ("-- dx", (z, x))
            if not (z, x) in atlas and not opts.keep:
                d= path_join (opts.dst, str (z), str (x))
                print ("X: %s" % d)
                if not opts.dry_run:
                    rmtree (d)

    for x in atlas.iterate_x (z):
        # print ("-- sx", (z, x))
        try:
            present_y= listdir (path_join (opts.dst, str (z), str (x)))
        except OSError as e:
            if e.errno!=ENOENT:
                raise e
        else:
            for y in ( int (y.split ('.')[0]) for y in present_y):
                # print ("--- dy", (z, x, y))
                if not (z, x, y) in atlas and not opts.keep:
                    f= path_join (opts.dst, str (z), str (x), str (y)+'.png')
                    print ("D: %s" % f)
                    if not opts.dry_run:
                        unlink (f)

        for y in atlas.iterate_y (z, x):
            # print ("--- sy", (z, x, y))
            src_y= path_join (opts.src, str (z), str (x), str (y)+'.png')
            dst_y= path_join (opts.dst, str (z), str (x), str (y)+'.png')

            if file_newer (src_y, dst_y) or opts.overwrite:
                try:
                    print ("C: %s -> %s" % (src_y, dst_y))
                    if not opts.dry_run:
                        makedirs (path_join (opts.dst, str (z), str (x)), exist_ok=True)
                        copy (src_y, dst_y)
                except Exception as e:
                    print (e)
            else:
                # print ("K: %s" % dst_y)
                pass
