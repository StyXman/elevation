#! /bin/bash

set -o errexit -o nounset

if [ $# -ne 2 ]; then
    echo "Usage: $0 EXTRACT DST"
    echo
    echo -e "\tEXTRACT can be in the form of europe, europe/france or europe/france/provence-alps-cote-d-azur"
    echo -e "\tDST is the destination directory"
    echo -e "\tFor more info, go to http://download.geofabrik.de/"
    exit 1
fi

extract=$1
dst=$2

path="${extract}-latest.osm.pbf"
file="$dst/$(basename $path)"

mkdir -pv $dst

if [ -f $file ]; then
    time_cond="--time-cond $file"
else
    time_cond=""
fi
# $time_cond
curl --location --output $file --continue - --verbose http://download.geofabrik.de/$path
