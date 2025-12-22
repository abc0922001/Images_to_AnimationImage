#!/bin/sh

# ==============================================================================
#  WebP 自動化轉檔腳本 (Git Bash 相容 / 完美優化版)
#  功能：將序列圖片轉為 WebP，自動控制檔案大小與畫質平衡。
#  特點：
#   1. 自動計算 BPP (Bits Per Pixel) 以預估解析度。
#   2. 針對慢動作自動啟用 AI 補幀 (Motion Interpolation)。
#   3. 智慧二次校正：使用平方根邏輯精確調整大小，並具備無效重試攔截功能。
# ==============================================================================

# ==== 1. 基礎參數設定 ====

# 圖片來源裁切參數
w_cut=1920
h_cut=1080
x_cutpoint=0
y_cutpoint=0

# 輸出標籤與檔案限制
Remark=""
# 設定目標大小 (MB)。Discord 上限為 10MB。
gif_size=8

# 動畫控制參數
# gifspeed: 1=原速, <1=慢動作(自動補幀), >1=加速
gifspeed=1
# reverse_gif: 1=啟用倒帶, 0=禁用
reverse_gif=0

# FPS 設定
frame=30
desired_fps=30
today=$(date +%Y%m%d%H%M%S)

# ==== 2. 演算法核心參數 ====

# 壓縮常數 (Bits Per Pixel, BPP)
# 設計決策：在 -q:v 85 的高畫質設定下，每個像素約佔用 0.25 bits。
# 若設定過低會導致初次輸出檔案超標；設定過高則會過度壓縮解析度。
z_contants=0.25

# WebP 畫質參數 (0-100)
# 選擇 85 而非 100 的原因：WebP 在 80-85 為甜蜜點，100 會導致檔案體積暴增但肉眼差異極小。
quality_val=90

# ==== 3. 檔案與環境準備 ====

source_dir="./make"
# 修正路徑分隔符號為 "/" 以相容 Linux/Git Bash 環境
source_pattern="${source_dir}/Base%6d.png"

# 計算圖片數量
image_count=$(find "${source_dir}" -maxdepth 1 -type f -name "*.png" | wc -l)

if [ "$image_count" -eq 0 ]; then
    echo "錯誤：在 ${source_dir} 找不到 .png 圖片。"
    exit 1
fi
echo "圖片數量為: $image_count"

# ==== 4. 基礎數值運算 (使用 awk 取代 bc) ====

# 計算影片總長度 (秒)
gif_length=$(awk -v c="$image_count" -v f="$frame" -v s="$gifspeed" 'BEGIN {printf "%.2f", c/f/s}')

# 計算 PTS 校正係數 (用於控制播放速度)
correction=$(awk -v d="$desired_fps" -v f="$frame" 'BEGIN {print d/f}')

# 設定裁切字串
cutParameter=${w_cut}:${h_cut}:${x_cutpoint}:${y_cutpoint}

# ==== 5. 濾鏡邏輯判斷 ====

# 設定倒帶濾鏡
if [ "$reverse_gif" -eq 1 ]; then
    reverse_filter="reverse,"
else
    reverse_filter=""
fi

# 設定補幀濾鏡 (Motion Interpolation)
# 設計決策：僅在 gifspeed < 1 (慢動作) 時啟用。
# 原因：minterpolate 運算成本極高。慢動作時補幀可避免卡頓 (幻燈片感)；
# 原速或加速時，補幀不僅浪費時間，還可能產生不必要的殘影。
is_slow_motion=$(awk -v s="$gifspeed" 'BEGIN {print (s < 1) ? 1 : 0}')

if [ "$is_slow_motion" -eq 1 ]; then
    echo "偵測到慢動作 ($gifspeed)，啟用高品質補幀 (MCI/AOBMC)..."
    # fps=${frame} 強制輸出維持流暢的幀率，而非隨速度降低
    minterpolate_filter="minterpolate=fps=${frame}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1,"
else
    minterpolate_filter=""
fi

# ==== 6. 核心函數定義 ====

# 函數：calculate_target_width
# 目的：根據目標檔案大小，反推合適的解析度 (寬度)。
# 原理：檔案大小 ≈ 總像素量 * BPP。
#       Width = sqrt( (TargetMB * 8bit * 1024^2) / (Aspect * TotalFrames * BPP) )
calculate_target_width() {
    size=$(awk -v z="$z_contants" -v gs="$gifspeed" -v target="$gif_size" \
               -v wc="$w_cut" -v hc="$h_cut" -v fr="$frame" -v gl="$gif_length" \
    'BEGIN {
        # 若加速播放 (>1)，畫面變動率高，WebP 壓縮率會下降，故增加 BPP 預估值
        bpp = (gs > 1) ? z * 1.15 : z;
        print "使用 BPP 係數: " bpp > "/dev/stderr";

        # 計算總幀數與長寬比
        total_frames = fr * gs * gl;
        aspect = wc / hc;

        # 避免除以零的保護機制
        if (total_frames > 0 && aspect > 0 && bpp > 0) {
            # 核心公式運算
            tmp_val = (target * 8388608) / (aspect * total_frames * bpp);
            calc_w = int(sqrt(tmp_val));
        } else {
            calc_w = wc;
        }

        # 邊界檢查：計算結果不可超過原始裁切寬度
        if (calc_w > wc) {
            print wc;
        } else {
            print calc_w;
        }
    }')

    echo "預估目標寬度: $size px"
}

