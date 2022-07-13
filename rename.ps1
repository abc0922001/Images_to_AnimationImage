<# 
���Gmake_image_to_gif
#> 

#rename
Set-Location make
Get-ChildItem *.png | % { $x = 0 } { Rename-Item $_ -NewName "Base$($x.tostring('000000')).png"; $x++ }
