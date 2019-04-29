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
SUBFILE_PREP="${NMEA_ROOT}/.loc"
SUBFILE_FINAL="${NMEA_ROOT}/loc"

[ -f $SUBFILE_PREP.vtt ] && rm $SUBFILE_PREP.vtt
[ -f $SUBFILE_FINAL.vtt ] && rm $SUBFILE_FINAL.vtt
[ -f $SUBFILE_PREP.srt ] && rm $SUBFILE_PREP.srt
[ -f $SUBFILE_FINAL.srt ] && rm $SUBFILE_FINAL.srt

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
count=0

echo "WEBVTT" > $SUBFILE_PREP.vtt
echo "" >> $SUBFILE_PREP.vtt

#echo "" > $SUBFILE_PREP.srt
#echo "" >> $SUBFILE_PREP.srt
touch $SUBFILE_PREP.srt

while [ 1 ]
do
        #sleep ${SLEEP_TIME}s
	count=$(( count + 1 ))
	last_vtt_timestamp=${current_vtt_timestamp}
	current_vtt_timestamp=$(( $(date +%s) - timestamp ))
	gpspipe -w -n 10 |   grep -m 1 lon | jq . >> $SUBFILE_PREP

	#Classic SRT subtitles
	echo "$count" >> $SUBFILE_PREP.srt
	echo "00:00:${last_vtt_timestamp},000 --> 00:00:${current_vtt_timestamp},000" >> $SUBFILE_PREP.srt
	echo -n "GPS Output:  " >> $SUBFILE_PREP.srt
	cat $SUBFILE_PREP  >> $SUBFILE_PREP.srt
	echo "" >> $SUBFILE_PREP.srt
	cp $SUBFILE_PREP.srt $SUBFILE_FINAL.srt

	#WebVTT subtitles
	#I get wierd behavior playing these, but left them in anyway
	echo "00:${last_vtt_timestamp}.000 --> 00:${current_vtt_timestamp}.000" >> $SUBFILE_PREP.vtt
	echo -n "GPS Output:  " >> $SUBFILE_PREP.vtt
	cat $SUBFILE_PREP  >> $SUBFILE_PREP.vtt
	echo "" >> $SUBFILE_PREP.vtt
	cp $SUBFILE_PREP.vtt $SUBFILE_FINAL.vtt


done

