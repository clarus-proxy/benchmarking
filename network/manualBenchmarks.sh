# /bin/bash

#METRIC="--write-out %{http_code}\tPre-Transfer: %{time_pretransfer}\tStart Transfer: %{time_starttransfer}\tTotal: %{time_total}\tSize: %{size_download}\n"
#METRIC="-w HTTP_CODE:%{http_code}\\nTOTAL_TIME:%{time_total}\\n"
METRIC="-w @tools/filters/metrics"
HEADERS="-H 'Pragma: no-cache' -H 'Cache-Control: no-cache'"
CURL_ARGS="--silent --output /dev/null $METRIC $HEADERS "
if [ "$#" -lt 1 ]; then
	# Demo GEO server IP is 172.17.117.24
	echo $0 SERVER_IP CLARUS_IP
fi

for IP in "$@"; do
	URL="http://$IP:8080/geoserver/wfs"
    EXT="_measures.log"
    DIR="results/"
    DATE=$(date +%s)
    FILENAME="$DIR$DATE"_"$IP$EXT"
    mkdir $DIR &> /dev/null
    echo "" > $FILENAME
	# GET BOREHOLES
	ARGS="bbox=-4554423,3840196,4754994,9294742,EPSG:3857&request=GetFeature&service=WFS&srsname=EPSG:3857&typename=clarus:groundwater_boreholes_3857&version=1.1.0"
	CMD="curl $CURL_ARGS -X GET \"$URL?$ARGS\""
    #echo $CMD
    eval $CMD >> $FILENAME 
	
#	# SEARCH through BOREHOLES
	CMD="curl $CURL_ARGS -X POST --data @../../dataSets/geo/std/searchWfsBoreholes.xml \"$URL\""
    eval $CMD >> $FILENAME 

#	# GET GASPIPE
    ARGS="?bbox=-4554423,3840196,4754994,9294742,EPSG:3857&request=GetFeature&service=WFS&srsname=EPSG:3857&typename=clarus:gaspipe_trans_light&version=1.1.0"
	CMD="curl $CURL_ARGS -X GET \"$URL?$ARGS\""
    eval $CMD >> $FILENAME 
#	
#	# GET GASLEAK 
	ARGS="bbox=-4554423,3840196,4754994,9294742,EPSG:3857&request=GetFeature&service=WFS&srsname=EPSG:3857&typename=clarus:gasleak&version=1.1.0"
	CMD="curl $CURL_ARGS -X GET \"$URL?$ARGS\""
    eval $CMD >> $FILENAME 
#	
#	# KRIGING PART
	URL="http://172.17.117.24:8080/wps/WebProcessingService"
    ARGS="Request=DescribeProcess&Service=WPS&version=1.0.0&Identifier=org.n52.wps.server.r.krige3857"
#	# GET KRIGING
	CMD="curl $CURL_ARGS -X GET \"$URL?$ARGS\""
    eval $CMD >> $FILENAME 
#	
#	# LAUNCH KRIGING
    ARGS="Request=DescribeProcess&Service=WPS&version=1.0.0&Identifier=org.n52.wps.server.r.krige3857"
	CMD="curl $CURL_ARGS -X POST --data @../../dataSets/geo/std/executeKriging.xml \"$URL?$ARGS\""
    eval $CMD >> $FILENAME 
done;
