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
#Discord max 25MB
gif_size=15

# 設定是否倒帶
# 設為 1 以啟用倒帶；設為 0 以禁用倒帶
reverse_gif=0

# 設定其他參數
z_contants=3.64
frame=30
giffps=${frame}
today=$(date +%Y%m%d%H%M%S)

# 計算圖片數量
image_count=$(find ".\make" -maxdepth 1 -type f -printf . | wc -c)
echo "圖片數量為 $image_count"

# 計算 GIF 長度
gif_length=$(echo "$image_count" "$frame" "$gifspeed" | awk '{print $1/$2/$3}')
echo "GIF 長度為 $gif_length"

#====ffmpeg parameter====
sourceName=".\make\Base%6d.png"
cutParameter=${w_cut}:${h_cut}:${x_cutpoint}:${y_cutpoint}

calculate_compression_ratio() {
    # 計算壓縮參數
    compression_ratio=$(echo "$z_contants" "$gifspeed" "$size_factor" | awk '{print ($2<1)?$1/$3:($2/10+$1)/$3}')
    echo "壓縮參數為 $compression_ratio"

    # 計算 GIF 尺寸
    aspect_ratio=$(echo "$w_cut" "$h_cut" | awk '{print $1/$2}')
    tmp=$(echo "$gif_size" "$aspect_ratio" "$giffps" "$compression_ratio" "$gif_length" | awk '{print $1*8*$2/$3/$4/$5}')
    square_root=$(echo "$tmp" | awk '{print sqrt($1)}')
    size=$(echo "$square_root" | awk '{print int($1*1024+0.5)}')
    echo "GIF 尺寸為 $size"
}

create_gif() {
    # 設定動畫轉換參數
    scaleParameter="${size}:-1:flags=lanczos,${reverse_filter}split[s0][s1];[s0]palettegen=reserve_transparent=0:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3"
    minterpolateParameter="fps=${frame}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1"

    # 設定輸出檔名
    outputName=./"${today}_${size}_${gifspeed}_${gif_length}s_${Remark}".gif

    # 執行動畫轉換
    echo "開始轉換……"
    ffmpeg -f image2 -framerate ${frame} -i ${sourceName} -vf "format=rgb24,setpts=(1/${gifspeed})*PTS,crop=${cutParameter},minterpolate=${minterpolateParameter},scale=${scaleParameter}" -q:v 2 -loop 0 "${outputName}"
    echo "轉換結束！"
}

# 根據 reverse_gif 值添加 reverse 過濾器
if [ $reverse_gif -eq 1 ]; then
    reverse_filter="reverse,"
else
    reverse_filter=""
fi

# 調用函數計算壓縮比率和尺寸
calculate_compression_ratio

#檢查 size 是否大於 w_cut
if [ "$size" -gt $w_cut ]; then
    size=$w_cut
    echo "Size 超過 w_cut，使用 $size"
    # 調用函數創建 GIF
    create_gif
    exit 1
fi

# 調用函數創建 GIF
create_gif

# 獲取實際大小（單位：MB）
actual_size=$(stat -c '%s' "${outputName}" | awk '{printf "%.2f", $1/1024/1024}')

# 打印實際大小
echo "輸出檔案大小為: ${actual_size}MB"

# 利用 awk 進行比較，檢查是否需要調整 size_factor
min_size=$(awk -v size="$gif_size" 'BEGIN{print size * 0.95}')
max_size=$(awk -v size="$gif_size" 'BEGIN{print size * 1.05}')

if awk -v actual="$actual_size" -v min="$min_size" -v max="$max_size" 'BEGIN{exit !(actual < min || actual > max)}'; then
    # 重新計算壓縮參數
    size_factor=$(echo "${gif_size} ${actual_size}" | awk '{print ($1/$2)}')

    echo "尺寸因子為 ${size_factor}"

    # 調用函數計算壓縮比率和尺寸
    calculate_compression_ratio

    #檢查 size 是否大於 w_cut
    if [ "$size" -gt $w_cut ]; then
        size=$w_cut
        echo "Size 超過 w_cut，使用 $size"  
    fi
    
    # 調用函數創建 GIF
    create_gif
fi
echo "實際大小為 ${actual_size}MB，GIF 大小為 ${gif_size}MB"

#read -n 1 -p "Press any key to continue..."
