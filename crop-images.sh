#!/bin/bash

# 初始化輸入和輸出資料夾路徑
input_folder="./make"
output_folder="./crop-images"

# 設定裁剪的參數
crop_width=397
crop_height=1080
start_x=746
start_y=0

# 若輸出資料夾不存在，則建立之
mkdir -p "$output_folder"

# 迴圈處理每個 PNG 圖片
for image in "$input_folder"/*.png; do
    # 設定輸出檔案名稱
    output_filename="$output_folder/$(basename "$image")"

    # 使用 ffmpeg 進行圖片裁剪
    # -filter_complex 用來指定複雜的過濾器鏈
    # [0:v] 表示輸入影片的第一個影像流
    # crop 過濾器用於裁剪影像
    # hstack 過濾器用於水平堆疊影像
    ffmpeg -i "$image" -filter_complex "[0:v]crop=${start_x}:${crop_height}:0:0[left];[0:v]crop=in_w-${start_x}-${crop_width}:${crop_height}:${start_x}+${crop_width}:${start_y}[right];[left][right]hstack" "$output_filename"
done