<# 
���Gmake_image_to_gif
#> 

#rename
cd make
dir *.bmp | %{$x=0} {Rename-Item $_ -NewName "Base$($x.tostring('000000')).bmp"; $x++ }

#make to webp
#800x450
#640x360
cd..
$Today=Get-Date -Format "yyyyMMddHHmmss"
ffmpeg.exe -f image2 -i ".\make\Base%6d.bmp" -filter_complex "fps=30" -vsync 0 -loop 0 -s 800x450 -y .\$Today.gif
