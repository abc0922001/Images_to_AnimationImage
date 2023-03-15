#!/bin/sh

# 設定圖片裁剪參數
w_cut=1920
h_cut=1080
x_cutpoint=0
y_cutpoint=0

# 設定 GIF 參數
Remark=""
gifspeed=1
size_factor=1
gif_size=5.5

# 設定其他參數
z_contants=3.64
frame=30
giffps=${frame}

# 計算壓縮參數
compression_ratio=$(echo "$z_contants" "$gifspeed" "$size_factor" | awk '{print ($2<1)?$1/$3:($2/10+$1)/$3}')
echo "壓縮參數為 $compression_ratio"

# 計算圖片數量
image_count=$(find ".\make" -maxdepth 1 -type f -printf . | wc -c)
echo "圖片數量為 $image_count"

# 計算 GIF 長度
gif_length=$(echo "$image_count" "$frame" "$gifspeed" | awk '{print $1/$2/$3}')
echo "GIF 長度為 $gif_length"

# 計算 GIF 尺寸
aspect_ratio=$(echo "$w_cut" "$h_cut" | awk '{print $1/$2}')
tmp=$(echo "$gif_size" "$aspect_ratio" "$giffps" "$compression_ratio" "$gif_length" | awk '{print $1*8*$2/$3/$4/$5}')
square_root=$(echo "$tmp" | awk '{print sqrt($1)}')
size=$(echo "$square_root" | awk '{print int($1*1024+0.5)}')
echo "GIF 尺寸為 $size"
today=$(date +%Y%m%d%H%M%S)

#====ffmpeg parameter====
sourceName=".\make\Base%6d.png"
cutParameter=${w_cut}:${h_cut}:${x_cutpoint}:${y_cutpoint}

# 設定動畫轉換參數，包括生成調色板和應用調色板
scaleParameter="${size}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=diff:colors=256[p];[s1][p]paletteuse=dither=floyd_steinberg"
#scaleParameter="${size}:-1:flags=lanczos,reverse,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3"
minterpolateParameter="fps=${frame}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1"

# 設定輸出檔名
outputName=./"${today}_${size}_${gifspeed}_${gif_length}s_${Remark}".gif
#========================

# 執行動畫轉換，加上 -stats 參數以輸出進度和資訊
echo "開始轉換……"
ffmpeg -hide_banner -loglevel error -f image2 -framerate ${frame}*${gifspeed} -i ${sourceName} -vf "crop=${cutParameter},minterpolate=${minterpolateParameter},scale=${scaleParameter}" -loop 0 "${outputName}"
echo "轉換結束！"
#read -n 1 -p "Press any key to continue..."

# 如果最後輸出的檔案大小超出 gif_size 正負 5% 範圍，就調整 size_factor 參數
actual_size=$(stat -c '%s' "${outputName}" | awk -F ',' '{printf "%.2f", $1/1024/1024}')
echo "輸出檔案大小為: ${actual_size}MB"
if [ "$(echo "${actual_size} < (${gif_size} * 0.95)" | awk '{print ($1 < $2)}')" -eq 1 ] || [ "$(echo "${actual_size} > (${gif_size} * 1.05)}" | awk '{print ($1 > $2)}')" -eq 1 ]; then
    size_factor=$(echo "${gif_size} ${actual_size}" | awk '{print ($1/$2)}')
    # 重新計算壓縮參數
    compression_ratio=$(echo "$z_contants" "$gifspeed" "$size_factor" | awk '{print ($2<1)?$1/$3:($2/10+$1)/$3}')
    echo "重新壓縮參數為 $compression_ratio"
    # 重新計算 GIF 尺寸
    aspect_ratio=$(echo "$w_cut" "$h_cut" | awk '{print $1/$2}')
    tmp=$(echo "$gif_size" "$aspect_ratio" "$giffps" "$compression_ratio" "$gif_length" | awk '{print $1*8*$2/$3/$4/$5}')
    square_root=$(echo "$tmp" | awk '{print sqrt($1)}')
    size=$(echo "$square_root" | awk '{print int($1*1024+0.5)}')
    echo "新的 GIF 尺寸為 $size"
    # 設定動畫轉換參數，包括生成調色板和應用調色板
    scaleParameter="${size}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=diff:colors=256[p];[s1][p]paletteuse=dither=floyd_steinberg"
    echo "開始轉換……"
    ffmpeg -y -hide_banner -loglevel error -f image2 -framerate ${frame}*${gifspeed} -i ${sourceName} -vf "crop=${cutParameter},minterpolate=${minterpolateParameter},scale=${scaleParameter}" -loop 0 "${outputName}"
    echo "轉換結束！"
fi
echo "實際大小為 ${actual_size}MB，GIF 大小為 ${gif_size}MB，尺寸因子為 ${size_factor}"

#read -n 1 -p "Press any key to continue..."
