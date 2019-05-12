#! /bin/bash

if [ $# -eq 0 -o "$1" == "-h" -o "$1" == "--help" ]; then
    echo "$0 <region> <cols> <rows> file..."
    exit 0
fi

dst="$1.vrt"
dst_corrected="$1-corrected.vrt"
shift

# TODO: use gdalinfo rd-corrected.vrt | grep '^Size' to calculate extents
cols=$1
rows=$2
shift 2

gdalbuildvrt "$dst" "$@"
gdalwarp -t_srs "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 \
         +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over" \
         -r lanczos -tr 30.92208077590933 -30.92208077590933 \
         -of VRT "$dst" "$dst_corrected"

tile_size=$((2**14))

for i in $(seq 0 $cols); do
    for j in $( seq 0 $(($rows / 4)) ); do
        for k in $(seq 0 3); do
            l=$((4 * $j + $k));
            file="$(printf "%03dx%03d-corrected.tif" $i $l)"
            if ! [ -f "$file" ]; then
                # -eco to ignore
                gdal_translate -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZMA -co LZMA_PRESET=9 \
                    -eco \
                    -srcwin $(($tile_size * $i)) $(($tile_size * $l)) \
                        $(($tile_size + 1)) $(($tile_size + 1)) \
                    -of GTiff "$dst_corrected" "$file" &
            fi
        done;
        wait;
    done;
done

make -j 4 all_single
