#!/bin/bash

set -e
set -u

overlay_text_file='/home/pi/carcam/nmea/loc'
VIDEO_BASE="/home/pi/carcam/video"

video_segment="${VIDEO_BASE}/$(date +%F)"
[ -d $video_segment ] || mkdir -p $video_segment


while [ ! -e $overlay_text_file.vtt ]; do sleep 1s ; done
while [ ! -e $overlay_text_file.srt ]; do sleep 1s ; done


raspivid -n -w 720 -h 405 -fps 25 -vf -t 0 -b 1800000 -ih -o - \
|   ffmpeg -y -loglevel verbose \
    -i - \
    -i $overlay_text_file.srt \
    -i $overlay_text_file.vtt \
    -map 0 -map 1 -map 2 \
    -c:s copy -metadata:s:s:0 language=eng -metadata:s:s:1 language=ipk \
    -codec:v copy \
    -codec:s copy \
    -f ssegment \
    -segment_time 60 \
    -strftime 1 "${video_segment}/%Y-%m-%d_%H-%M-%S.mkv"

#    -c:s mov_text -metadata:s:s:0 language=eng -metadata:s:s:1 language=ipk \
#trap "rm stream.m3u8 segments/*.ts" EXIT

# vim:ts=2:sw=2:sts=2:et:ft=sh
