<# 
¤å¥ó¡Gmake_image_to_webp
#> 

#rename
cd make
dir *.bmp | %{$x=0} {Rename-Item $_ -NewName "Base$($x.tostring('000000')).bmp"; $x++ }

#make to webp
cd..
$Today=Get-Date -Format "yyyyMMddHHmmss"
ffmpeg.exe -f image2 -i ".\make\Base%6d.bmp" -filter_complex "fps=30" -vsync 0 -loop 0 -y .\$Today.webp
