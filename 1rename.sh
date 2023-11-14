#!/usr/bin/env bash

if [ ! -d "make" ]; then
  echo "目錄 'make' 不存在。"
  exit 1
fi

cd make || exit
x=0

for f in *.png; do
  new_name=$(printf "Base%06d.png" "$x")
  mv -- "$f" "$new_name"
  x=$((x+1))
done
