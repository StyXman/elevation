#! /bin/bash

dst="$1.vrt"
dst_corrected="$1-corrected.vrt"
shift

gdalbuildvrt "$dst" "$@"
gdalwarp -t_srs "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 \
         +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over" \
         -r lanczos -tr 30.92208077590933 -30.92208077590933 \
         -of VRT "$dst" "$dst_corrected"

tile_size=$((2**14))

# TODO: use gdalinfo rd-corrected.vrt | grep '^Size' to calculate extents
for i in $(seq 0 5); do
    for j in $(seq 0 5); do
        for k in $(seq 0 3); do
            l=$((4 * $j + $k));
            # -eco to ignore
            gdal_translate -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZMA -co LZMA_PRESET=9 \
                -eco \
                -srcwin $(($tile_size * $i)) $(($tile_size * $l)) \
                    $(($tile_size + 1)) $(($tile_size + 1)) \
                -of GTiff "$dst_corrected" \
                $(printf "%03dx%03d-corrected.tif" $i $l) &
        done;
        wait;
    done;
done
