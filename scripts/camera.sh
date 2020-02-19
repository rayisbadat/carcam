#!/bin/bash

set -e
set -u

while [ $(ntpq -p| grep GPS  | tr -s " " | cut -d" " -f9 | cut -f2 -d"-" | cut -f1 -d"." ) -gt 5 ]
do
  sleep 1
done


DURATION=60 #segment length in seconds
NMEA_ROOT='/home/pi/carcam/nmea'

VIDEO_BASE="/home/pi/carcam/video"
TS="$(date +%s)"
DATE="$(date -d@"$TS" +%F)"
DATETIME=$(date -d@"$TS" +"%Y-%m-%d_%H:%M:%S")


video_segment="${VIDEO_BASE}/${DATE}"

LOOP_CNT=0

INIT_SUBTITLES() {
SUBTITLE=$( mktemp )
RAW_VIDEO="$( mktemp ).mpeg"
GPS_LOOP="$( mktemp )"
GPS_OUT=$( mktemp )

    #[ -f $SUBTITLE.vtt ] && rm $SUBTITLE.vtt
    #[ -f $SUBTITLE.srt ] && rm $SUBTITLE.srt

    echo "WEBVTT" > $SUBTITLE.vtt
    echo "" >> $SUBTITLE.vtt
    touch $SUBTITLE.srt
    count=0
    last_vtt_timestamp=0
    last_vtt_timestamp_min=0
    current_vtt_timestamp=0
    current_vtt_timestamp_min=0
    touch $GPS_LOOP #used so the gps to subtitle files function, knows when the main ffmpeg process ended, so it stops creating subtitles
    timestamp=$( date +%s )

}


GPS_SUBTITLES() {

while [ -f $GPS_LOOP ]
do

        count=$(( count + 1 ))
        last_vtt_timestamp=${current_vtt_timestamp}
        current_vtt_timestamp="$( printf "%02d" $(( $(date +%s) - timestamp )) )"

        if [ $last_vtt_timestamp -gt 59 ]
        then
          last_vtt_timestamp=$(( last_vtt_timestamp - 60 ))
          last_vtt_timestamp_min="$( printf "%02d" $(( last_vtt_timestamp_min + 1 )) )"
        fi

        if [ $current_vtt_timestamp -gt 59 ]
        then
          current_vtt_timestamp=$(( current_vtt_timestamp - 60 ))
          current_vtt_timestamp_min="$( printf "%02d" $(( current_vtt_timestamp_min + 1 )) )"
        fi

        gpspipe -w -n 10 |   grep -m 1 lon  > $GPS_OUT

        #Classic SRT subtitles
        echo "$count" >> $SUBTITLE.srt
        echo "00:${last_vtt_timestamp_min}:${last_vtt_timestamp},000 --> 00:${current_vtt_timestamp_min}:${current_vtt_timestamp},000" >> $SUBTITLE.srt
        cat $GPS_OUT  >> $SUBTITLE.srt
        echo "" >> $SUBTITLE.srt

        #WebVTT subtitles
        echo "${last_vtt_timestamp_min}:${last_vtt_timestamp}.000 --> ${current_vtt_timestamp_min}:${current_vtt_timestamp}.000" >> $SUBTITLE.vtt
	cat $GPS_OUT  >> $SUBTITLE.vtt
        echo "" >> $SUBTITLE.vtt
done


}

MERGE_SUBS_AND_VID() {

[ -d $video_segment ] || mkdir -p $video_segment
ffmpeg -y -loglevel verbose \
    -fflags +genpts \
    -i $RAW_VIDEO \
    -i $SUBTITLE.srt \
    -i $SUBTITLE.vtt \
    -map 0 -map 1 -map 2 \
    -codec:v copy \
    -c:s copy -metadata:s:s:0 language=eng -metadata:s:s:1 language=ipk \
    ${video_segment}/${DATE}_Loop-${LOOP_CNT}_${timestamp}.mkv &

#    -map 0 -map 1 -map 2 \
#    -i $SUBTITLE.srt \
#    -c:s copy -metadata:s:s:0 language=eng -metadata:s:s:1 language=ipk \

}



while [ 1 ]
do

	INIT_SUBTITLES
	GPS_SUBTITLES &
	
	raspivid -n -w 720 -h 405 -fps 25  -t $(( DURATION * 1000 )) -b 1800000 -ih -o $RAW_VIDEO  ;
	rm $GPS_LOOP

	MERGE_SUBS_AND_VID &

	#Increment the file name loop counter
	LOOP_CNT=$(( LOOP_CNT + 1 ))

done
    

#trap "rm stream.m3u8 segments/*.ts" EXIT

# vim:ts=2:sw=2:sts=2:et:ft=sh
