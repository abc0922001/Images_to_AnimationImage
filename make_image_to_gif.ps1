<# 
¤å¥ó¡Gmake_image_to_gif
#> 

#rename
cd make
dir *.jpg | %{$x=0} {Rename-Item $_ -NewName "Base$($x.tostring('000000')).jpg"; $x++ }

#make to webp
cd..
$Today=Get-Date -Format "yyyyMMddHHmmss"
ffmpeg.exe -f image2 -framerate 15 -i ".\make\Base%6d.jpg" -vsync 0 -loop 0 -vf "scale=iw/2.4:ih/2.4" -y .\$Today.gif
