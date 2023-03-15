#!/bin/bash

cd make
x=0

for f in *.png; do
  new_name=$(printf "Base%06d.png" $x)
  mv -- "$f" "$new_name"
  x=$((x+1))
done
