#! /usr/bin/python2

import sys
from math import pi,cos,sin,log,exp,atan, ceil, floor
from os.path import dirname, basename, join as path_join
from os import listdir, stat, unlink, mkdir, walk
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

    # print src_stat.st_mtime, dst_stat.st_mtime
    return src_stat.st_mtime>dst_stat.st_mtime

def coord_range (mn, mx, zoom):
    image_size=256.0
    return ( coord for coord in range (mn, mx+1)
                   if coord >= 0 and coord < 2**zoom )

class Map:
    def __init__ (self, bbox, max_z):
        ll0 = (bbox[0],bbox[3])
        ll1 = (bbox[2],bbox[1])
        gprj = GoogleProjection(max_z+1)

        self.levels= []
        for z in range (0, max_z+1):
            px0 = gprj.fromLLtoPixel(ll0,z)
            px1 = gprj.fromLLtoPixel(ll1,z)
            # print px0, px1
            self.levels.append (( (int (px0[0]/256), int (px0[1]/256)),
                                  (int (px1[0]/256), int (px1[1]/256)) ))
        # print self.levels

    def __contains__ (self, t):
        if len (t)==3:
            z, x, y= t
            px0, px1= self.levels[z]
            # print (z, px0[0], x, px1[0], px0[1], y, px1[1])
            ans= px0[0]<=x and x<=px1[0]
            # print ans
            ans= ans and px0[1]<=y and y<=px1[1]
            # print ans
        elif len (t)==2:
            z, x= t
            px0, px1= self.levels[z]
            # print (z, px0[0], x, px1[0])
            ans= px0[0]<=x and x<=px1[0]
        else:
            raise ValueError

        return ans

    def iterate_x (self, z):
        px0, px1= self.levels[z]
        return coord_range (px0[0], px1[0], z) # NOTE

    def iterate_y (self, z):
        px0, px1= self.levels[z]
        return coord_range (px0[1], px1[1], z) # NOTE

class Atlas:
    def __init__ (self, sectors):
        self.maps= []
        c= ConfigParser ()
        c.read ('bboxes.ini')
        self.minZoom= 0
        self.maxZoom= 0

        for sector in sectors:
            sector= [ float (x) for x in c.get ('bboxes', sector).split (',') ]
            # #4 is the max_z
            if sector[4]>self.maxZoom:
                self.maxZoom= int (sector[4])

        for sector in sectors:
            sector= [ float (x) for x in c.get ('bboxes', sector).split (',') ]
            self.maps.append (Map (sector[:4], self.maxZoom))

    def __contains__ (self, t):
        w= False
        for m in self.maps:
            w= w or t in m

        return w

    def iterate_x (self, z):
        for m in self.maps:
            for x in m.iterate_x (z):
                yield x

    def iterate_y (self, z, x):
        for m in self.maps:
            if (z, x) in m:
                for y in m.iterate_y (z):
                    yield y

src= sys.argv.pop (1)
dst= sys.argv.pop (1)
sectors= sys.argv[1:]
atlas= Atlas (sectors)

# I assume I will want all the zoom levels
# so I don't have to check for dir contents
for z in range (atlas.minZoom, atlas.maxZoom+1):
    # print "- z", (z, )
    try:
        present_x= listdir (path_join (dst, str (z)))
    except OSError, e:
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
        except OSError, e:
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

            if file_newer (src_y, dst_y):
                makedirs (path_join (dst, str (z), str (x)))
                try:
                    copy (src_y,dst_y)
                    print "C: %s -> %s" % (src_y, dst_y)
                except Exception, e:
                    print e
            else:
                print "K: %s" % dst_y
