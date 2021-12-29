# Images_to_AnimationImage

1. 把 make 資料夾裡面的圖片製作成 gif 圖
1. 用 potplayer 的連續截圖功能，截 jpg 格式的圖片
1. 點兩下執行 rename.sh
1. 再點兩下執行 make_image_to_gif.sh
1. 裁圖方式：
	1. FastStone Image Viewer
	1. 使用剪裁編輯版，裁切要的大小跟畫面
	1. 記下下面的 xy 軸與大小
	1. 修改 2make_image_to_gif.sh 裡的參數
      	1. w_cut 為裁切後的寬度
      	2. h_cut 為裁切後的高度
      	3. x_cutpoint 為裁切的 x 座標
      	4. y_cutpoint 為裁切的 y 座標