#! /usr/bin/python2

import sys

import map_utils
from shutil import copy, rmtree
from os import listdir, stat, unlink, mkdir, walk
from os.path import dirname, basename, join as path_join
from errno import ENOENT, EEXIST

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

if len (sys.argv)==0 or sys.argv[1] in ('-h', '--help'):
    # usage
    print """%s [-f|-o|--force|--overwrite] SRC DST MAP...""" % sys.argv[0]
    exit (0)

overwrite= False
if sys.argv[1] in ('-f', '-o', '--force', '--overwrite'):
    overwrite= True
    sys.argv.pop (1)

src= sys.argv.pop (1)
dst= sys.argv.pop (1)
sectors= sys.argv[1:]
atlas= map_utils.Atlas (sectors)

# I assume I will want all the zoom levels
# so I don't have to check for dir contents
for z in range (atlas.minZoom, atlas.maxZoom+1):
    # print "- z", (z, )
    try:
        present_x= listdir (path_join (dst, str (z)))
    except OSError as e:
        if e.errno!=ENOENT:
            raise e
    else:
        for x in ( int (x) for x in present_x ):
            # print "-- dx", (z, x)
            if not (z, x) in atlas:
                d= path_join (dst, str (z), str (x))
                rmtree (d)
                print "X: %s" % d

    for x in atlas.iterate_x (z):
        # print "-- sx", (z, x)
        try:
            present_y= listdir (path_join (dst, str (z), str (x)))
        except OSError as e:
            if e.errno!=ENOENT:
                raise e
        else:
            for y in ( int (y.split ('.')[0]) for y in present_y):
                # print "--- dy", (z, x, y)
                if not (z, x, y) in atlas:
                    f= path_join (dst, str (z), str (x), str (y)+'.png')
                    unlink (f)
                    print "D: %s" % f

        for y in atlas.iterate_y (z, x):
            # print "--- sy", (z, x, y)
            src_y= path_join (src, str (z), str (x), str (y)+'.png')
            dst_y= path_join (dst, str (z), str (x), str (y)+'.png')

            if file_newer (src_y, dst_y) or overwrite:
                try:
                    map_utils.makedirs (path_join (dst, str (z), str (x)))
                    copy (src_y, dst_y)
                    print "C: %s -> %s" % (src_y, dst_y)
                except Exception as e:
                    print e
            else:
                # print "K: %s" % dst_y
                pass
