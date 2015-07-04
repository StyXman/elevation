This set of scripts and data files are aimed to get data, process it, prepare
source files, render maps, copy them to servers and even maybe you phone. For
the moment being, they're too coupled to my own setup, but I definitely plan to
make it as general as possible.

# Dependencies

* `python-sqlalchemy` (for MBTiles backend)
* `python-mapnik` (of course :)
* [`ayrton`](https://github.com/StyXman/ayrton) (for several scripts)

# Usage

The workflow is a little bit long, but worth it :) This probably should be a
script, but the fact that I have been doing some steps here and there while
tuning this thing lead to have none yet.

* Get a file with the source data from OSM. This can be achieved in several ways,
  but I recommend [Geofabrik's](http://geofabrik.de/) [planet extracts](http://download.geofabrik.de/):

    cd data/osm
    wget [dbf_url]

* Create the `gis` database:

    ./import-osm-data.sh restart

* Import the data. You can use --bbox to limit the import or any other osm2pgsql
  option:

    ./import-osm-data.sh import [dbf_file]

* Get the DEMs for that region:

    cd ../height
    ./pull_height.ay ../osm/[dbf_file] # for this you will need ayrton properly installed

* Generate the terrain, slopeshade and hillshade raster images, and contour files:

    make # in fact this Makefile has a lot of info about doing these four things

* Import the contour files

* Clone my own version of openstreetmap-carto

* Get all the needed shapefiles.

(TBF)
