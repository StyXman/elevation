# kate: replace-tabs: off; indent-width 8

# data/height/Make

# for the main directory
all:
	make -C datafiles -j 4 all_single
	make main

# this Makefile is multipurpose, to be used at the root of the height data dir
# (data/height) and on each provider's dir

# but minor goals first
prepare:


#############
# FIRST GOAL
# the first goal is to processes the original DEM files and produce 3 or 4 files:
# * an optional corrected version, for those DEMs that are not in the proper scale.
# * final terrain, slopeshade and hillshade versions.
# this is used on the provider's dirs

# height_files = $(wildcard *-reprojected.tif)
height_files =      $(wildcard *.hgt)
reprojected_files = $(wildcard *-reprojected.tif)
terrain_files =     $(foreach height_file,$(reprojected_files),$(subst .tif,-terrain.tif,$(height_file)))
compensated_files = $(foreach height_file,$(reprojected_files),$(subst .tif,-compensated.tif,$(height_file)))
slope_files =       $(foreach height_file,$(compensated_files),$(subst .tif,-slopeshade.tif,$(height_file)))
hill_files =        $(foreach height_file,$(compensated_files),$(subst .tif,-hillshade.tif,$(height_file)))
contour_files =     $(foreach height_file,$(height_files),$(subst -reprojected.tif,-contour.sql.xz,$(height_file)))

all_files = $(sort $(terrain_files) $(hill_files) $(slope_files))
sql_files = $(sort $(contour_files))

echo:
	@echo -n 'height: '
	@echo $(height_files)
	@echo -n 'reprojected: '
	@echo $(reprojected_files)
	@echo -n 'terraint: '
	@echo $(terrain_files)
	@echo -n 'compensated: '
	@echo $(compensated_files)
	@echo -n 'slopeshade: '
	@echo $(slope_files)
	@echo -n 'hillshade: '
	@echo $(hill_files)
	@echo -n 'contour: '
	@echo $(contour_files)
	@echo -n 'all: '
	@echo $(all_files)

# do not remove these intermediate files
.SECONDARY: $(corrected_files)
.SECONDARY: $(slope_orig_files)

# but removed failed ones
# .DELETE_ON_ERROR:

all_single: $(all_files)

sql_single: $(sql_files)

# unit is degree (2 * math.pi / 360)
# units/pixel= 1 deg/3600 (1 arc sec) = 0.000277777777778
#          +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs
# WebMerc = "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over"
WebMerc = EPSG:3857
m_per_pixel=30.92208077590933

<<<<<<< Updated upstream
%-corrected.tif: %.vrt
	gdalwarp $(gopts) -t_srs $(WebMerc) -r lanczos -tr $(m_per_pixel) -$(m_per_pixel) \
	    $< $@;

%-corrected.tif: %.hgt
	gdalwarp $(gopts) -t_srs $(WebMerc) -r lanczos -tr $(m_per_pixel) -$(m_per_pixel) \
	    $< $@;

%-corrected.tif: %.tif
	gdalwarp $(gopts) -t_srs $(WebMerc) -r lanczos -tr $(m_per_pixel) -$(m_per_pixel) \
	    $< $@;

%-terrain.tif: %-corrected.tif color-relief.txt
	gdaldem color-relief -alpha $(gopts) $< color-relief.txt /vsistdout/ | \
	    gdal_translate $(final_gopts) -b 1 -b 2 -b 3 /vsistdin/ $@
=======
# S33W066.hgt
# S33W066-reprojected.tif
# S33W066-reprojected-terrain.tif
# S33W066-reprojected-compensated.tif
# S33W066-reprojected-compensated-hillshade.tif
# S33W066-reprojected-compensated-slopeshade.tif
# S33W066-reprojected-contours.sql.xz

>>>>>>> Stashed changes

# I keep changing these because sources keep changing
# %-reprojected.tif: %.tif
%-reprojected.tif: %.hgt
	../process.sh reproject $<;

%-reprojected-terrain.tif: %-reprojected.tif color-relief.txt
	../process.sh terrain $<

%-reprojected-compensated.tif: %-reprojected.tif
	../process.sh compensate $<

