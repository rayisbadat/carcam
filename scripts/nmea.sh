#!/bin/bash
# -r = Output raw NMEA sentences.
# -d = Causes gpspipe to run as a daemon.
# -l = Causes gpspipe to sleep for ten seconds before attempting to connect to gpsd.
# -o = Output to file.

set -e
set -u


NMEA_ROOT='/home/pi/carcam/nmea'
GPS_LOCK=$( /tmp/gpslock )

while [ $(ntpq -p| grep GPS  | tr -s " " | cut -d" " -f9 | cut -f2 -d"-" | cut -f1 -d"." ) -gt 5 ]
do
	sleep 1
done

touch $GPS_LOCK

timestamp=$( date +%s )

datetime=$(date -d@${timestamp}  +"%Y-%m-%d_%H:%M:%S")
date=$( date -d@${timestamp}  +"%Y-%m-%d" )
TGTDIR="${NMEA_ROOT}/${date}"

[ -d "$TGTDIR" ]  || mkdir -p $TGTDIR
gpspipe -r -d -l -o $TGTDIR/${datetime}.nmea
