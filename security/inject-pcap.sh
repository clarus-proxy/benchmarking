#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 pcap_file" 1>&2
	echo "example: $0 pcap/ssl.pcap"
	exit 1
fi

tomahawk -i ens2 -j ens3 -R 1 -A 0 -l 1 -f $1
