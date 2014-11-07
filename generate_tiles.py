#!/usr/bin/env python

from math import pi,cos,sin,log,exp,atan
from subprocess import call
import sys, os, os.path
from Queue import Queue
from optparse import OptionParser
import time
import errno

import threading

try:
    import mapnik2 as mapnik
except:
    import mapnik

import multiprocessing

DEG_TO_RAD = pi/180
RAD_TO_DEG = 180/pi

try:
    NUM_CPUS = multiprocessing.cpu_count ()
except NotImplementedError:
    NUM_CPUS = 1


def makedirs(_dirname):
    """ Better replacement for os.makedirs():
        doesn't fails if some intermediate dir already exists.
    """
    dirs = _dirname.split('/')
    i = ''
    while len(dirs):
        i += dirs.pop(0)+'/'
        try:
            os.mkdir(i)
        except OSError, e:
            if e.args[0]!=errno.EEXIST:
                raise e


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



class RenderThread:
    def __init__(self, tile_dir, mapfile, q, printLock, maxZoom, meta_size):
        self.tile_dir = tile_dir
        self.q = q
        self.meta_size= meta_size
        self.tile_size= 256
        self.image_size= self.tile_size*self.meta_size
        self.m = mapnik.Map(self.image_size, self.image_size)
        self.printLock = printLock
        # Load style XML
        mapnik.load_map(self.m, mapfile, True)
        # Obtain <Map> projection
        self.prj = mapnik.Projection(self.m.srs)
        # Projects between tile pixel co-ordinates and LatLong (EPSG:4326)
        self.tileproj = GoogleProjection(maxZoom+1)


    def render_tile(self, tile_base_dir, x, y, z):
        # Calculate pixel positions of bottom-left & top-right
        p0 = (x * self.tile_size, (y + self.meta_size) * self.tile_size)
        p1 = ((x + self.meta_size) * self.tile_size, y * self.tile_size)

        # Convert to LatLong (EPSG:4326)
        l0 = self.tileproj.fromPixelToLL(p0, z);
        l1 = self.tileproj.fromPixelToLL(p1, z);

        # Convert to map projection (e.g. mercator co-ords EPSG:900913)
        c0 = self.prj.forward(mapnik.Coord(l0[0],l0[1]))
        c1 = self.prj.forward(mapnik.Coord(l1[0],l1[1]))

        # Bounding box for the tile
        if hasattr(mapnik,'mapnik_version') and mapnik.mapnik_version() >= 800:
            bbox = mapnik.Box2d(c0.x,c0.y, c1.x,c1.y)
        else:
            bbox = mapnik.Envelope(c0.x,c0.y, c1.x,c1.y)

        self.m.resize(self.image_size, self.image_size)
        self.m.zoom_to_box(bbox)
        if(self.m.buffer_size < 128):
            self.m.buffer_size = 128

        # Render image with default Agg renderer
        start= time.time ()
        im = mapnik.Image(self.image_size, self.image_size)
        mapnik.render(self.m, im)
        end= time.time ()

        # save the image, splitting it in the right amount of tiles
        # we use min() so we can support low zoom levels with less than meta_size tiles
        for i in xrange (min (self.meta_size, 2**z)):
            tile_dir= os.path.join (tile_base_dir, str (z), str (x+i))
            makedirs (tile_dir)
            for j in xrange (min (self.meta_size, 2**z)):
                # print "%d:%d:%d" % (x+i, y+j, z)
                k= im.view (i*self.tile_size, j*self.tile_size, self.tile_size, self.tile_size)
                tile_uri = os.path.join (tile_dir, str (y+j)+'.png')
                k.save(tile_uri, 'png256')

        # self.printLock.acquire()
        print "%d:%d:%d: %f" % (x, y, z, end-start)
        # self.printLock.release()

    def loop(self):
        while True:
            #Fetch a tile from the queue and render it
            r = self.q.get()
            if (r == None):
                self.q.task_done()
                break
            else:
                (name, tile_base_uri, x, y, z) = r

            all_exist= True
            exists= ""
            # we use min() so we can support low zoom levels with less than meta_size tiles
            for tile_x in range (x, x+min (self.meta_size, 2**z)):
                for tile_y in range (y, y+min (self.meta_size, 2**z)):
                    tile_uri= os.path.join (tile_base_uri, str (z), str (tile_x), str(tile_y)+'.png')
                    all_exist= all_exist and os.path.isfile(tile_uri)
                    # print "%s: %s" % (tile_uri, all_exist)

            if all_exist:
                exists= "exists"
            else:
                self.render_tile(tile_base_uri, x, y, z)

            bytes=os.stat(tile_uri)[6]
            empty= ''
            if bytes == 103:
                empty = " Empty Tile "
            # print name, ":", z, x, y, exists, empty
            self.q.task_done()


