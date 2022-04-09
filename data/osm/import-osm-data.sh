#! /bin/bash

set -eu

# TODO: generalize:
# cache
# procs
# path

function usage() {
    exit_code=${1:-0}

    echo "Usage: $0 [-h|--help] [-d|--database DB] [-p|--port PORT] [boot|restart|import PBF ARGS...|append PBF ARGS...|drop]"
    echo
    echo "boot creates a super user '$USER'. needs sudo."
    echo "restart (re)recreates the database from scratch. WARNING: it removes previous data."
    echo "import and append import new data. ARGS are passed directly to osm2pgsql."
    echo "drop deletes the whole database."
    echo "DB is by default 'gis', and PORT is postgres' port, usually 5432."
    echo
    echo "WARNING: -d|--database must be provided BEFORE the command, and MUST be provided for restart."

    exit $exit_code
}

if [ $# -eq 0 ]; then
    usage
fi

# defaults
db='gis'
db_provided=false
port=5432
bin='osm2pgsql'
# bin='/home/mdione/src/system/osm/osm2pgsql/build/osm2pgsql'

while [ $# -gt 0 ]; do
    case "$1" in
      -d|--database)
        db="$2"
        db_provided=true
        shift 2
      ;;

      -p|--port)
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

if [ $# -eq 0 ]; then
    usage 1
fi

osm_carto="$(realpath $(pwd)/../../osm-carto)"

common_opts="--username $USER --port $port --database "$db" --cache 0 --number-processes 16 --verbose \
    --slim --flat-nodes $(pwd)/nodes.cache --hstore \
    --multi-geometry --style $osm_carto/openstreetmap-carto.style --tag-transform-script $osm_carto/openstreetmap-carto.lua \
    --drop"

command=$1
shift

case "$command" in
  boot)
    if [ $# -gt 0 ]; then
        usage 1
    fi

    sudo --user postgres createuser --port $port --superuser $USER
    # sudo --user postgres psql -c "create tablespace hdd owner mdione location '/var/lib/data/postgresql';"
    ;;

  restart)
    if [ $# -gt 0 ]; then
        usage 1
    fi

    if [ $db_provided == false ]; then
        usage 1
    fi

    sudo --user postgres dropdb --port $port --if-exists "$db"
    sudo --user postgres createdb --port $port --encoding UTF8 --owner $USER "$db"
    sudo --user postgres psql --port $port --dbname "$db" --command "CREATE EXTENSION postgis;"
    sudo --user postgres psql --port $port --dbname "$db" --command "CREATE EXTENSION hstore;"
    sudo --user postgres psql --port $port --dbname "$db" --command "ALTER TABLE geometry_columns OWNER TO $USER;"
    sudo --user postgres psql --port $port --dbname "$db" --command "ALTER TABLE spatial_ref_sys  OWNER TO $USER;"
    ;;

  import)
    # opts="--create --unlogged"
    # unlogged was removed in https://github.com/openstreetmap/osm2pgsql/issues/940
    opts="--create"
    nice -n 19 $bin $opts $common_opts "$@"
    time psql --port $port --dbname "$db" --file ../../osm-carto/indexes.sql
    ;;

  append)
    opts="--append"
    nice -n 19 $bin $opts $common_opts "$@"
    ;;

  drop)
    sudo --user postgres dropdb --port $port --if-exists "$db"
    ;;

  *)
    echo "ERROR: wrong command $command"
    exit 1
esac
