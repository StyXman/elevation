#! /usr/bin/python3

import sys
from shutil import copy, rmtree
from os import listdir, stat, unlink, mkdir, walk, makedirs
from os.path import dirname, basename, join as path_join
from errno import ENOENT, EEXIST
import argparse

import map_utils

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

def update (opts, x, y, z):
    # print ("--- sy", (z, x, y))
    src_y= path_join (opts.src, str (z), str (x), str (y)+'.png')
    dst_y= path_join (opts.dst, str (z), str (x), str (y)+'.png')

    if file_newer (src_y, dst_y) or opts.overwrite:
        try:
            print ("C: %s -> %s" % (src_y, dst_y))
            if not opts.dry_run:
                # TODO: find a copy() function that does not try to set the owner/perms.
                # chmod("/home/mdione/media/Nokia N9/local/share/marble/maps/earth/Elevation/14/8445/5971.png", 0644) = -1 EPERM (Operation not permitted)
                makedirs (path_join (opts.dst, str (z), str (x)), exist_ok=True)
                copy (src_y, dst_y)
        except Exception as e:
            print (e)
    else:
        # print ("K: %s" % dst_y)
        pass

parser= argparse.ArgumentParser ()
parser.add_argument ('-f', '--force',     dest='overwrite', action='store_true')
parser.add_argument ('-o', '--overwrite', dest='overwrite', action='store_true')
parser.add_argument ('-k', '--keep', action='store_true')
parser.add_argument ('-n', '--dry-run', action='store_true')
parser.add_argument ('-u', '--update', action='store_true', help='implies --keep')
parser.add_argument ('-s', '--size', action='store_true')
parser.add_argument ('src', metavar='SRC')
parser.add_argument ('dst', metavar='DST')
parser.add_argument ('maps', metavar='MAP', nargs='+')
opts= parser.parse_args ()

atlas = map_utils.Atlas(opts.maps)

# TODO: other backends
src = map_utils.DiskBackend(opts.src)

if opts.size:
    dirs = 0
    files = 0
    total_bytes = 0

    for z in range(atlas.minZoom, atlas.maxZoom + 1):
        # the zoom_level dir counts
        dirs += 1

        for x in atlas.iterate_x(z):
            # this one too
            dirs += 1

            for y in atlas.iterate_y(z, x):
                tile = map_utils.Tile(z, x, y)

                if src.exists(tile):
                    files += 1
                    total_bytes += src.size(tile)

    print("dirs: %s; files: %d; total bytes: %d" % (dirs, files, total_bytes))

    sys.exit(0)

if opts.update:
    # to avoid (not opts.keep or opts.update)
    opts.keep= True


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
            if not (z, x) in atlas:
                if not opts.keep:
                    d= path_join (opts.dst, str (z), str (x))
                    print ("X: %s" % d)
                    if not opts.dry_run:
                        rmtree (d)
                elif opts.update:
                    # TODO
                    pass

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
                if not (z, x, y) in atlas:
                    if not opts.keep:
                        f= path_join (opts.dst, str (z), str (x), str (y)+'.png')
                        print ("D: %s" % f)
                        if not opts.dry_run:
                            unlink (f)
                    elif opts.update:
                        update (opts, x, y, z)

        for y in atlas.iterate_y (z, x):
            update (opts, x, y, z)
