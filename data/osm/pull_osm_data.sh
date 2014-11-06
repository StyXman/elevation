#! /bin/bash

for i in $@; do
    wget --continue http://download.geofabrik.de/$i-latest.osm.pbf
done
