#!/bin/sh

size=480
w_cut=iw
h_cut=ih
x_cutpoint=0
y_cutpoint=0
frame=30
giffps=${frame}
today=$(date +%Y%m%d%H%M%S)


#====ffmpeg parameter====
sourceName=".\make\Base%6d.jpg"
cutParameter=${w_cut}:${h_cut}:${x_cutpoint}:${y_cutpoint}
outputSize=${size}:-1
qualityParameter="lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3"
outputName=./"${today}".gif
#========================

".\ffmpeg.exe" -f image2 -framerate ${frame} -i ${sourceName} -vf "crop=${cutParameter},scale=${outputSize}:flags=${qualityParameter}" -loop 0 -r ${giffps} "${outputName}"
#read -n 1 -p "Press any key to continue..."