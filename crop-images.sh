#!/bin/bash

input_folder="./make"
output_folder="./crop-images"
crop_width=397
crop_height=1080
start_x=746
start_y=0

# Create output folder if it doesn't exist
mkdir -p "$output_folder"

for image in "$input_folder"/*.png; do
    output_filename="$output_folder/$(basename "$image")"
    ffmpeg -i "$image" -filter_complex "[0:v]crop=$start_x:$crop_height:0:0[left];[0:v]crop=in_w-$start_x-$crop_width:$crop_height:$start_x+$crop_width:$start_y[right];[left][right]hstack" "$output_filename"
done
