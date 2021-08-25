today=`date +%Y%m%d%H%M%S`
starttime=1
time=2.5
size=480
giffps=30

./ffmpeg.exe -ss ${starttime} -t ${time} -i output.mp4 -filter_complex "[0:v] fps=$giffps,scale=w=$size:h=-1,split [a][b];[a] palettegen=stats_mode=single [p];[b][p] paletteuse=new=1" ${today}.gif
#read -n 1 -p "Press any key to continue..."
