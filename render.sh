#! /bin/bash

set -eu

git checkout render
make Elevation.xml
# git commit fails if there's nothing to commit
git commit Elevation.xml -m "[*] $(date --iso-8601=seconds)." &> /dev/null || true

./generate_tiles.py --input-file Elevation.xml --output-dir Elevation \
    --metatile-size 8 "$@" || true  # I hope this handles C-c

git checkout master
