#! /bin/bash

set -e

region=$1

# Extent: (9.499995, 46.301027) - (17.212637, 49.067789)

extent_file="${region}/extent.txt"
ogrinfo -al -so ${region}/roads.shp | grep "Extent" > $extent_file
west=$(cat $extent_file | awk 'BEGIN { FS= "[\\(\\), ]" } { print $3 }')
south=$(cat $extent_file | awk 'BEGIN { FS= "[\\(\\), ]" } { print $5 }')
east=$(cat $extent_file | awk 'BEGIN { FS= "[\\(\\), ]" } { print $9 }')
north=$(cat $extent_file | awk 'BEGIN { FS= "[\\(\\), ]" } { print $11 }')

source ../../layers.sh

file=../../tilemill/project/osm-tilemill/input/highways.mml

rm -f $file

for highway in $highways; do
(
cat << EOS
    {
      "geometry": "linestring",
      "extent": [
        $west,
        $south,
        $east,
        $north
      ],
      "Datasource": {
        "type": "postgis",
        "table": "(select * from planet_osm_roads where highway='$highway') as foo",
        "key_field": "",
        "geometry_field": "",
        "extent_cache": "auto",
        "extent": "368945.35,5243076.72,974136.32,5652196.58",
        "host": "localhost",
        "user": "postgres",
        "dbname": "osm"
      },
      "id": "$highway",
      "class": "roads",
      "srs-name": "900913",
      "srs": "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over",
      "advanced": {},
      "name": "roads"
    },
EOS
) >> $file
done
