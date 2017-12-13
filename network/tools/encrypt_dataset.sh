#!/bin/bash
DATA=$1
ENC_DATA=$2

echo "Encrypting database $DATA...."
cat $DATA | grep -v INSERT | cut -c 2- | awk -F'[(,]' '{newstr=system("./network/tools/encrypt.sh "$1); print newStr}'
