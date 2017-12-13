#!/bin/bash
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
TSP=$(date +%s)
DELAY=1
mkdir ./results/$TSP

# We have to remember to add the Line "Average:" at the end of each sar file

## VMSTAT metrics
#vmstat -n -t 5 1800 | awk '{now=strftime("%d-%m-%y     %H:%M:%S    "); print now $0}'> ./results/$TSP/vmstats.txt &   # this will run for 3 minutes
#
## SAR metrics
#sar -B $DELAY | awk '{now=strftime("%d-%m-%y    "); print now $0}'> ./results/$TSP/paging_report.txt &
#sar -b $DELAY | awk '{now=strftime("%d-%m-%y    "); print now $0}'> ./results/$TSP/io_report.txt &
#sar -n IP $DELAY | awk '{now=strftime("%d-%m-%y    "); print now $0}'> ./results/$TSP/network_report.txt &
#sar -r $DELAY | awk '{now=strftime("%d-%m-%y    "); print now $0}'> ./results/$TSP/memory_report.txt &
#sar -u $DELAY | awk '{now=strftime("%d-%m-%y    "); print now $0}'> ./results/$TSP/cpu_report.txt &
#
## iostat metrics
#iostat -d | awk '{now=strftime("%d-%m-%y    "); print now $0}'> ./results/$TSP/device_report.txt &
#iostat -d $DELAY | grep -v "Device" | awk '{now=strftime("%d-%m-%y    "); print now $0}'>> ./results/$TSP/device_report.txt &

# VMSTAT metrics
vmstat -n 5 1800 > ./results/$TSP/vmstats.txt &   # this will run for 3 minutes

# SAR metrics
sar -B $DELAY > ./results/$TSP/paging_report &
sar -b $DELAY > ./results/$TSP/io_report &
sar -n DEV $DELAY > ./results/$TSP/network_report &
sar -r $DELAY > ./results/$TSP/memory_report &
sar -u $DELAY > ./results/$TSP/cpu_report &

# iostat metrics
iostat -d > ./results/$TSP/device_report.txt &
iostat -d $DELAY | grep -v "Device" >> ./results/$TSP/device_report.txt &

# To kil everything
# ps xa | grep sar | grep -v grep | awk -F " " '{ print (}' | xargs -IFOO sudo kill -1 FOO)