# 函數：create_webp
# 目的：執行 FFmpeg 轉檔指令。
# 設計決策：
# 1. 使用 yuva420p：確保在有損壓縮下仍能保留 Alpha 通道 (透明背景)。
# 2. 濾鏡順序：Crop -> [Minterpolate] -> [Reverse] -> SetPTS -> Scale。
#    確保先裁切掉不要的區域再進行補幀運算，提升效率。
create_webp() {
    outputName="./${today}_${size}_${gifspeed}_${gif_length}s_${Remark}.webp"

    # 計算實際輸出的 FPS
    final_fps=$(awk -v f="$frame" -v s="$gifspeed" 'BEGIN {print f * s}')

    # 組合 Scale 濾鏡 (包含倒帶)
    scaleParameter="${size}:-1:flags=lanczos,${reverse_filter}"

    echo "----------------------------------------"
    echo "開始轉換... (寬度: $size, FPS: $final_fps)"
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

# ==== 7. 主執行流程 ====

# 第一階段：初步估算與轉檔
calculate_target_width
create_webp

# 檢查檔案是否存在
if [ ! -f "${outputName}" ]; then
    echo "錯誤：輸出檔案不存在，FFmpeg 執行失敗。"
    exit 1
fi

# 獲取實際檔案大小
actual_size=$(stat -c '%s' "${outputName}" | awk '{printf "%.2f", $1/1024/1024}')
echo "實際大小: ${actual_size} MB (目標: ${gif_size} MB)"

# ==== 8. 智慧二次校正機制 ====
# 目的：檢查檔案是否符合 Discord 限制，並決定是否重試。
# 邏輯重點：
# 1. 若檔案過大 -> 必須縮小 (Downscale)。
# 2. 若檔案過小 -> 僅在「解析度尚未達上限」時才放大 (Upscale)。
#    若已是最大解析度 (w_cut) 則不重試，避免無效的重複運算。

needs_retry=$(awk -v act="$actual_size" -v target="$gif_size" \
              -v cur_w="$size" -v max_w="$w_cut" \
              'BEGIN {
                  min = target * 0.90; # 允許小於目標 10%
                  max = target * 1.02; # 允許超過目標 2% (寬容值)

                  # 情況 A: 檔案太大 (必須重試)
                  if (act > max) {
                      print 1;
                      exit;
                  }

                  # 情況 B: 檔案太小
                  if (act < min) {
                      # 關鍵防呆：若已經是最大解析度，重試也無法變更大，直接放棄
                      if (cur_w >= max_w) {
                          print 0;
                      } else {
                          print 1;
                      }
                      exit;
                  }

                  # 情況 C: 大小剛好
                  print 0;
              }')

if [ "$needs_retry" -eq 1 ]; then
    echo "大小不符預期，進行精確修正..."

    # 計算修正後的寬度
    # 原理：利用面積公式，修正因子 = sqrt(目標大小 / 實際大小)
    size=$(awk -v target="$gif_size" -v actual="$actual_size" -v current_w="$size" -v max_w="$w_cut" \
    'BEGIN {
        factor = sqrt(target / actual);

        # 若是縮小操作，乘上 0.98 作為安全緩衝，確保第二次一定過關
        # 若是放大操作，則盡量貼近目標
        if (factor < 1) {
            new_w = int(current_w * factor * 0.98);
        } else {
            new_w = int(current_w * factor);
        }

        # 邊界檢查
        if (new_w > max_w) new_w = max_w;
        print new_w;
    }')

    echo "重試寬度: $size px"
    create_webp

    final_size=$(stat -c '%s' "${outputName}" | awk '{printf "%.2f", $1/1024/1024}')
    echo "最終大小: ${final_size} MB"
else
    # 輸出不重試的原因，讓使用者安心
    check_reason=$(awk -v act="$actual_size" -v cw="$size" -v mw="$w_cut" \
                   'BEGIN { print (act < 7.0 && cw >= mw) ? 1 : 0 }')

    if [ "$check_reason" -eq 1 ]; then
        echo "雖檔案較小 ($actual_size MB)，但解析度已達來源上限 ($w_cut px)，不再重試。"
    else
        echo "大小符合範圍，無需重試。"
    fi
fi

exit 0
