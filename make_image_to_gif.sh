frame=30
giffps=30
size=480
today=`date +%Y%m%d%H%M%S`
ffmpeg -f image2 -framerate ${frame} -i ".\make\Base%6d.jpg" -filter_complex "[0:v] fps=$giffps,scale=w=$size:h=-1,split [a][b];[a] palettegen=stats_mode=single [p];[b][p] paletteuse=new=1" -loop 0 -r ${giffps} ./${today}.gif
#read -n 1 -p "Press any key to continue..."