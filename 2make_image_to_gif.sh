size=480
w_cut=iw
h_cut=ih
x_cutpoint=0
y_cutpoint=0
frame=30
giffps=${frame}
today=`date +%Y%m%d%H%M%S`

".\ffmpeg.exe" -f image2 -framerate ${frame} -i ".\make\Base%6d.jpg" -vf "crop=${w_cut}:${h_cut}:${x_cutpoint}:${y_cutpoint},scale=$size:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" -loop 0 -r ${giffps} ./${today}.gif
#read -n 1 -p "Press any key to continue..."