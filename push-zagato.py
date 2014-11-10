#! /usr/bin/python2

import sys
from math import pi,cos,sin,log,exp,atan
from os.path import dirname, basename, join as path_join
from os import listdir, stat, unlink, mkdir
from errno import ENOENT, EEXIST
from shutil import copy, rmtree
from ConfigParser import ConfigParser

# shamelessly taken from generate_tiles.py
DEG_TO_RAD = pi/180
RAD_TO_DEG = 180/pi

def minmax (a,b,c):
    a = max(a,b)
    a = min(a,c)
    return a


class GoogleProjection:
    def __init__(self,levels=18):
        self.Bc = []
        self.Cc = []
        self.zc = []
        self.Ac = []
        c = 256
        for d in range(0,levels):
            e = c/2;
            self.Bc.append(c/360.0)
            self.Cc.append(c/(2 * pi))
            self.zc.append((e,e))
            self.Ac.append(c)
            c *= 2

    def fromLLtoPixel(self,ll,zoom):
         d = self.zc[zoom]
         e = round(d[0] + ll[0] * self.Bc[zoom])
         f = minmax(sin(DEG_TO_RAD * ll[1]),-0.9999,0.9999)
         g = round(d[1] + 0.5*log((1+f)/(1-f))*-self.Cc[zoom])
         return (e,g)

    def fromPixelToLL(self,px,zoom):
         e = self.zc[zoom]
         f = (px[0] - e[0])/self.Bc[zoom]
         g = (px[1] - e[1])/-self.Cc[zoom]
         h = RAD_TO_DEG * ( 2 * atan(exp(g)) - 0.5 * pi)
         return (f,h)

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

def process_x (src, dst, path, wanted):
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

    # TODO: rmtree() empty dirs
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


bboxes= {}
src= sys.argv.pop (1)
dst= sys.argv.pop (1)
sectors_wanted= sys.argv[1:]
c= ConfigParser ()
c.read ('bboxes.ini')
minZoom= 0
maxZoom= 0

for sector in sectors_wanted:
    bboxes[sector]= [ float (x) for x in c.get ('bboxes', sector).split (',') ]
    # #4 is the max_z
    if bboxes[sector][4]>maxZoom:
        maxZoom= int (bboxes[sector][4])

gprj = GoogleProjection(maxZoom+1)

def coord_range (mn, mx, zoom):
    image_size=256.0
    return ( coord for coord in range (int (mn/image_size), int (mx/image_size)+1)
                   if coord >= 0 and coord < 2**zoom )

# I assume I will want all the zoom levels
# so I don't have to check for dir contents
for z in range(minZoom,maxZoom + 1):

    # NOTE: I think that there is a way to factorize this with process_x()
    # but for the moment I'll just do the brute force way
    wanted_x= set ()
    for sector in sectors_wanted:
        bbox= bboxes[sector]
        ll0 = (bbox[0],bbox[3])
        ll1 = (bbox[2],bbox[1])
        px0 = gprj.fromLLtoPixel(ll0,z)
        px1 = gprj.fromLLtoPixel(ll1,z)

        for x in coord_range (px0[0], px1[0], z):
            print "W: %s" % path_join (src, str(z), str (x))
            # NOTE: I could also compare the dirs' mtimes to see if they're actually updated.
            # which reinforces the idea that I could actually factorize this with process_x()
            wanted_x.add (str (x))

    try:
        present_x= set (listdir (path_join (dst, str (z))))
    except OSError, e:
        if e.errno==ENOENT:
            present_x= set ()
        else:
            raise e

    # clean up the dst dirs no longer wanted
    x_to_delete= present_x-wanted_x

    for x in x_to_delete:
        d= path_join (dst, str (z), str (x))
        rmtree (d)
        print "X: %s" % d

    for x in wanted_x:
        process_x (src, dst, path_join (str (z), str (x)),
                   set ([ str (y)+'.png' for y in coord_range (px0[1], px1[1], z) ]))
