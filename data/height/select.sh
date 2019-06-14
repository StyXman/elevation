#! /bin/bash

set -eu

for layer in hillshade terrain slopeshade; do
    ln -sfv $1-$layer.vrt mixed-$layer.vrt
    for size in medium small; do
        ln -sfv $1-$layer-$size.tif mixed-$layer-$size.tif
    done
done
