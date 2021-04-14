<# 
���Gmake_image_to_gif
#> 

#rename
cd make
dir *.jpg | %{$x=0} {Rename-Item $_ -NewName "Base$($x.tostring('000000')).jpg"; $x++ }

#make to webp
#1   800x450
#0.8 640x360
#0.7 560x315
cd..
$Today=Get-Date -Format "yyyyMMddHHmmss"
ffmpeg.exe -f image2 -framerate 15 -i ".\make\Base%6d.jpg" -vsync 0 -loop 0 -s 800x450 -y .\$Today.gif
