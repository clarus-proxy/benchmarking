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
export PGPASSWORD="password"
if [ "$ENCRYPT" == "True" ]; then
    echo "`echo "SELECT * FROM discharge_simple WHERE pat_id='00000113';" | ./network/tools/encrypt_dataset.pl`" >> ./network/tools/requests.tmp
    echo "`echo "SELECT * FROM discharge_simple WHERE pat_name='JESUS' AND pat_last1='RUEDA' AND pat_last2='BRAVO';" | ./network/tools/encrypt_dataset.pl`">> ./network/tools/requests.tmp
    echo "`echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE pat_gen='M';" | ./network/tools/encrypt_dataset.pl`">> ./network/tools/requests.tmp
    echo "`echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE ep_range='01';" | ./network/tools/encrypt_dataset.pl`">> ./network/tools/requests.tmp
    echo "`echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_serv='CAR';" | ./network/tools/encrypt_dataset.pl`">> ./network/tools/requests.tmp
    echo "`echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_adm='2015/04/04/';" | ./network/tools/encrypt_dataset.pl`">> ./network/tools/requests.tmp
    echo "`echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_dis='2015/10/13/'" | ./network/tools/encrypt_dataset.pl`">> ./network/tools/requests.tmp
    echo "`echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_adtp='EN';" | ./network/tools/encrypt_dataset.pl`">> ./network/tools/requests.tmp
    echo "`echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_dest='01';" | ./network/tools/encrypt_dataset.pl`">> ./network/tools/requests.tmp
    echo "`echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dia_id='070.54';" | ./network/tools/encrypt_dataset.pl`">> ./network/tools/requests.tmp
else
    echo "SELECT * FROM discharge_simple WHERE pat_id='00000113';">> ./network/tools/requests.tmp
    echo "SELECT * FROM discharge_simple WHERE pat_name='JESUS' AND pat_last1='RUEDA' AND pat_last2='BRAVO';">> ./network/tools/requests.tmp
    echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE pat_gen='M';">> ./network/tools/requests.tmp
    echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE ep_range='01';">> ./network/tools/requests.tmp
    echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_serv='CAR';">> ./network/tools/requests.tmp
    echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_adm='2015/04/04/';">> ./network/tools/requests.tmp
    echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_dis='2015/10/13/'">> ./network/tools/requests.tmp
    echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_adtp='EN';">> ./network/tools/requests.tmp
    echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dis_dest='01';">> ./network/tools/requests.tmp
    echo "SELECT  DISTINCT  ON  (dis_id,  dis_ver)  *  FROM  discharge_advanced  WHERE dia_id='070.54';">> ./network/tools/requests.tmp
fi
pgbench -U postgres -h $IP -d $DB_NAME -i
pgbench -U postgres -h $IP -d $DB_NAME -q -f ./network/tools/requests.tmp 
rm ./network/tools/requests.tmp
