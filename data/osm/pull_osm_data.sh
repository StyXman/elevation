#! /bin/bash

set -o errexit -o nounset

if [ $# -eq 0 ]; then
    echo "Usage: $0 EXTRACT [...]"
    echo
    echo -e "\tEXTRACT can be in the form of europe, europe/france or europe/france/provence-alps-cote-d-azur"
    echo -e "\tFor more info, go to http://download.geofabrik.de/"
    exit 1
fi

for extract in $@; do
    path="$extract-latest.osm.pbf"
    file=$(basename $path)

    if [ -f $file ]; then
        time_cond="--time-cond $file"
    else
        time_cond=""
    fi
    curl $time_cond --location --output $file http://download.geofabrik.de/$path
done
