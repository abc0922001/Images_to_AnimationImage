<# 
¤å¥ó¡Gmake_image_to_gif
#> 

#rename
cd make
dir *.jpg | %{$x=0} {Rename-Item $_ -NewName "Base$($x.tostring('000000')).jpg"; $x++ }
