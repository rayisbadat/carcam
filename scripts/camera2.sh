#!/bin/bash

base="/home/pi/carcam/video"
overlay_text_file='/home/pi/carcam/nmea/loc.txt'

#cd $base

#raspivid -n -w 720 -h 405 -fps 25 -vf -t 86400000 -b 1800000 -ih -o - \
raspivid -n -w 720 -h 405 -fps 25 -vf -t 0 -b 1800000 -ih -o - \
| ffmpeg \
    -i - \
    -filter_complex drawtext=textfile=${overlay_text_file}:reload=1:fontsize=12:fontcolor=yellow \
    -f mpegts \
    pipe:1 \
|   ffmpeg -y \
    -i - \
    -c:v copy \
    -map 0:0 \
    -f ssegment \
    -segment_time 60 \
    -segment_format mpegts \
    -segment_list "$base/stream.m3u8" \
    -segment_list_size 720 \
    -segment_list_flags live \
    -segment_list_type m3u8 \
    -strftime 1 \
    "${base}/segments/%Y-%m-%d_%H-%M-%S.ts"

#trap "rm stream.m3u8 segments/*.ts" EXIT

# vim:ts=2:sw=2:sts=2:et:ft=sh
