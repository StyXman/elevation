#! /bin/bash

set -eu

# TODO: generalize:
# cache
# procs
# path

db='gis'
bin='osm2pgsql'
# bin='/home/mdione/src/system/osm/osm2pgsql/build/osm2pgsql'

case "$1" in
  -d|--database)
    db="$2"
    shift 2
esac

osm_carto='../../osm-carto'

common_opts="--username $USER --database "$db" --cache 1024 --number-processes 4 --verbose \
    --slim --flat-nodes /home/mdione/src/projects/osm/nodes.cache --hstore \
    --multi-geometry --style $osm_carto/openstreetmap-carto.style --tag-transform-script $osm_carto/openstreetmap-carto.lua \
    --drop"

command=$1
shift

case "$command" in
  boot)
    sudo --user postgres createuser --superuser mdione
    sudo --user postgres psql -c "create tablespace hdd owner mdione location '/var/lib/data/postgresql';"
    ;;

  restart)
    sudo --user postgres dropdb --if-exists "$db"
    sudo --user postgres createdb --encoding UTF8 --owner $USER "$db"
    sudo --user postgres psql --dbname "$db" --command "CREATE EXTENSION postgis;"
    sudo --user postgres psql --dbname "$db" --command "CREATE EXTENSION hstore;"
    sudo --user postgres psql --dbname "$db" --command "ALTER TABLE geometry_columns OWNER TO $USER;"
    sudo --user postgres psql --dbname "$db" --command "ALTER TABLE spatial_ref_sys  OWNER TO $USER;"
    ;;

  import)
    opts="--create --unlogged"
    nice -n 19 $bin $opts $common_opts "$@"
    # psql --dbname "$db" --command "create index planet_osm_point_population_index on planet_osm_point (cast (population as int) desc nulls last);"
    ;;

  append)
    opts="--append"
    nice -n 19 $bin $opts $common_opts "$@"
    ;;

  *)
    echo "ERROR: wrong command $command"
    exit 1
esac