def render_tiles(bbox, mapfile, tile_dir, minZoom=1,maxZoom=18, name="unknown",
                 num_threads=NUM_CPUS, tms_scheme=False, meta_size=1):
    print "render_tiles(",bbox, mapfile, tile_dir, minZoom,maxZoom, name,")"

    # Launch rendering threads
    queue = Queue(32)
    printLock = threading.Lock()
    renderers = {}
    for i in range(num_threads):
        renderer = RenderThread(tile_dir, mapfile, queue, printLock, maxZoom,
                                meta_size)
        render_thread = threading.Thread(target=renderer.loop)
        render_thread.start()
        #print "Started render thread %s" % render_thread.getName()
        renderers[i] = render_thread

    if not os.path.isdir(tile_dir):
         os.mkdir(tile_dir)

    gprj = GoogleProjection(maxZoom+1)

    ll0 = (bbox[0],bbox[3])
    ll1 = (bbox[2],bbox[1])

    image_size=256.0*meta_size

    for z in range(minZoom,maxZoom + 1):
        px0 = gprj.fromLLtoPixel(ll0,z)
        px1 = gprj.fromLLtoPixel(ll1,z)

        for x in range(int(px0[0]/image_size),int(px1[0]/image_size)+1):
            # Validate x co-ordinate
            if (x < 0) or (x*meta_size >= 2**z):
                continue

            for y in range(int(px0[1]/image_size),int(px1[1]/image_size)+1):
                # Validate x co-ordinate
                if (y < 0) or (y*meta_size >= 2**z):
                    continue

                # Submit tile to be rendered into the queue
                t = (name, tile_dir, x*meta_size, y*meta_size, z)
                try:
                    queue.put(t)
                except KeyboardInterrupt:
                    raise SystemExit("Ctrl-c detected, exiting...")

    # Signal render threads to exit by sending empty request to queue
    for i in range(num_threads):
        queue.put(None)
    # wait for pending rendering jobs to complete
    queue.join()
    for i in range(num_threads):
        renderers[i].join()

if __name__ == "__main__":
    parser= OptionParser ()

    parser.add_option ('-b', '--bbox',          dest='bbox',      default='-180,-90,180,90')
    parser.add_option ('-i', '--input-file',    dest='mapfile',   default='osm.xml')
    parser.add_option ('-m', '--metatile-size', dest='meta_size', default=1, type='int')
    parser.add_option ('-n', '--min-zoom',      dest='mn_zoom',   default=0, type="int")
    parser.add_option ('-o', '--output-dir',    dest='tile_dir',  default='tiles/')
    parser.add_option ('-t', '--threads',       dest='threads',   default=NUM_CPUS, type="int")
    parser.add_option ('-x', '--max-zoom',      dest='mx_zoom',   default=18, type="int")
    options, args= parser.parse_args ()

    if options.tile_dir[-1]!='/':
        # we need the trailing /, it's actually a series of BUG s in render_tiles()
        options.tile_dir+= '/'

    bbox = [ float (x) for x in options.bbox.split (',') ]

    render_tiles(bbox, options.mapfile, options.tile_dir,
                 options.mn_zoom, options.mx_zoom, "Elevation",
                 num_threads=options.threads, meta_size=options.meta_size)