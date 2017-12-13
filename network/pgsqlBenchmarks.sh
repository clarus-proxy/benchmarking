#!/bin/bash
TSP=$(date +%s)
if [ "$#" -lt 1 ]; then
  # PSQL server IP is 172.17.117.28
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
    head dataSets/ehealth/crypt/std/eHealth_tableScheme.tpl > $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    #psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableScheme.sql
    #psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_views.sql
    cat $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.tpl | nice -n 20 ./network/tools/encrypt_dataset.pl >> $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    echo "COMMIT;" >> $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    #cat $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql | nice -n 20 ./network/tools/decrypt_dataset.pl > $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData_nocrypt.sql
    sed -i -e "s///g" $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    #storing into postgres
    echo "psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql"
    psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql
    # Deleting the crypted file  version
    rm -f $DATASET_DIR/crypt/$DATASET_SIZE/eHealth_tableData.sql

else
    cat dataSets/ehealth/std/eHealth_tableScheme.tpl > $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    cat dataSets/ehealth/std/eHealth_tableData.tpl >> $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    echo "COMMIT;" >> $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    sed -i -e "s/\<feff\>/ /g" $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    sed -i -e "s/^M//g" $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql
    #psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/$DATASET_SIZE/eHealth_tableScheme.sql
    #psql -U postgres -h $IP -d $DB_NAME -f $DATASET_DIR/$DATASET_SIZE/eHealth_views.sql
    echo "psql -U postgres -h $IP -d $DB_NAME < $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql "
    psql -U postgres -h $IP -d $DB_NAME < $DATASET_DIR/$DATASET_SIZE/eHealth_tableData.sql 
fi
unset PGPASSWORD
