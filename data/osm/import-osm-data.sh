#! /bin/bash

set -eu

# TODO: generalize:
# cache
# procs
# path

function usage() {
    echo "Usage: $0 [-h|--help] [-d|--database DB] [-p|--port PORT] [boot|restart|import PBF ARGS...|append PBF ARGS...]"
    echo
    echo "boot creates a super user '$USER'. needs sudo."
    echo "restart (re)recreates the database from scratch. WARNING: it removes previous data."
    echo "import and append import new data. ARGS are passed directly to osm2pgsql."
    echo "DB is by dfault 'gis', and PORT is postgres' port, usually 5432."
    echo
    echo "WARNING: -d|--database must be provided BEFORE the command."
    exit 0
}

if [ $# -eq 0 ]; then
    usage
fi

db='gis'
port=5432
bin='osm2pgsql'
# bin='/home/mdione/src/system/osm/osm2pgsql/build/osm2pgsql'

while true; do
    case "$1" in
      -d|--database)
        db="$2"
        shift 2
      ;;

      --p|-port)
        port="$2"
        shift 2
      ;;

      -h|--help)
        usage
      ;;

      *)
        break
      ;;
    esac
done

osm_carto='../../osm-carto'

common_opts="--username $USER --port $port --database "$db" --cache 0 --number-processes 4 --verbose \
    --slim --flat-nodes /home/mdione/src/projects/osm/nodes.cache --hstore \
    --multi-geometry --style $osm_carto/openstreetmap-carto.style --tag-transform-script $osm_carto/openstreetmap-carto.lua \
    --drop"

command=$1
shift

case "$command" in
  boot)
    sudo --user postgres --port $port createuser --superuser $USER
    # sudo --user postgres psql -c "create tablespace hdd owner mdione location '/var/lib/data/postgresql';"
    ;;

  restart)
    sudo --user postgres dropdb --port $port --if-exists "$db"
    sudo --user postgres createdb --port $port --encoding UTF8 --owner $USER "$db"
    sudo --user postgres psql --port $port --dbname "$db" --command "CREATE EXTENSION postgis;"
    sudo --user postgres psql --port $port --dbname "$db" --command "CREATE EXTENSION hstore;"
    sudo --user postgres psql --port $port --dbname "$db" --command "ALTER TABLE geometry_columns OWNER TO $USER;"
    sudo --user postgres psql --port $port --dbname "$db" --command "ALTER TABLE spatial_ref_sys  OWNER TO $USER;"
    ;;

  import)
    # opts="--create --unlogged"
    # unlogged is not recognized anymore, is there an option?
    opts="--create"
    nice -n 19 $bin $opts $common_opts "$@"
    time psql --port $port --dbname "$db" --file ../../osm-carto/indexes.sql
    ;;

  append)
    opts="--append"
    nice -n 19 $bin $opts $common_opts "$@"
    ;;

  *)
    echo "ERROR: wrong command $command"
    exit 1
esac
