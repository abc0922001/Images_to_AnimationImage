frame=30
giffps=${frame}
size=480
today=`date +%Y%m%d%H%M%S`

".\ffmpeg.exe" -f image2 -framerate ${frame} -i ".\make\Base%6d.jpg" -vf "scale=$size:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle" -loop 0 -r ${giffps} ./${today}.gif
#read -n 1 -p "Press any key to continue..."