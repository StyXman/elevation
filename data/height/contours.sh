#! /bin/bash

set -eu

if [ $# -eq 0 ]; then
    echo "Usage: $0 FILE"
    echo
    echo "Converts DEM fil into countour lines in SQL format."
    exit 0
fi

input="$1"
shape_dir="$(basename "$input").shp"

mkdir -pv "$shape_dir"
gdal_contour -i 10 -a height "$input" "$shape_dir"
shp2pgsql -c -I -g way "${shape_dir}/contour" contours | sed -e '/CREATE TABLE/d; /"id" int4/d; /"height" numeric/d; /ALTER TABLE/d; /SELECT AddGeometryColumn/d'
rm -rfv "$shape_dir"
