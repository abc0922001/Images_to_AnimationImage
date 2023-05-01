#!/bin/bash

#====ffmpeg parameter====
filename=""
startTime="00:00:00"
cutTime=3
imageScale=1920:1080
videoFormat=mp4
videoPath=""
#========================

ffmpeg -ss "$startTime" -i "$videoPath\\$filename.$videoFormat" -t "$cutTime" -vf scale="$imageScale" -pix_fmt rgb24 -preset ultrafast -crf 0 -vsync passthrough -f image2 ".\make\image-%03d.png"