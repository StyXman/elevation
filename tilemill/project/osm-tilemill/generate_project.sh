#! /bin/bash

set -e

(
cd input
echo '{'
cat project.mml
echo '  "Layer": ['

cat relief.mml
cat contour.mml

cat highways.mml

# cat boundaries.mml

echo '  ],'
cat epilogue.mml

echo '}'
) > project.mml
