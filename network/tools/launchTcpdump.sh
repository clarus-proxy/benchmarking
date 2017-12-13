if [ "$#" -lt 1 ]; then
  # Demo GEO server IP is 172.17.117.24
  echo $0 filter_file 
fi
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
FILTER=$1
tcpdump -i ens3 -l -e -n port not 22 | $FILTER

