#!/bin/bash

#====ffmpeg parameter====
filename=""
startTime="00:00:00"
cutTime=3
imageScale=1920:1080
videoFormat=mp4
#========================

".\ffmpeg.exe" -ss "$startTime" -i "$filename"."$videoFormat" -t "$cutTime" -vf scale="$imageScale" -compression_level 0 -vsync 0 -f image2 ".\make\image-%03d.png"