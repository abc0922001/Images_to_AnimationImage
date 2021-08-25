# Images_to_AnimationImage

1. 把 make 資料夾裡面的圖片製作成 gif 圖
1. 用 potplayer 的連續截圖功能，截 jpg 格式的圖片
1. 先右鍵用 PowerShell 執行 rename.ps1
1. 再點兩下執行 make_image_to_gif.sh
1. 裁圖方式：
	1. FastStone Image Viewer
	1. 使用剪裁編輯版，裁切要的大小跟畫面
	1. 記下下面的 xy 軸與大小
	1. 到工具>批次選擇轉換的圖像(F3)
	1. 當進階選項>裁剪>填入寬度、高度、X、Y
	1. 轉完後，make_image_to_gif.ps1 裡面的大小也要跟著調整，不然比例會錯