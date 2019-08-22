#! /bin/bash

set -eu

if ! [ -s Elevation.xml ]; then
    # a previous run mangled the file
    rm -f Elevation.xml
fi

make Elevation.xml
# git commit fails if there's nothing to commit
git commit Elevation.xml -m "[*] $(date --iso-8601=seconds)." &> /dev/null || true

PYTHON="python3 -s"
# PYTHON="LD_LIBRARY_PATH=$HOME/local/lib pyhton3"

nice -n 19 $PYTHON ./generate_tiles.py \
    --input-file Elevation.xml \
    --output-dir Elevation \
    --metatile-size 8 --empty-color '#aad3df' \
    --log-file render.log "$@"
