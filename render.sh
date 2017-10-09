#! /bin/bash

set -eu

make Elevation.xml
# git commit fails if there's nothing to commit
git commit Elevation.xml -m "[*] $(date --iso-8601=seconds)." &> /dev/null || true

nice -n 19 python3.6 -s ./generate_tiles.py \
    --input-file Elevation.xml \
    --output-dir Elevation \
    --metatile-size 8 --log-file render.log "$@"
