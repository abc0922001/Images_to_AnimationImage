#!/usr/bin/env bash

# 檢查 'make' 目錄是否存在
if [ ! -d "make" ]; then
  echo "目錄 'make' 不存在。"
  exit 1
fi

# 切換到 'make' 目錄
cd make || exit

# 檢查是否有 PNG 檔案
if [ -z "$(ls *.png 2> /dev/null)" ]; then
  echo "沒有在目錄中找到 PNG 檔案。"
  exit 1
fi

# 初始化檔案計數器
file_counter=0

# 對目錄中的每個 .png 檔案進行重新命名
for file in *.png; do
  # 格式化新檔名
  new_name=$(printf "Base%06d.png" "$file_counter")
  # 重新命名檔案
  if ! mv -- "$file" "$new_name"; then
    echo "無法重命名檔案 '$file'。"
    exit 1
  fi
  # 更新檔案計數器
  file_counter=$((file_counter + 1))
done

echo "所有 PNG 檔案已重命名。"
