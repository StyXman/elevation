#! /bin/bash

if [ -n "$DEBUG" ]; then
    export PS4='> $(date +"%Y-%m_dT%H:%M:%S") > $(basename "${BASH_SOURCE}") > ${FUNCNAME[0]:-__main__}():${LINENO} > '
    exec 5>> "$(basename $0).$$.log"
    BASH_XTRACEFD=5
    set -x
fi

set -euo pipefail

base_dir=$(dirname $0)

# options used everywhere
# gopts='-co BIGTIFF=YES'
gopts=''

shade_opts='-compute_edges'

# options used in final files because of
# Cannot open TIFF file due to missing codec
# see: https://gis.stackexchange.com/questions/72463/qgis-2-0-cannot-open-tiff
# -co TILED=YES -co COMPRESS=LZMA -co LZMA_PRESET=9
final_gopts='-co BIGTIFF=YES  -co TILED=YES  -co COMPRESS=LZW'

# gdal_calc has --long-opts instead of -long-opts, so....
final_gopts2='--co BIGTIFF=YES --co TILED=YES --co COMPRESS=LZW'

WebMerc='EPSG:3857'
m_per_pixel='30.92208077590933'

function add_suffix {
    orig=$1
    suffix=$2
    extra=$3
    ext=${4:-tif}

    filename=${orig%.*}  # remove .*
    # len=$(( ${#filename} + 1 ))
    # ext=${orig:$len}  # ext

    # echo "${filename}-${suffix}.${ext}"
    if [ "$extra" == '' ]; then
        echo "${filename}-${suffix}.${ext}"
    else
        echo "${filename}-${suffix}-${extra}.${ext}"
    fi
}

#  -r <resampling_method>
#     Resampling method to use. Available methods are:
#     near: nearest neighbour resampling (default, fastest algorithm, worst interpolation quality).
#     bilinear: bilinear resampling.
#     cubic: cubic resampling.
#     cubicspline: cubic spline resampling.
#     lanczos: Lanczos windowed sinc resampling.
function reproject {
    src=$1
    algo=$2
    suffix=$3
    dst=$(add_suffix $src "$algo" "$suffix")

    if [ -f $dst ]; then
        echo "$dst"
        return 0
    fi

    # ERROR 1: Output dataset N67E017-reprojected.tif exists,
    # but some command line options were provided indicating a new dataset
    # should be created.  Please delete existing dataset and run again.
    rm -f $dst

    gdalwarp $gopts -t_srs ${WebMerc} -r "$algo" -tr ${m_per_pixel} -${m_per_pixel} $src $dst >&2
    echo "$dst"
}

function terrain {
    src=$1
    suffix=$2
    dst=$(add_suffix $src 'terrain' "$suffix")

    if [ -f $dst ]; then
        return 0
    fi

    gdaldem color-relief -alpha ${gopts} $src color-relief.txt /vsistdout/ | \
        gdal_translate ${final_gopts} -b 1 -b 2 -b 3 /vsistdin/ $dst

    echo "Wrote $dst"
    echo
}

function compensate {
    src=$1
    suffix=$2
    dst=$(add_suffix $src 'compensated' "$suffix")

    if [ -f $dst ]; then
        echo "$dst"
        return 0
    fi

    $base_dir/compensate.py $src $dst

    # echo "Wrote $dst"
    # echo
    echo "$dst"
}

function hillshade {
    src=$1
    multi=$2
    scale=$3
    suffix=$4

    if [ $multi -eq 0 ]; then
        dst=$(add_suffix $src 'hillshade' "$suffix")
        if [ -f $dst ]; then
            return 0
        fi

        gdaldem hillshade -alg Horn -s ${scale} ${shade_opts} ${final_gopts} $src $dst
    else
        dst=$(add_suffix $src 'hillshade-multi' "$suffix")
        if [ -f $dst ]; then
            return 0
        fi

        # gdaldem hillshade -alg Horn -multidirectional -s ${scale} ${shade_opts} ${final_gopts} $src $dst
        gdaldem hillshade -alg Horn -multidirectional ${shade_opts} ${final_gopts} $src $dst
    fi

    echo "Wrote $dst"
    echo
}

function combined {
    src=$1
    scale=$2
    suffix=$3
    dst=$(add_suffix $src 'combined' "$suffix")

    gdaldem hillshade -combined -alg Horn -s ${scale} ${shade_opts} ${final_gopts} $src $dst

    echo "Wrote $dst"
    echo
}

