#!/bin/bash
# -r = Output raw NMEA sentences.
# -d = Causes gpspipe to run as a daemon.
# -l = Causes gpspipe to sleep for ten seconds before attempting to connect to gpsd.
# -o = Output to file.

set -e
set -u
#set -x

SLEEP_TIME=1 #in seconds
NMEA_ROOT='/home/pi/carcam/nmea'
SUBFILE_PREP="${NMEA_ROOT}/.loc.vtt"
SUBFILE_FINAL="${NMEA_ROOT}/loc.vtt"

[ -f $SUBFILE_PREP ] && rm $SUBFILE_PREP
[ -f $SUBFILE_FINAL ] && rm $SUBFILE_FINAL

timestamp=$( date +%s )
while [ "$timestamp" == "" ]
do
	timestamp=$( date +%s )
done

datetime=$(date -d@${timestamp}  +"%Y-%m-%d_%H:%M:%S")
date=$( date -d@${timestamp}  +"%Y-%m-%d" )
TGTDIR="${NMEA_ROOT}/${date}"

[ -d "$TGTDIR" ]  || mkdir -p $TGTDIR
gpspipe -r -d -l -o $TGTDIR/${datetime}.nmea

last_vtt_timestamp=00
current_vtt_timestamp="00"

echo "WEBVTT" > $SUBFILE_PREP
echo "" >> $SUBFILE_PREP

while [ 1 ]
do
        sleep ${SLEEP_TIME}s
	last_vtt_timestamp=${current_vtt_timestamp}
	current_vtt_timestamp=$(( $(date +%s) - timestamp ))

	echo "00:${last_vtt_timestamp}.000 --> 00:${current_vtt_timestamp}.000" >> $SUBFILE_PREP
	echo -n "GPS Output:  " >> $SUBFILE_PREP
	gpspipe -w -n 10 |   grep -m 1 lon | jq . >> $SUBFILE_PREP
	echo "" >> $SUBFILE_PREP

	cp $SUBFILE_PREP $SUBFILE_FINAL

done

