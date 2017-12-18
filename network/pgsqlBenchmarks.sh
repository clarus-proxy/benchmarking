#!/bin/bash
# /home/hargathor/dev/clarus-proxy/benchmarking/network/pgsqlBenchmarks.sh
# Copyright (c) 2017 hargathor <3949704+hargathor@users.noreply.github.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# File              : /home/hargathor/dev/clarus-proxy/benchmarking/network/pgsqlBenchmarks.sh
# Author            : hargathor <3949704+hargathor@users.noreply.github.com>
# Date              : 13.12.2017
# Last Modified Date: 14.12.2017
# Last Modified By  : hargathor <3949704+hargathor@users.noreply.github.com>
TSP=$(date +%s)
if [ "$#" -lt 1 ]; then
  echo $0 SERVER_IP CLARUS_IP
fi
IP=$1
DATASET_DIR=$2
DATASET_SIZE=$3
DB_NAME=$4
ENCRYPT=$5
export PGSSLMODE=disable
export PGPASSWORD="password"
psql -U postgres -h $IP -c "CREATE DATABASE $DB_NAME;"
if [ $ENCRYPT == "True" ]; then
    # head dataSets/ehealth/std/eHealth_tableScheme.tpl > $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    #psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableScheme.sql
    #psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_views.sql
    cat $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql | nice -n 20 ./network/tools/encrypt_dataset.pl >> $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    # echo "COMMIT;" >> $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    #cat $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql | nice -n 20 ./network/tools/decrypt_dataset.pl > $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData_nocrypt.sql
    # dos2unix $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    #storing into postgres
    echo "psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql"
    psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    # Deleting the crypted file  version
    rm -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql

else
    # cat dataSets/ehealth/std/eHealth_tableScheme.tpl > $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    # cat dataSets/ehealth/$DATASET_SIZE/eHealth_tableData.tpl >> $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    # dos2unix $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    # echo "COMMIT;" >> $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    #sed -i -e "s/\<feff\>/ /g" $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    #sed -i -e "s/^M//g" $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    #psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/$DATASET_SIZE/eHealth_tableScheme.sql
    #psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/$DATASET_SIZE/eHealth_views.sql
    echo "psql -U postgres -h $IP -d $DB_NAME < $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql"
    psql -U postgres -h $IP -d $DB_NAME < $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql 
fi
unset PGPASSWORD
