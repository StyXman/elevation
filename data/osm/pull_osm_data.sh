#! /bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 EXTRACT [...]"
    echo
    echo -e "\tEXTRACT can be europe, europe/france or europe/france/provence-alps-cote-d-azur"
    echo -e "\tFor more info, go to http://download.geofabrik.de/"
    exit 1
fi

for i in $@; do
    wget --continue http://download.geofabrik.de/$i-latest.osm.pbf
done
