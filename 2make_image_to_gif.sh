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
outputName=./"${today}".gif
tmpVido=./tmp/${today}video.flv
tmpPalette=./tmp/${today}palette.png
#========================

#產生調色盤
".\ffmpeg.exe" -f image2 -i ${sourceName} -vf "crop=${cutParameter},scale=${outputSize}:sws_dither=ed,palettegen" "${tmpPalette}"

#
".\ffmpeg.exe" -f image2 -framerate ${frame} -i ${sourceName} "${tmpVido}"

#使用調色盤做 gif
".\ffmpeg.exe" -i "${tmpVido}" -i "${tmpPalette}" -filter_complex  "crop=${cutParameter},scale=${outputSize}:flags=lanczos[x];[x][1:v]paletteuse" -loop 0 -r ${giffps} "${outputName}"
#read -n 1 -p "Press any key to continue..."