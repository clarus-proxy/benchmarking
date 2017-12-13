#!/bin/bash
if [ "$#" -lt 1 ]; then
  echo $0 result_dir
fi
RESULT_DIR=$1
CURRENT_DIR=`pwd`
SAR2RRD_CMD=$CURRENT_DIR
SAR2RRD_CMD+="/performance/rrdTool/sar2rrd-2.6.2.pl"

cd $RESULT_DIR
mkdir rrd img &> /dev/null
for f in *; do
  if [[ "$f" -ne "rrd" ]] && [[ "$f" -ne "img" ]] && [[ "$f" -ne "vmstats.txt" ]] && [[ "$f" -ne "xml" ]]; then
    [[ -e $f ]] || continue
  else
    echo 'Average:' >> $f
    eval perl $SAR2RRD_CMD -f $f
  fi
done

cd $CURRENT_DIR
