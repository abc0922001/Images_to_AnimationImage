#!/bin/sh

# 定義輸入和輸出路徑
input_gif_file="your_input_gif_file.gif"  # 更換為您的 GIF 文件名
output_folder="./make"  # 輸出 PNG 文件的文件夾

# 檢查輸入文件是否存在
if [ ! -f "$input_gif_file" ]; then
    echo "錯誤：GIF 文件不存在"
    exit 1
fi

# 創建輸出文件夾（如果不存在）
mkdir -p "${output_folder}"

# 使用 ffmpeg 將 GIF 拆分為 PNG 文件
if ffmpeg -i "${input_gif_file}" -hide_banner -loglevel error "${output_folder}/Base%06d.png"; then
    echo "GIF 已成功拆分為 PNG 文件"
else
    echo "錯誤：無法將 GIF 拆分為 PNG 文件"
fi
