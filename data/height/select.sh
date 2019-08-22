#! /bin/bash

set -eu

name=$1

make $(for layer in hillshade terrain slopeshade; do
    for size in medium small; do
        echo $name-$layer-$size.tif
    done
done)

for layer in hillshade terrain slopeshade; do
    ln -sfv $name-$layer.vrt mixed-$layer.vrt
    for size in medium small; do
        ln -sfv $name-$layer-$size.tif mixed-$layer-$size.tif
    done
done
