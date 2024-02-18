#! /bin/bash

if [ -n "$DEBUG" ]; then
    export PS4='> $(date +"%Y-%m_dT%H:%M:%S") > $(basename "${BASH_SOURCE}") > ${FUNCNAME[0]:-__main__}():${LINENO} > '
    exec 5>> "$(basename $0).$$.log"
    BASH_XTRACEFD=5
    set -x
fi

set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 [-v] FILESPEC..."
    exit 1
fi

if [ "$1" == '-v' ]; then
    verb_opts='--bar --eta'
    shift
else
    verb_opts=''
fi

root=$(dirname $0)
children=$(cat /proc/cpuinfo | grep -E 'processor' | wc -l)

algo=lanczos

##
# original
parallel --jobs $children $verb_opts ${root}/process.sh terrain ::: "$@"
rm -f terrain.vrt
gdalbuildvrt terrain.vrt $(ls *-terrain.tif | grep -v "$algo")

compensated=( $(parallel --jobs $children $verb_opts ${root}/process.sh compensate ::: "$@") )

# apply to slope (not slopeshade) and hillshade processing
# the ratio of vertical units to horizontal

# if data is in WGS84 projection (standard latitude/longitude), h=1°
# 1° == 111120m at 0,0
# scale_option='-s 111120'
parallel --jobs $children $verb_opts ${root}/process.sh slopeshade   111120 ::: "${compensated[@]}"
rm -f slopeshade.vrt
gdalbuildvrt slopeshade.vrt $(ls *-slopeshade.tif | grep -v "$algo")

parallel --jobs $children $verb_opts ${root}/process.sh hillshade  0 111120 ::: "${compensated[@]}"
rm -f hillshade.vrt
gdalbuildvrt hillshade.vrt $(ls *-hillshade.tif | grep -v "$algo")


##
# reprojected
reprojected=( $(parallel --jobs $children $verb_opts ${root}/process.sh reproject "$algo" ::: "$@") )

parallel --jobs $children $verb_opts ${root}/process.sh terrain ::: "${reprojected[@]}"
rm -f "$algo"-terrain.vrt
gdalbuildvrt "$algo"-terrain.vrt *-"$algo"-terrain.tif

compensated=( $(parallel --jobs $children $verb_opts ${root}/process.sh compensate ::: "${reprojected[@]}") )

# if data is in WebMerc, h=1m
# scale_option='-s 1'
parallel --jobs $children $verb_opts ${root}/process.sh slopeshade   1 ::: "${compensated[@]}"
rm -f "$algo"-slopeshade.vrt
gdalbuildvrt "$algo"-slopeshade.vrt *-"$algo"-compensated-slopeshade.tif

parallel --jobs $children $verb_opts ${root}/process.sh hillshade  0 1 ::: "${compensated[@]}"
rm -f "$algo"-hillshade.vrt
gdalbuildvrt "$algo"-hillshade.vrt *-"$algo"-compensated-hillshade.tif

# parallel --jobs $children $verb_opts ${root}/process.sh contours ::: "${reprojected[@]}"

declare -A sizes
sizes=(
    [medium]=123.68832310363732
    [small]=247.37664620727463
    [tiny]=1979.013169658197
)

for style in '' "${algo}-"; do
    for size in medium small tiny; do
        for layer in terrain hillshade slopeshade; do
            # ERROR 1: Output dataset hillshade-small.tif exists,
            # but some command line options were provided indicating a new dataset
            # should be created.  Please delete existing dataset and run again.
            rm -f "${style}${layer}-${size}.tif"

            echo "${style}${layer}-${size}.tif"
            time gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW \
                -tr "${sizes[$size]}" -"${sizes[$size]}" "${style}${layer}.vrt" "${style}${layer}-${size}.tif"
        done

        wait
    done
done
