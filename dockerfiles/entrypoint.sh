#!/bin/sh
set -e

BINARY_PATH=/opt/rel/caltar/bin/caltar

if [ ! -f $DATABASE_PATH]; then
  mkdir -p $(dirname $DATABASE_PATH)
  sudo touch $DATABASE_PATH
fi


exec $BINARY_PATH "$@"
