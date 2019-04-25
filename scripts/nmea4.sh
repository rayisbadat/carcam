#!/bin/bash
# -r = Output raw NMEA sentences.
# -d = Causes gpspipe to run as a daemon.
# -l = Causes gpspipe to sleep for ten seconds before attempting to connect to gpsd.
# -o = Output to file.

SUBFILE_PREP='/home/pi/carcam/nmea/.loc.vtt'
SUBFILE_FINAL='/home/pi/carcam/nmea/loc.vtt'

datetime=$(date +"%Y%m%d-%H-%M-%S")
gpspipe -r -d -l -o /home/pi/carcam/nmea/${datetime}.nmea

while [ 1 ]
do
	echo "WEBVTT" > $SUBFILE_PREP
	echo "" >> $SUBFILE_PREP
	echo "00:00.000 --> 00:60.000" >> $SUBFILE_PREP
	echo -n "GPS Output:  " >> $SUBFILE_PREP
	gpspipe -w -n 10 |   grep -m 1 lon | jq . >> $SUBFILE_PREP
	mv $SUBFILE_PREP $SUBFILE_FINAL
	sleep 1s
done

