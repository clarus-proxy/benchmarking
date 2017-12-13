#!/bin/bash
if [ "$#" -lt 1 ]; then
  echo $0 result_dir
fi
RESULT_DIR=$1
CURRENT_DIR=`pwd`
DATA="vmstat.txt"
GNUPLOT_OPTS="
set grid; set terminal png size 1920,1200;
"

cd $RESULT_DIR
cat vmstats.txt | grep -v r > vmstat.txt
gnuplot -p -e "$GNUPLOT_OPTS set output 'img/cpu.png'; set title 'CPU usage'; set yrange [ 0 : 100 ];set ytics 0,10; set mytics 2; 
    plot '$DATA' using 13 title 'CPU user load' with lines, '$DATA' using 14 ti 'CPU system load' w l, '$DATA' using 15 ti 'CPU idle time' w l, '$DATA' using 16 ti 'CPU IO wait time' w l"

gnuplot -p -e "$GNUPLOT_OPTS set output 'img/io.png'; set title 'IO'; set autoscale xy; set yrange [ 0 : 4000 ]; set ytics 0,1000; set mytics 2; plot '$DATA' using 9 ti 'in' w l, '$DATA' using 10 ti 'out' w l"

gnuplot -p -e "$GNUPLOT_OPTS set output 'img/memory.png'; set title 'MEMORY'; plot '$DATA' using 3 ti 'swap' w l, '$DATA' using 4 ti 'free' w l, '$DATA' using 5 ti 'buff' w l, '$DATA' using 6 ti 'cache' w l"

gnuplot -p -e "$GNUPLOT_OPTS set output 'img/system.png'; set title 'SYSTEM'; set yrange [ 0 : 5000 ]; set ytics 0,1000; set mytics 2; plot '$DATA' using 11 ti 'in' w l, '$DATA' using 12 ti 'cs' w l"

cat network_report | grep eno1 > network_report.tmp
DATA="network_report.tmp"
gnuplot -p -e "$GNUPLOT_OPTS set output 'img/network.png'; set title 'NETWORK'; set autoscale xy; plot '$DATA' using 3 ti 'rxpck/s' w l, '$DATA' using 4 ti 'rxpck/s' w l, '$DATA' using 5 ti 'rxkB/s' w l, '$DATA' using 6 ti 'txkB/s' w l, '$DATA' using 7 ti 'rxcmp/s' w l, '$DATA' using 8 ti 'txcmp/s' w l, '$DATA' using 9 ti 'rxmcst/s' w l, '$DATA' using 10 ti '%ifutil' w l"
rm $DATA

cat device_report.txt | grep -Ev "Device|Average|Linux" |sed '/^\s*$/d' > device_report.tmp
DATA="device_report.tmp"
gnuplot -p -e "$GNUPLOT_OPTS set output 'img/device.png'; set title 'DEVICE REPORT'; plot '$DATA' using 2 ti 'tps' w l, '$DATA' using 3 ti 'kB_read/s' w l, '$DATA' using 4 ti 'kB_wrtn/s' w l, '$DATA' using 5 ti 'kB_read' w l, '$DATA' using 6 ti 'kB_wrtn' w l"
rm $DATA
cd $CURRENT_DIR
