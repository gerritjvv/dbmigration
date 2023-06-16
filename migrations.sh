#!/bin/bash

dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

MIGRATIONS_DIR=${MIGRATIONS_DIR:-"migrations"}

if [ -f ".env" ]; then
  source .env
fi

mkdir -p "${MIGRATIONS_DIR}/upgrades"
mkdir -p "${MIGRATIONS_DIR}/downgrades"
mkdir -p "${MIGRATIONS_DIR}/fixtures"

CMD="$1"
shift

case $CMD in

configure)

  read -rp 'DB HOST: ' DB_HOST
  echo ""
  read -rp 'DB PORT: (5432)' DB_PORT
  echo ""
  read -rsp 'DB DB PASSWORD: ' DB_PASSWORD
  echo ""
  read -rp 'DB NAME: ' DB_NAME
  echo ""
  read -rp "MIGRATIONS_DIR: ($dir)" MIGRATIONS_DIR,
  echo ""

  if [ -z "${DB_PORT}" ]; then
    DB_PORT="5432"
  fi

  echo "DB_HOST=${DB_HOST}" >>.env
  echo "DB_PORT=${DB_PORT}" >>.env
  echo "DB_PASSWORD=${DB_PASSWORD}" >>.env
  echo "DB_NAME=${DB_NAME}" >>.env
  echo "MIGRATIONS_DIR=${MIGRATIONS_DIR}" >>.env

  echo "Wrote configuration values to .env"
  ;;
run)
  export PGHOST="${DB_HOST:-localhost}"
  export PGUSER="${DB_USER:-postgres}"
  export PGPASSWORD="${DB_PASSWORD:-password}"
  export PGDATABASE="${DB_NAME:-postgres}"

  find "${MIGRATIONS_DIR}/upgrades" -type f -iname "*.sql" | sort | xargs -n 1 psql -f
  find "${MIGRATIONS_DIR}/fixtures" -type f -iname "*.sql" | sort | xargs -n 1 psql -f

  ;;

downgrade-all)
  export PGHOST="${DB_HOST:-localhost}"
  export PGUSER="${DB_USER:-postgres}"
  export PGPASSWORD="${DB_PASSWORD:-password}"
  export PGDATABASE="${DB_NAME:-postgres}"

  find "${MIGRATIONS_DIR}/downgrades" -type f -iname "*.sql" | sort -r | xargs -n 1 psql -f
  ;;
create)
  name=$1
  if [ -z "$name" ]; then
    read -rp 'Migration name? (migration): ' name
    echo ""
  fi

  if [ -z "${name}" ]; then
    name="migration"
  fi

  ts=$(date +%s)
  file="${MIGRATIONS_DIR}/upgrades/${ts}_${name}.sql"
  echo "Creating empty upgrade file $file"
  touch "$file"

  cat >>"${file}" <<EOL
CREATE SCHEMA IF NOT EXISTS public;

CREATE TABLE IF NOT EXISTS public.migration (
    id text PRIMARY KEY
);

-- insert commands before this line
INSERT INTO public.migration (id) VALUES('${ts}_${name}.sql') ON CONFLICT DO NOTHING;
EOL

  file2="${MIGRATIONS_DIR}/downgrades/${ts}_${name}.sql"
  echo "Creating empty downgrade file $file2"
  touch "$file2"
  echo "-- insert commands before this line" >"$file2"
  echo "DELETE FROM public.migration WHERE id='${ts}_${name}.sql';" >>"$file2"
  ;;

lint)
  if ! command -v pip &>null; then
    echo "Python and Pip are required to run this command"
    echo "Please visit https://pip.pypa.io/en/stable/installation/"
    exit 1
  fi

  pip install sqlfluff
  DB_DIALECT="${DB_DIALECT:-PostgreSQL}"
  sqlfluff lint "${MIGRATIONS_DIR}" --dialect "${DB_DIALECT}"
  ;;
*)
  echo "Command $CMD not supported use: run, create, configure, lint, downgrade-all"
  exit 1
  ;;
esac
