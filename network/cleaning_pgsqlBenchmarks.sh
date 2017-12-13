#!/bin/bash
if [ "$#" -lt 1 ]; then
  # PSQL server IP is 172.17.117.28
  echo $0 SERVER_IP CLARUS_IP
fi
IP=$1
DATASET_DIR=$2
DATASET_SIZE=$3
DB_NAME=$4
export PGPASSWORD="password"
psql -U postgres -h $IP -l | cut -d " " -f 2 | grep ehealth | xargs -IFOO psql -U postgres -h $IP -c "DROP DATABASE FOO;"
unset PGPASSWORD
