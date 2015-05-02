# kate: replace-tabs: off; indent-width 8

height_files = $(wildcard *1arc_v3.tif) $(wildcard *.hgt)
corrected_files = $(foreach height_file,$(height_files),$(subst .tif,-corrected.tif, $(height_file)))
terrain_files =   $(foreach height_file,$(height_files),$(subst .tif,-terrain.tif,   $(height_file))) \
                  $(foreach height_file,$(height_files),$(subst .hgt,-terrain.tif,   $(height_file)))
hill_files =      $(foreach height_file,$(height_files),$(subst .tif,-hillshade.tif, $(height_file))) \
                  $(foreach height_file,$(height_files),$(subst .hgt,-hillshade.tif, $(height_file)))
slope_files =     $(foreach height_file,$(height_files),$(subst .tif,-slopeshade.tif,$(height_file))) \
                  $(foreach height_file,$(height_files),$(subst .hgt,-slopeshade.tif,$(height_file)))

master = mixed.tif
hillshade = mixed_hillshade.tif
slopeshade = mixed_slopeshade.tif
relief = mixed_relief.tif
# shapefiles = $(foreach heigh_file, $(height_files), $(basename $(height_file)) )

gopts = -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW

# all: $(hillshade) $(relief) $(slopeshade)
all_single: $(terrain_files) $(hill_files) $(slope_files)
# contour10.shp contour100.shp contour500.shp contour1000.shp
# $(shapefiles)

# TODO: gdalinfo /vsizip/N43E016.zip/N43E006.hgt
$(master): $(height_files)
	gdal_merge.py -o $@ -v $^

.SECONDARY: $(correctd_files)

%-corrected.tif: %.tif
	if gdalinfo $< | grep -q 'Size is 1801'; then gdalwarp $(gopts) -tr 0.000277777777778 -0.000277777777778 $< $@; else ln $< $@; fi

%-terrain.tif: %-corrected.tif color-relief.txt
	gdaldem color-relief -alpha $(gopts) $< color-relief.txt $@

%-hillshade.tif: %-corrected.tif
	gdaldem hillshade -alg Horn -s 111120 -compute_edges $(gopts) $< $@

%-slope.tif: %-corrected.tif
	gdaldem slope -alg Horn $(gopts) -compute_edges -p $< $@

%-slopeshade.tif: %-slope.tif slope.txt
	gdaldem color-relief $(gopts) $< slope.txt $@

define gdal-contour
gdal_contour -i 50 -a height $< .
shapeindex $(basename )
endef

define shp2pgsql
shp2pgsql -c -I -g way $(basename $<) contours > $@
endef

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
