#! /bin/bash

set -eu

common_opts="--username mdione --database gis --cache 2048 --number-processes 4 \
    --verbose --slim --flat-nodes /home/mdione/src/projects/osm/nodes.cache \
    --style import.style"

command=$1
shift

case "$command" in
  restart)
    sudo -u postgres dropdb gis
    sudo -u postgres createdb -E UTF8 -O mdione gis
    # sudo -u postgres createlang plpgsql gis
    sudo -u postgres psql -d gis -c "CREATE EXTENSION postgis;"
    # sudo -u postgres psql -d gis -c "CREATE EXTENSION hstore;"
    sudo -u postgres psql -d gis -c "ALTER TABLE geometry_columns OWNER TO mdione;"
    sudo -u postgres psql -d gis -c "ALTER TABLE spatial_ref_sys  OWNER TO mdione;"
    # sudo -u postgres psql -d gis -f /usr/share/osm2pgsql/900913.sql
    ;&

  import)
    opts="--create --unlogged"
    nice -n 19 osm2pgsql $opts $common_opts $2
    psql -d gis -c "create index planet_osm_point_populaiton_index on planet_osm_point (cast (population as int) desc nulls last);"
    ;;

  append)
    opts="--append"
    for file in $@; do
        nice -n 19 osm2pgsql $opts $common_opts $file
    done
    ;;

  *)
    echo "ERROR: wrong ocmmand $command"
    exit 1
esac
