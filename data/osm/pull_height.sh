#! /bin/bash

set -e







pbf_file=$1
extent=$(osmpbf-outline $pbf_file | grep bbox)

#     bbox: 9.5267800,46.3685100,17.1627300,49.0240300
west=$(echo $extent | awk 'BEGIN { FS= "[ ,\\.]+" } { print $2 }')
south=$(echo $extent | awk 'BEGIN { FS= "[ ,\\.]+" } { print $4 }')
east=$(echo $extent | awk 'BEGIN { FS= "[ ,\\.]+" } { print $6 }')
north=$(echo $extent | awk 'BEGIN { FS= "[ ,\\.]+" } { print $8 }')


echo $west, $south, $east, $north

declare -a mins maxs patterns

# -17, 32, -6, 42
if [ ${east:0:1} == "-" -a ${west:0:1} == "-" ]; then
    # reorder them for seq
    # -17 -6 -> 6 17
    mins=([0]="${east:1}")
    maxs=([0]="${west:1}")
    patterns=([0]="N\${lat}W\${long}")
    seqs=1

# -2, 42, 1, 45
elif [ ${west:0:1} == "-" ]; then
    # -2 1 -> 1 2 0 1
    mins=([0]="1" [1]="0")
    maxs=([0]="$(( ${west:1} + 1 ))" [1]="${east}")
    patterns=([0]="N\${lat}W\${long}" [1]="N\${lat}E\${long}")
    seqs=2

else
    mins=([0]="${west}")
    maxs=([0]="${east}")
    patterns=([0]="N\${lat}E\${long}")
    seqs=1
fi

cd ../height

for s in $( seq 0 $((seqs-1)) ); do
    min=${mins[$s]}
    max=${maxs[$s]}
    pattern=${patterns[$s]}

    for i in $(seq $min $max); do
        long=$(printf "%03d" $i)

        for j in $(seq $south $north); do
            lat=$(printf "%02d" $j)









            zip_file=$(eval "echo ${pattern}.hgt.zip")

            if ! [ -f $(eval "echo ${pattern}.hgt") ]; then

                echo "Getting $(eval "echo ${pattern}.hgt")"
                # http://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Eurasia/N00E072.hgt.zip
                url="http://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Eurasia/$zip_file"
                wget $WGET_OPTS $url || true




                if [ -f $zip_file ]; then
                    echo "Got $zip_file"
                    ( set +e; unzip -u $zip_file; rm $zip_file ) &
                fi

                sleep 1
            fi
        done
    done
done
