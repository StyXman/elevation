#! /bin/bash

set -eu

# TODO: generalize:
# cache
# procs
# path

db='gis'

case "$1" in
  -d|--database)
    db="$2"
    shift 2
esac

common_opts="--username $USER --database "$db" --cache 4096 --number-processes 2 \
    --verbose --slim --flat-nodes /home/mdione/src/projects/osm/nodes.cache \
    --style import.style --drop --tablespace-slim-data index"

command=$1
shift

case "$command" in
  restart)
    sudo --user postgres dropdb --if-exists "$db"
    sudo --user postgres createdb --encoding UTF8 --owner $USER "$db"
    # sudo --user postgres createlang plpgsql "$db"
    sudo --user postgres psql --dbname "$db" --command "CREATE EXTENSION postgis;"
    # sudo --user postgres psql --dbname "$db" --command "CREATE EXTENSION hstore;"
    sudo --user postgres psql --dbname "$db" --command "ALTER TABLE geometry_columns OWNER TO $USER;"
    sudo --user postgres psql --dbname "$db" --command "ALTER TABLE spatial_ref_sys  OWNER TO $USER;"
    # sudo --user postgres psql --dbname "$db" --file /usr/share/osm2pgsql/900913.sql
    ;;

  import)
    opts="--create --unlogged"
    nice -n 19 osm2pgsql $opts $common_opts "$@"
    # psql --dbname "$db" --command "create index planet_osm_point_population_index on planet_osm_point (cast (population as int) desc nulls last);"
    ;;

  append)
    opts="--append"
    for file in $@; do
        nice -n 19 osm2pgsql $opts $common_opts $file
    done
    ;;

  *)
    echo "ERROR: wrong command $command"
    exit 1
esac
