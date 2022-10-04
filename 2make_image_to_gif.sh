#!/bin/sh

w_cut=1920
h_cut=1080
x_cutpoint=0
y_cutpoint=0
Remark=""
size_factor=1
gifspeed=1
gif_size=6
z_contants=3.64
frame=30
giffps=${frame}

compression_ratio=$(echo "$z_contants" "$gifspeed" "$size_factor" | awk '{print ($2<1)?$1*$2/$3:($2/10+$1)/$3}')
echo "compression_ratio is $compression_ratio"
image_count=$(find ".\make" -maxdepth 1 -type f -printf . | wc -c)
echo "image_count is $image_count"
gif_length=$(echo "$image_count" "$frame" "$gifspeed" | awk '{print $1/$2/$3}')
echo "gif_length is $gif_length"
aspect_ratio=$(echo "$w_cut" "$h_cut" | awk '{print $1/$2}')
tmp=$(echo "$gif_size" "$aspect_ratio" "$giffps" "$compression_ratio" "$gif_length" | awk '{print $1*8*$2/$3/$4/$5}')
square_root=$(echo "$tmp" | awk '{print sqrt($1)}')
size=$(echo "$square_root" | awk '{print int($1*1024+0.5)}')
echo "size is $size"
today=$(date +%Y%m%d%H%M%S)

#====ffmpeg parameter====
sourceName=".\make\Base%6d.png"
cutParameter=${w_cut}:${h_cut}:${x_cutpoint}:${y_cutpoint}
scaleParameter="${size}:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3"
minterpolateParameter="fps=${giffps}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1"
outputName=./"${today}_${size}_${gifspeed}_${gif_length}s_${Remark}".gif
#========================

".\ffmpeg.exe" -f image2 -framerate ${frame}*${gifspeed} -i ${sourceName} -vf "crop=${cutParameter},minterpolate=${minterpolateParameter},scale=${scaleParameter}" -loop 0 "${outputName}"
#read -n 1 -p "Press any key to continue..."