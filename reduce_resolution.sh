#!/bin/sh

filename=""
size=540

ffmpeg -i release/"${filename}.gif" -vf "scale=$size:-1" "${filename}_resize.gif"

#read -n 1 -p "Press any key to continue..."
