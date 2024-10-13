#!/bin/sh

filename=""
size=320

ffmpeg -i "${filename}.gif" -vf "scale=$size:-1" "${filename}_resize.gif"

#read -n 1 -p "Press any key to continue..."
