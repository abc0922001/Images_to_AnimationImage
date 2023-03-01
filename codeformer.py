import os
import replicate
import requests

model = replicate.models.get("sczhou/codeformer")
version = model.versions.get(
    "7de2ea26c616d5bf2245ad0d5e24f0ff9a6204578a5c876db53142edd9d2cd56")

input_folder = "image_restore_input"  # 輸入資料夾路徑
output_folder = "image_restore_output"  # 輸出資料夾路徑

# 若輸出資料夾不存在，則建立之
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# 迭代輸入資料夾中的所有檔案
for file_name in os.listdir(input_folder):
    # 檢查檔案是否為圖片檔案
    if file_name.endswith(".jpg") or file_name.endswith(".jpeg") or file_name.endswith(".png"):
        # 構造輸入和輸出檔案路徑
        input_file_path = os.path.join(input_folder, file_name)
        output_file_path = os.path.join(output_folder, file_name)

        # 檢查輸出資料夾中是否已經存在同名檔案
        if os.path.exists(output_file_path):
            print(f"{output_file_path} already exists. Skipping...")
            continue

        # 設定 API 的輸入參數
        inputs = {
            'image': open(input_file_path, "rb"),
            'codeformer_fidelity': 1,
            'background_enhance': True,
            'face_upsample': True,
            'upscale': 2,
        }

        # 呼叫 API 進行圖片修復
        output = version.predict(**inputs)
        response = requests.get(output)
        output_image = response.content
        # 將修復後的圖片保存到輸出資料夾中
        with open(output_file_path, "wb") as f:
            f.write(output_image)
