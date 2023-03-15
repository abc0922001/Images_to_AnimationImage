#!/bin/sh

input_gif="your_input_gif_file.gif"  # 更換為您的GIF文件名
output_folder=".\make"  # 輸出PNG文件的文件夾

# 創建輸出文件夾（如果不存在）
mkdir -p "${output_folder}"

# 使用ffmpeg將GIF拆分為PNG文件
ffmpeg -i "${input_gif}" -hide_banner -loglevel error "${output_folder}/Base%06d.png"

echo "GIF 已成功拆分為 PNG 文件"
