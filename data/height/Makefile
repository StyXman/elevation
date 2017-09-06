# kate: replace-tabs: off; indent-width 8

# data/height/Make

# options used everywhere
gopts = -co BIGTIFF=YES
# -co TILED=YES -co COMPRESS=LZMA -co LZMA_PRESET=9
# options used in final filkes because of
# Cannot open TIFF file due to missing codec
# see: https://gis.stackexchange.com/questions/72463/qgis-2-0-cannot-open-tiff
final_gopts = -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW
# apply to slope (not slopeshade) and hillshade processing
# scale_option = -s 111120
scale_option = -s 1

# for the main directory
all:
	make -C datafiles -j 4 all_single
	make main

# this Makefile is multipurposse, to be used at the root of the height data dir
# (data/height) and on each provider's dir

# but minor goals first
prepare:


#############
# FIRST GOAL
# the first goal is to processes the original DEM files and produces 3 or 4 files:
# * an optional corrected version, for those DEMs that are not in the proper scale.
# * final terrain, slopeshade and hillshade versions.
# this is used on the provider's dirs

height_files = $(wildcard *1arc_v3.tif) $(wildcard *.hgt *5deg*5.tif  *5deg*0.tif)
# corrected_files = $(foreach height_file,$(height_files),$(subst .tif,-corrected.tif, $(height_file)))
corrected_files = $(foreach column,000 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017,)
terrain_files =   $(foreach height_file,$(height_files),$(subst .tif,-terrain.tif,   $(height_file))) \
                  $(foreach height_file,$(height_files),$(subst .hgt,-terrain.tif,   $(height_file)))
hill_files =      $(foreach height_file,$(height_files),$(subst .tif,-hillshade.tif, $(height_file))) \
                  $(foreach height_file,$(height_files),$(subst .hgt,-hillshade.tif, $(height_file)))
slope_files =     $(foreach height_file,$(height_files),$(subst .tif,-slopeshade.tif,$(height_file))) \
                  $(foreach height_file,$(height_files),$(subst .hgt,-slopeshade.tif,$(height_file)))
all_files = $(sort $(corrected_files) $(terrain_files) $(hill_files) $(slope_files))

# do not remove these intermediate files
.SECONDARY: $(corrected_files)

# but removed failed ones
.DELETE_ON_ERROR:

all_single: $(all_files)

# deFerrantis haves some of the polar files at 1801 pixels instead of the 3601
# so we have to 'correct' them
# unit is degree (2*math.pi / 360)
# units/pixel= 1 deg/3600 (1 arc sec) = 0.000277777777778
WebMerc = "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over"
m_per_pixel=30.92208077590933
%-corrected.tif: %.tif
	gdalwarp $(gopts) -t_srs $(WebMerc) -r lanczos \
		-tr $(m_per_pixel) -$(m_per_pixel) $< $@; \

%-corrected.tif: %.hgt
	gdalwarp $(gopts) -t_srs $(WebMerc) -r lanczos \
		-tr $(m_per_pixel) -$(m_per_pixel) $< $@; \

%-terrain.tif: %-corrected.tif color-relief.txt
	gdaldem color-relief -alpha $(final_gopts) $< color-relief.txt $@

%-hillshade.tif: %-corrected.tif
	gdaldem hillshade -alg Horn $(scale_option) -compute_edges $(final_gopts) $< $@

%-slopeshade.tif: %-corrected.tif slope.txt
# %-slopeshade.tif: %.tif slope.txt
# %-slopeshade.tif: %.hgt slope.txt
# %-slopeshade.tif: %.dem slope.txt
	gdaldem slope -alg Horn $(scale_option) -compute_edges $(gopts) $< $(subst -slopeshade,-slope,$@)
	gdaldem color-relief $(final_gopts) $(subst -slopeshade,-slope,$@) slope.txt $@
	rm $(subst -slopeshade,-slope,$@)

# %-corrected.shp/contour.shp: %-corrected.tif
# 	mkdir -pv $(dir $@)
# 	gdal_contour -i 50 -a height $< $(dir $@)
# 	for ext in dbf prj shp shx; do \
# 		mv -v contour.$$ext .$$ext; \
# 	done

# %-corrected.sql: %-corrected.shp/contour.shp
# 	shp2pgsql -c -I -g way $(basename $<) contours > $@
# 	rm -rfv $(dir $<)

%-corrected.sql.xz: %-corrected.sql
	xz -9 $<

%-corrected.sql: %-corrected.tif
	mkdir -pv $(basename $<).shp
	gdal_contour -i 50 -a height $< $(basename $<).shp
	shp2pgsql -c -I -g way $(basename $<).shp/contour contours > $@
	rm -rfv $(basename $<).shp

terrain.vrt: *-terrain.tif
	# gdalbuildvrt $@


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
	gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW -tr 123.68832310363732 -123.68832310363732 $< $@

%-small.tif: %.vrt
	rm -f $@
# 8 times less resolute than the original
# units/pixel= 1 deg/450 (8 arc sec) = 0.002222222222222
	gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW -tr 247.37664620727463 -247.37664620727463 $< $@

tiny: mixed-terrain-tiny.tif mixed-hillshade-tiny.tif mixed-slopeshade-tiny.tif

%-tiny.tif: %-small.tif
	rm -f $@
# 8 times less resolute than -small (64 times the original)
# units/pixel= 1 deg/56.25 (64 arc sec) = 0.017777777777778
	gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW -tr 1979.013169658197 -1979.013169658197 $< $@

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

# define gdal-contour
# gdal_contour -i 10 -a height $< .
# shapeindex $(basename )
# endef

# define shp2pgsql
# shp2pgsql -c -I -g way $(basename $<) contours > $@
# endef

# $(master): $(height_files)
# 	gdal_merge.py -o $@ -v $^
#
# mixed_contour.sql: contour.shp
# 	$(shp2pgsql)
#
# contour.shp: $(master)
# 	$(gdal-contour)
#
# contour1000.shp: contour.shp
# 	ogr2ogr -f "ESRI Shapefile" -overwrite -where "height >0 and height % 1000 = 0" contour1000.shp contour.shp
#
# contour500.shp: contour.shp
# 	ogr2ogr -f "ESRI Shapefile" -overwrite -where "height >0 and height % 500 = 0 and height % 1000 != 0" contour500.shp contour.shp
#
# contour100.shp: contour.shp
# 	ogr2ogr -f "ESRI Shapefile" -overwrite -where "height >0 and height % 100 = 0 and height % 500 != 0 and height % 1000 != 0" contour100.shp contour.shp
#
# contour10.shp: contour.shp
# 	ogr2ogr -f "ESRI Shapefile" -overwrite -where "height >0 and height % 100 != 0 and height % 500 != 0 and height % 1000 != 0" contour10.shp contour.shp

# %.sql: %.shp
# 	$(shp2pgsql)
#
# %.shp: %.tif
# 	$(gdal-contour)
