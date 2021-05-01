input=".\make\Base%6d.jpg"
today=`date +%Y%m%d%H%M%S`
filters="scale=350:-1:flags=lanczos"
pale="split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
#make to webp

ffmpeg -f image2 -framerate 30 -i "$input" -vf "$filters,$pale" -loop 0 -r 30 ./${today}.gif
#read -n 1 -p "Press any key to continue..."