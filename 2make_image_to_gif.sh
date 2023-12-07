#!/bin/sh

# 初始化參數設定
initialize_parameters() {
    local_width=1920
    local_height=1080
    crop_x=0
    crop_y=0

    gif_remark=""
    gif_speed=1
    size_factor=1
    max_gif_size_mb=15
    reverse_gif=0

    z_constants=3.64
    frame_rate=30
    today=$(date +%Y%m%d%H%M%S)
}

# 計算影像數量和 GIF 長度
calculate_image_count_and_gif_length() {
    image_count=$(find ".\make" -maxdepth 1 -type f -printf . | wc -c)
    echo "圖片數量為 ${image_count}"

    gif_length=$(echo "${image_count} ${frame_rate} ${gif_speed}" | awk '{print $1/$2/$3}')
    echo "GIF 長度為 ${gif_length}"
}

# 計算壓縮比率和 GIF 尺寸
calculate_compression_and_size() {
    compression_ratio=$(echo "${z_constants} ${gif_speed} ${size_factor}" | awk '{print ($2<1)?$1/$3:($2/10+$1)/$3}')
    echo "壓縮參數為 ${compression_ratio}"

    aspect_ratio=$(echo "${local_width} ${local_height}" | awk '{print $1/$2}')
    tmp=$(echo "${max_gif_size_mb} ${aspect_ratio} ${frame_rate} ${compression_ratio} ${gif_length}" | awk '{print $1*8*$2/$3/$4/$5}')
    square_root=$(echo "${tmp}" | awk '{print sqrt($1)}')
    gif_size=$(echo "${square_root}" | awk '{print int($1*1024+0.5)}')
    echo "GIF 尺寸為 ${gif_size}"
}

# 創建 GIF
create_gif() {
    local scale_filter="scale=${gif_size}:-1:flags=lanczos"
    local palette="palettegen=reserve_transparent=0[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3"
    local minterpolate_filter="minterpolate='fps=${frame_rate}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1'"
    local crop_filter="crop=${local_width}:${local_height}:${crop_x}:${crop_y}"
    local reverse_filter=$([ ${reverse_gif} -eq 1 ] && echo "reverse," || echo "")

    output_name="./${today}_${gif_size}_${gif_speed}_${gif_length}s_${gif_remark}.gif"

    echo "開始轉換……"
    ffmpeg -f image2 -framerate ${frame_rate}*${gif_speed} -i .\make\Base%6d.png \
        -vf "format=rgb24,${crop_filter},${minterpolate_filter},${reverse_filter}split[s0][s1];[s0]${palette},${scale_filter}" \
        -q:v 2 -loop 0 "${output_name}"
    echo "轉換結束！"
}

# 檢查並調整 GIF 尺寸
check_and_adjust_gif_size() {
    actual_size_mb=$(stat -c '%s' "${output_name}" | awk '{printf "%.2f", $1/1024/1024}')
    echo "輸出檔案大小為: ${actual_size_mb}MB"

    min_size=$(awk -v size="${max_gif_size_mb}" 'BEGIN{print size * 0.95}')
    max_size=$(awk -v size="${max_gif_size_mb}" 'BEGIN{print size * 1.05}')

    if awk -v actual="${actual_size_mb}" -v min="${min_size}" -v max="${max_size}" 'BEGIN{exit !(actual < min || actual > max)}'; then
        size_factor=$(echo "${max_gif_size_mb} ${actual_size_mb}" | awk '{print ($1/$2)}')
        echo "尺寸因子調整為 ${size_factor}"
        calculate_compression_and_size
        create_gif
    fi
}

# 主程式開始
initialize_parameters
calculate_image_count_and_gif_length
calculate_compression_and_size
create_gif
check_and_adjust_gif_size
echo "實際大小為 ${actual_size_mb}MB，GIF 大小為 ${max_gif_size_mb}MB"
