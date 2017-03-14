# kate: replace-tabs: off; indent-width 8

# options used everywhere
# gopts = -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW
gopts = -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZMA -co LZMA_PRESET=9

# for the main directory
all:
	make -C datafiles -j 4 all_single
	make main

# this Makefile has two goals:

#############
# FIRST GOAL
# the first goal is to processes the original DEM files and produces 3 or 4 files:
# * an optional corrected version, for those DEMs that are not in the proper scale.
# * final terrain, slopeshade and hillshade versions.

height_files = $(wildcard *1arc_v3.tif) $(wildcard *.hgt)
corrected_files = $(foreach height_file,$(height_files),$(subst .tif,-corrected.tif, $(height_file)))
terrain_files =   $(foreach height_file,$(height_files),$(subst .tif,-terrain.tif,   $(height_file))) \
                  $(foreach height_file,$(height_files),$(subst .hgt,-terrain.tif,   $(height_file)))
hill_files =      $(foreach height_file,$(height_files),$(subst .tif,-hillshade.tif, $(height_file))) \
                  $(foreach height_file,$(height_files),$(subst .hgt,-hillshade.tif, $(height_file)))
slope_files =     $(foreach height_file,$(height_files),$(subst .tif,-slopeshade.tif,$(height_file))) \
                  $(foreach height_file,$(height_files),$(subst .hgt,-slopeshade.tif,$(height_file)))
all_files = $(sort $(terrain_files) $(hill_files) $(slope_files))

# do not remove these intermediate files
.SECONDARY: $(corrected_files)

# but removed failed ones
.DELETE_ON_ERROR:

all_single: $(all_files)

# deFerrantis haves some of the polar files at 1801 pixels instead of the 3601
# so we have to 'correct' them
# unit is degree (math.pi/180)
# units/pixel= 1 deg/3600 (1 arc sec) = 0.000277777777778
WebMerc = "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over"
%-corrected.tif: %.tif
	@if gdalinfo $< | grep -q 'Size is 1801'; then \
		gdalwarp $(gopts) -tr 0.000277777777778 -0.000277777777778 $< $@; \
	else \
		gdalwarp $(gopts) -t_srs $(WebMerc) -r lanczos $< $@; \
	fi

%-terrain.tif: %-corrected.tif color-relief.txt
	gdaldem color-relief -alpha $(gopts) $< color-relief.txt $@

%-hillshade.tif: %-corrected.tif
	gdaldem hillshade -alg Horn -s 111120 -compute_edges $(gopts) $< $@

%-slope.tif: %-corrected.tif
	gdaldem slope -alg Horn $(gopts) -compute_edges -p $< $@

%-terrain.tif: %.hgt color-relief.txt
	gdaldem color-relief -alpha $(gopts) $< color-relief.txt $@

%-hillshade.tif: %.hgt
	gdaldem hillshade -alg Horn -s 111120 -compute_edges $(gopts) $< $@

%-slope.tif: %.hgt
	gdaldem slope -alg Horn $(gopts) -compute_edges -p $< $@

%-slopeshade.tif: %-slope.tif slope.txt
	gdaldem color-relief $(gopts) $< slope.txt $@

# TODO: readd the .sql files with the contour lines

##############
# SECOND GOAL
# the second goal is to combine these versions in three .vrt files,
# so it can be used directly by the rendering engine
# and also a small version so it can be used for rendering low zoom levels (currently 7 and below)

# iterate first over the suffixes, then the datafiles
# so .vrt are built first and small later
# (but that should be resolved by the deps anyways)
main_files = $(foreach suf,.vrt -medium.tif -small.tif,\
                     $(foreach datafile,terrain slopeshade hillshade,\
		               $(addsuffix $(suf),mixed-$(datafile))))

main: $(main_files)

%-medium.tif: %.vrt
	rm -f $@
# 4 times less resolute than the original
# units/pixel= 1 deg/900 (4 arc sec) = 0.001111111111111
	gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW -tr 0.001111111111111 -0.001111111111111 $< $@

%-small.tif: %.vrt
	rm -f $@
# 8 times less resolute than the original
# units/pixel= 1 deg/450 (8 arc sec) = 0.002222222222222
	gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW -tr 0.002222222222222 -0.002222222222222 $< $@

tiny: mixed-terrain-tiny.tif mixed-hillshade-tiny.tif mixed-slopeshade-tiny.tif

%-tiny.tif: %-small.tif
	rm -f $@
# 8 times less resolute than -small (64 times the original)
# units/pixel= 1 deg/56.25 (64 arc sec) = 0.017777777777778
	gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW -tr 0.017777777777778 -0.017777777777778 $< $@

###############################################
# the old targets, left for historical reasons
master = mixed.tif
hillshade = mixed-hillshade.tif
slopeshade = mixed-slopeshade.tif
relief = mixed-terrain.tif
# shapefiles = $(foreach height_file, $(height_files), $(basename $(height_file)) )

# all: $(hillshade) $(relief) $(slopeshade)
# contour10.shp contour100.shp contour500.shp contour1000.shp
# mixed_contour.sql
# $(shapefiles)

define gdal-contour
gdal_contour -i 50 -a height $< .
shapeindex $(basename )
endef

define shp2pgsql
shp2pgsql -c -I -g way $(basename $<) contours > $@
endef

$(master): $(height_files)
	gdal_merge.py -o $@ -v $^

mixed_contour.sql: contour.shp
	$(shp2pgsql)

contour.shp: $(master)
	$(gdal-contour)

contour1000.shp: contour.shp
	ogr2ogr -f "ESRI Shapefile" -overwrite -where "height >0 and height % 1000 = 0" contour1000.shp contour.shp

contour500.shp: contour.shp
	ogr2ogr -f "ESRI Shapefile" -overwrite -where "height >0 and height % 500 = 0 and height % 1000 != 0" contour500.shp contour.shp

contour100.shp: contour.shp
	ogr2ogr -f "ESRI Shapefile" -overwrite -where "height >0 and height % 100 = 0 and height % 500 != 0 and height % 1000 != 0" contour100.shp contour.shp

contour10.shp: contour.shp
	ogr2ogr -f "ESRI Shapefile" -overwrite -where "height >0 and height % 100 != 0 and height % 500 != 0 and height % 1000 != 0" contour10.shp contour.shp

# %.sql: %.shp
# 	$(shp2pgsql)

# %.shp: %.hgt
# 	$(gdal-contour)
