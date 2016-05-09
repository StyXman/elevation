#! /bin/bash

set -o errexit -o nounset

# a lot of files are quite big, and
# in my setup the main dir is in a partition in a small SSD big enough for the DB
# but not much more
# so all these big data files are stored in anothere directory
data_dir=$1

extract=$2

make prepare DATA_DIR=$data_dir

# as the data_dir is outside this repo, we can't have a Makefile there
# so we do this as indempotent as possible
(
    cd data/osm
    dst="$data_dir/data/osm"
    ./pull_osm_data.ay $extract $dst
    ln -sfv "$dst/$(basename ${extract}-latest.osm.pbf)" .
)
