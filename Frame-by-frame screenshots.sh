#!/bin/bash

#====ffmpeg parameter====
filename=""
startTime="00:00:00"
cutTime=3
imageScale=1920:1080
videoFormat=mp4
videoPath=""
#videoFormat=webm
#========================

ffmpeg -ss "$startTime" -i "$videoPath\\$filename.$videoFormat" -t "$cutTime" -s "$imageScale" -f image2 ".\make\image-%03d.png"