function slopeshade {
    src=$1
    scale=$2
    suffix=$3
    # mid=$(add_suffix $src 'slope' "$suffix")
    dst=$(add_suffix $src 'slopeshade' "$suffix")

    if [ -f $dst ]; then
        return 0
    fi

    # gdaldem slope -alg Horn -s ${scale} ${shade_opts} ${gopts} $src $mid
    gdaldem slope -alg Horn ${shade_opts} ${gopts} $src /vsistdout/ | \
        gdaldem color-relief ${gopts} /vsistdin/ slope.txt /vsistdout/ | \
        gdal_translate ${final_gopts} -b 1 /vsistdin/ $dst
    gdal_edit.py -colorinterp_1 gray $dst

    echo "Wrote $dst"
    echo
}

function flatten {
    # replaced by a proper slope.txt contents
    exit 1

    src=$1
    mid=$(add_suffix $src 'tmp')
    dst=$(add_suffix $src 'flattened')

    # A>20 return 0 if false
    # all orig values are 0-255, so the new values are 0-235; 255 is a safe no data value
    # gdal_calc does not overwrite some params if the file exists, so remove the target if needed
    # gdal_calc.py -A $src --outfile $mid --calc '(A>20)*(A-20)' --NoDataValue=255 \
    #     --overwrite ${final_gopts2}

    # another take. 20 is <0.08 of 255; scale down by 0.92 and add 20.
    # In [1]: 254*.92+20
    # Out[1]: 253.68
    # gdal_calc.py -A $src --outfile $mid --calc '(A*0.92)+20' --NoDataValue=255 \
    #         --overwrite ${final_gopts2}

    gdal_calc.py -A $src --outfile $mid --calc 'A*0.92' --NoDataValue=255 \
        --overwrite ${final_gopts2}

    gdal_translate ${final_gopts} -b 1 $mid $dst
    gdal_edit.py -colorinterp_1 gray $dst

    echo "Wrote $dst"
    echo
}

function buildvirt {
    # disabled
    exit 1

    suffix=$1
    dst="${suffix}.vrt"

    # gdalbuildvrt does not seem to overwrite the file, so
    rm -f $dst

    gdalbuildvrt $dst ???????-${suffix}.tif

    echo "Wrote $dst"
}

function contours {
    src=$1
    suffix=$2
    dst=$(add_suffix $src 'contours' "$suffix" 'sql.xz')

    if [ -f $dst ]; then
        return 0
    fi

    $base_dir/contours.sh $src | xz -9 > $dst

    echo "Wrote $dst"
    echo
}

function usage() {
    echo "$0 reproject  [-s suffix]        algo file...    converts to WebMerc"
    echo "$0 terrain    [-s suffix]             file...    builds terrain files"
    echo "$0 compensate [-s suffix]             file...    compensates DEM based on latitude"
    echo "$0 slopeshade [-s suffix]       scale file...    builds slopeshade files"
    echo "$0 hillshade  [-s suffix] multi scale file...    builds hillshade files, multidirectional or not"
    echo "$0 contours   [-s suffix]             file...    builds contour sql files"
    # echo "$0 combined   [-s suffix] multi scale file...    builds combined hill+slope shade files, multidirectional hillshade or not"
    # echo "$0 buildvrt|buildvirt|vrt [ suffix |  file... ]  build vrt file"
    # echo "$0 flatten file...                 flattens file to .92 scale for non-white valleys"

    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

what=$1
shift

if [ "$1" == '-s' ]; then
    suffix=$2
    shift 2
else
    suffix=''
fi

case $what in
  reproject)
    algo=$1
    shift
  ;;

  terrain|compensate|contours)
    # nothing
  ;;

  hillshade|combined)
    multi=$1
    scale=$2
    shift 2
  ;;

  slopeshade)
    scale=$1
    shift
  ;;

  # buildvrt|buildvirt|vrt)
  #   buildvirt $@
  #   exit $?
  # ;;
  *)
    echo "Unknown action '$what'"
    echo
    usage
  ;;
esac

for src in $@; do
    if [ -z "${scale:-}" -a -z "${algo:-}" ]; then
        $what $src "$suffix"
    else
        if [ -n "${algo:-}" ]; then
            $what $src $algo "$suffix"
        else
            if [ -z "${multi:-}" ]; then
                $what $src $scale "$suffix"
            else
                $what $src $multi $scale "$suffix"
            fi
        fi
    fi
done
