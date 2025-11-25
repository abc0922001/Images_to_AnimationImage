#!/bin/sh

# ==========================================
#  WebP 自動化轉檔腳本 (Git Bash 相容修正版)
#  修正：移除 bc 依賴，全改用 awk 運算
# ==========================================

# 1. 基礎參數設定
w_cut=1920
h_cut=1080
x_cutpoint=0
y_cutpoint=0

Remark=""
# Discord max limit (10MB)
gif_size=8

# 動畫控制
gifspeed=1
reverse_gif=0

# FPS 設定
frame=30
desired_fps=30
today=$(date +%Y%m%d%H%M%S)

# 2. 核心演算法參數
# 針對 -q:v 85
z_contants=0.25
quality_val=85

# 3. 檔案環境準備
source_dir="./make"
# Windows Git Bash 路徑修正
source_pattern="${source_dir}/Base%6d.png"

# 計算圖片數量
image_count=$(find "${source_dir}" -maxdepth 1 -type f -name "*.png" | wc -l)

if [ "$image_count" -eq 0 ]; then
    echo "錯誤：在 ${source_dir} 找不到 .png 圖片。"
    exit 1
fi
echo "圖片數量為: $image_count"

# ==== 純 awk 計算區域 (取代 bc) ====

# 計算 GIF 長度
gif_length=$(awk -v c="$image_count" -v f="$frame" -v s="$gifspeed" 'BEGIN {printf "%.2f", c/f/s}')

# 計算校正係數
correction=$(awk -v d="$desired_fps" -v f="$frame" 'BEGIN {print d/f}')

cutParameter=${w_cut}:${h_cut}:${x_cutpoint}:${y_cutpoint}

# 4. 濾鏡邏輯

# 倒帶
if [ "$reverse_gif" -eq 1 ]; then
    reverse_filter="reverse,"
else
    reverse_filter=""
fi

# 補幀 (使用 awk 判斷 float)
is_slow_motion=$(awk -v s="$gifspeed" 'BEGIN {print (s < 1) ? 1 : 0}')

if [ "$is_slow_motion" -eq 1 ]; then
    echo "偵測到慢動作 ($gifspeed)，啟用補幀..."
    minterpolate_filter="minterpolate=fps=${frame}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1,"
else
    minterpolate_filter=""
fi

# 5. 函數定義

calculate_target_width() {
    # 計算 BPP 與 目標寬度 (全 awk)
    # 邏輯：Width = sqrt( (TargetMB * 8388608) / (Aspect * TotalFrames * BPP) )

    size=$(awk -v z="$z_contants" -v gs="$gifspeed" -v target="$gif_size" \
               -v wc="$w_cut" -v hc="$h_cut" -v fr="$frame" -v gl="$gif_length" \
    'BEGIN {
        # 1. 調整 BPP
        bpp = (gs > 1) ? z * 1.15 : z;
        print "使用 BPP 係數: " bpp > "/dev/stderr";

        # 2. 計算總幀數與比例
        total_frames = fr * gs * gl;
        aspect = wc / hc;

        # 3. 計算目標寬度
        if (total_frames > 0 && aspect > 0 && bpp > 0) {
            tmp_val = (target * 8388608) / (aspect * total_frames * bpp);
            calc_w = int(sqrt(tmp_val));
        } else {
            calc_w = wc; # 避免除以零
        }

        # 4. 安全檢查
        if (calc_w > wc) {
            print wc;
        } else {
            print calc_w;
        }
    }')

    echo "預估目標寬度: $size px"
}

create_webp() {
    outputName="./${today}_${size}_${gifspeed}_${gif_length}s_${Remark}.webp"

    # 計算最終 framerate (使用 awk)
    final_fps=$(awk -v f="$frame" -v s="$gifspeed" 'BEGIN {print f * s}')

    scaleParameter="${size}:-1:flags=lanczos,${reverse_filter}"

    echo "----------------------------------------"
    echo "開始轉換... (FPS: $final_fps)"
    echo "----------------------------------------"

    ffmpeg -y -f image2 -framerate "$final_fps" \
        -i "${source_pattern}" \
        -vf "crop=${cutParameter},${minterpolate_filter}setpts=PTS*${correction},scale=${scaleParameter}" \
        -lossless 0 -q:v ${quality_val} \
        -pix_fmt yuva420p \
        -loop 0 \
        -hide_banner -loglevel warning \
        "${outputName}"

    echo "轉換結束。"
}

# 6. 主執行流程

calculate_target_width
create_webp

# 檢查結果
if [ -f "${outputName}" ]; then
    actual_size=$(stat -c '%s' "${outputName}" | awk '{printf "%.2f", $1/1024/1024}')
    echo "實際大小: ${actual_size} MB (目標: ${gif_size} MB)"
else
    echo "錯誤：輸出檔案不存在，FFmpeg 執行失敗。"
    exit 1
fi

# 7. 二次校正 (智慧攔截版)
# 邏輯優化：
# 1. 如果檔案太大 -> 必須重跑 (Downscale)
# 2. 如果檔案太小 -> 檢查是否已達解析度上限 (w_cut)
#    - 已達上限：不重跑 (避免無效運算)
#    - 未達上限：重跑 (Upscale)

needs_retry=$(awk -v act="$actual_size" -v target="$gif_size" \
              -v cur_w="$size" -v max_w="$w_cut" \
              'BEGIN {
                  min = target * 0.90;
                  max = target * 1.02;

                  # 情況 1: 檔案太大 (必須縮小)
                  if (act > max) {
                      print 1;
                      exit;
                  }

                  # 情況 2: 檔案太小
                  if (act < min) {
                      # 關鍵判斷：如果已經是最大解析度，重跑也沒用，直接放棄
                      if (cur_w >= max_w) {
                          print 0;
                      } else {
                          print 1;
                      }
                      exit;
                  }

                  # 情況 3: 大小剛好
                  print 0;
              }')

if [ "$needs_retry" -eq 1 ]; then
    echo "大小不符預期，進行修正..."

    # 計算新尺寸 (全 awk)
    size=$(awk -v target="$gif_size" -v actual="$actual_size" -v current_w="$size" -v max_w="$w_cut" \
    'BEGIN {
        factor = sqrt(target / actual);
        # 這裡有個細節：如果是縮小(太大)，我們乘 0.98 確保過關
        # 如果是放大(太小)，我們乘 1.0 盡量填滿，因為反正有 max_w 擋著
        if (factor < 1) {
            new_w = int(current_w * factor * 0.98);
        } else {
            new_w = int(current_w * factor);
        }

        if (new_w > max_w) new_w = max_w;
        print new_w;
    }')

    echo "重試寬度: $size px"
    create_webp

    final_size=$(stat -c '%s' "${outputName}" | awk '{printf "%.2f", $1/1024/1024}')
    echo "最終大小: ${final_size} MB"
else
    # 這裡可以告訴使用者為什麼不重跑
    if [ $(awk -v a="$actual_size" -v m="$w_cut" -v c="$size" 'BEGIN{print (a < 7.0 && c >= m) ? 1 : 0}') -eq 1 ]; then
        echo "雖然檔案較小 ($actual_size MB)，但解析度已達上限 ($w_cut px)，不再重試。"
    else
        echo "大小符合範圍 ($actual_size MB)，無需重試。"
    fi
fi

exit 0