%-reprojected-compensated-slopeshade.tif: %-reprojected-compensated.tif slope.txt
	../process.sh slopeshade 1 $<

%-reprojected-compensated-hillshade.tif: %-reprojected-compensated.tif
	../process.sh hillshade 0 1 $<

%-combined.tif: %-compensated.tif
	gdaldem hillshade -combined -alg Horn $(scale_option) -compute_edges $(final_gopts) \
	    $< $@

# A>20 return 0 if false
# all orig values are 0-255, so the new values are 0-235; 255 is a safe no data value
# gdal_calc does not overwrite some params if the file exists, so remove the target if needed
# %-slopeshade.tif: %-slopeshade.orig.tif
# 	gdal_calc.py -A $< --outfile $@ --calc '(A>20)*(A-20)' --NoDataValue=255 \
# 		--overwrite $(final_gopts2)

# another take. 20 is <0.08 of 255; scale down by 0.92 and add 20.
# In [1]: 254*.92+20
# Out[1]: 253.68
# %-slopeshade.tif: %-slopeshade.orig.tif
# 	gdal_calc.py -A $< --outfile $@ --calc '(A*0.98)+20' --NoDataValue=255 \
# 		--overwrite $(final_gopts2)

# TODO:
# 	gdal_translate $(final_gopts) -b 1 /vsistdin/ $@
# 	gdal_edit.py -colorinterp_1 gray $@

<<<<<<< Updated upstream
# files for blender
%-blender.tif: %.hgt
	gdal_calc.py -A $< --outfile $@ --calc 'A*8' --NoDataValue=255 --overwrite $(final_gopts2);

# %-contour.sql.xz: %-corrected.tif
# 	./contours.sh $< | xz -9 > $@

%-contour.sql.xz: %-contour.sql
	xz -9 $<

%-contour.sql: %-corrected.tif
	mkdir -pv $(basename $<).shp
	gdal_contour -i 10 -a height $< $(basename $<).shp
	shp2pgsql -c -I -g way $(basename $<).shp/contour contours > $@
	rm -rfv $(basename $<).shp
=======
%-reprojected-contours.sql.xz: %-reprojected.tif
	../process.sh contours $<
# 	./contours.sh $< | xz -9 > $@
# 	./contours.sh $< | psql contours
>>>>>>> Stashed changes

terrain.vrt: *-terrain.tif
	# gdalbuildvrt $@

color-relief.txt slope.txt:
	ln -sfv ../$@ ./

##############
# SECOND GOAL
# the second goal is to combine these versions in three .vrt files,
# so it can be used directly by the rendering engine
# and also a small version so it can be used for rendering low zoom levels
# (currently 7 and below)

# iterate first over the suffixes, then the datafiles
# so .vrt are built first and small later
# (but that should be resolved by the deps anyways)
main_files = $(foreach suf,.vrt -medium.tif -small.tif,\
                     $(foreach datafile,terrain slopeshade hillshade,\
		               $(addsuffix $(suf),$(datafile))))

main: $(main_files)

%-medium.tif: %.vrt
	rm -f $@
# 4 times less resolute than the original
# units/pixel= 1 deg/900 (4 arc sec) = 0.001111111111111
	gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW \
	    -tr 123.68832310363732 -123.68832310363732 $< $@

%-small.tif: %.vrt
	rm -f $@
# 8 times less resolute than the original
# units/pixel= 1 deg/450 (8 arc sec) = 0.002222222222222
	gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW \
	    -tr 247.37664620727463 -247.37664620727463 $< $@

tiny: mixed-terrain-tiny.tif mixed-hillshade-tiny.tif mixed-slopeshade-tiny.tif

%-tiny.tif: %-small.tif
	rm -f $@
# 8 times less resolute than -small (64 times the original)
# units/pixel= 1 deg/56.25 (64 arc sec) = 0.017777777777778
	gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW \
	    -tr 1979.013169658197 -1979.013169658197 $< $@



# blender
# TODO: rescale to (X - min) / (max - min) * 65536

# convert to UInt16
# gdal_translate -ot UInt16 -of GTiff /home/mdione/tmp/foo.tiff /home/mdione/tmp/bar.tif
