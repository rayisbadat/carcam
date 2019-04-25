#!/bin/bash
# -r = Output raw NMEA sentences.
# -d = Causes gpspipe to run as a daemon.
# -l = Causes gpspipe to sleep for ten seconds before attempting to connect to gpsd.
# -o = Output to file.

datetime=$(date +"%Y%m%d-%H-%M-%S")
gpspipe -r -d -l -o /home/pi/carcam/nmea/${datetime}.nmea

while [ 1 ]
do
	echo -n "GPS Output:  " > /home/pi/carcam/nmea/.loc.txt
	gpspipe -w -n 10 |   grep -m 1 lon | jq . >> /home/pi/carcam/nmea/.loc.txt
	mv /home/pi/carcam/nmea/.loc.txt /home/pi/carcam/nmea/loc.txt
	sleep 1s
done

