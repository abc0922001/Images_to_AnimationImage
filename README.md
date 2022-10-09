# Images_to_AnimationImage

1. 把 make 資料夾裡面的圖片製作成 gif 圖
1. 用 Frame-by-frame screenshots.sh 擷取影片 png 檔（無損畫質）
1. 點兩下執行 1rename.sh
   - 重新命名圖片順序
1. 再點兩下執行 2make_image_to_gif.sh
1. 裁圖方式：
   1. FastStone Image Viewer
   2. 使用剪裁編輯版，裁切要的大小跟畫面
   3. 記下下面的 xy 軸與大小
   4. 修改 2make_image_to_gif.sh 裡的參數
      1. w_cut 為裁切後的寬度
      2. h_cut 為裁切後的高度
      3. x_cutpoint 為裁切的 x 座標
      4. y_cutpoint 為裁切的 y 座標
      5. size_factor 為調整 gif 圖片檔案大小的比例
         - 有時候 gif 檔案大小會跟預期的有差距，以這參數作比例調整
      6. gifspeed 為 gif 的速度
      7. gif_size 為預計的 gif 檔案大小
         - 配合 size_factor 調整
      8. z_contants 為圖片壓縮率
         - 因為使用 lanczos 壓縮 gif，所以用一個常數去調整 gif 大小
      9. frame 為原始影片的幀率
