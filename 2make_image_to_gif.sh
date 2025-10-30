#!/bin/bash

# ============================================
# GIF 轉換工具 - ImageMagick 實現
# ============================================

set -e

# ============================================
# 0. 默認配置
# ============================================
declare -A CONFIG=(
    [w_cut]=1920
    [h_cut]=1080
    [x_cutpoint]=0
    [y_cutpoint]=0
	[remark]=""
    [gifspeed]=1
    [size_factor]=1
    [gif_size]=8
    [reverse_gif]=0
    [frame]=30
    [desired_fps]=30
)

# ============================================
# 1. 加載配置和參數
# ============================================
load_config() {
    # 從 config.conf 加載配置（如存在）
    if [[ -f "config.conf" ]]; then
        echo "✓ 從 config.conf 加載配置"
        source config.conf
    fi
    
    # 解析命令行參數 (覆蓋配置文件)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --width=*|--w=*)
                CONFIG[w_cut]="${1#*=}"
                ;;
            --height=*|--h=*)
                CONFIG[h_cut]="${1#*=}"
                ;;
            --crop-x=*)
                CONFIG[x_cutpoint]="${1#*=}"
                ;;
            --crop-y=*)
                CONFIG[y_cutpoint]="${1#*=}"
                ;;
            --speed=*)
                CONFIG[gifspeed]="${1#*=}"
                ;;
            --size-factor=*)
                CONFIG[size_factor]="${1#*=}"
                ;;
            --max-size=*)
                CONFIG[gif_size]="${1#*=}"
                ;;
            --reverse)
                CONFIG[reverse_gif]=1
                ;;
            --frame=*)
                CONFIG[frame]="${1#*=}"
                ;;
            --fps=*)
                CONFIG[desired_fps]="${1#*=}"
                ;;
            --name=*)
                CONFIG[remark]="${1#*=}"
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "✗ 未知參數: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# ============================================
# 顯示幫助
# ============================================
show_help() {
    cat << 'EOF'
GIF 轉換工具 - 使用說明

用法:
  ./converter.sh [選項]

選項:
  裁剪參數:
    --width=WIDTH          裁剪寬度 (默認: 1920)
    --height=HEIGHT        裁剪高度 (默認: 1080)
    --crop-x=X            裁剪起點 X 座標 (默認: 0)
    --crop-y=Y            裁剪起點 Y 座標 (默認: 0)

  GIF 參數:
    --speed=SPEED         播放速度倍數 (默認: 1)
    --max-size=SIZE       目標文件大小 MB (默認: 8)
    --frame=FRAME         源圖片幀數 (默認: 30)
    --fps=FPS            目標播放幀率 (默認: 30)
    --name=REMARK         文件名備註 (默認: converted)

  效果:
    --reverse             啟用倒帶效果
    --size-factor=FACTOR  初始尺寸因子 (默認: 1)

  其他:
    --help                顯示此幫助信息

示例:
  # 使用默認參數
  ./converter.sh

  # 自定義單個參數
  ./converter.sh --width=1280 --height=720 --speed=1.5

  # 完整示例
  ./converter.sh --width=1920 --height=1080 --crop-x=0 --crop-y=0 \
                 --speed=1 --max-size=8 --frame=30 --fps=30 \
                 --name="myanimation" --reverse

  # 使用配置文件 (config.conf) 後微調
  ./converter.sh --speed=2 --reverse

配置文件 (config.conf):
  在腳本目錄創建 config.conf，內容格式如下：
  CONFIG[w_cut]=1920
  CONFIG[h_cut]=1080
  CONFIG[x_cutpoint]=0
  CONFIG[y_cutpoint]=0
  CONFIG[gifspeed]=1
  CONFIG[size_factor]=1
  CONFIG[gif_size]=8
  CONFIG[reverse_gif]=0
  CONFIG[frame]=30
  CONFIG[desired_fps]=30
  CONFIG[remark]="converted"

EOF
}

# ============================================
# 初始化參數配置
# ============================================
initialize_parameters() {
    # 設置本地變量便於使用
    w_cut=${CONFIG[w_cut]}
    h_cut=${CONFIG[h_cut]}
    x_cutpoint=${CONFIG[x_cutpoint]}
    y_cutpoint=${CONFIG[y_cutpoint]}
    gifspeed=${CONFIG[gifspeed]}
    size_factor=${CONFIG[size_factor]}
    gif_size=${CONFIG[gif_size]}
    reverse_gif=${CONFIG[reverse_gif]}
    frame=${CONFIG[frame]}
    desired_fps=${CONFIG[desired_fps]}
    remark=${CONFIG[remark]}
    
    # 生成時間戳 (YYYYMMDDHHMMSS)
    timestamp=$(date +%Y%m%d%H%M%S)
    
    # 常數定義
    z_contants=0.5
    
    echo "✓ 初始化參數完成"
    echo "  裁剪尺寸: ${w_cut}x${h_cut} @ (${x_cutpoint},${y_cutpoint})"
    echo "  播放速度: ${gifspeed}x"
    echo "  目標幀率: ${desired_fps}fps"
    echo "  目標大小: ${gif_size}MB"
    echo "  倒帶效果: $([ $reverse_gif -eq 1 ] && echo '啟用' || echo '禁用')"
}

# ============================================
# 2. 圖片掃描與分析
# ============================================
scan_images() {
    if [[ ! -d "./make" ]]; then
        echo "✗ 錯誤: ./make 目錄不存在"
        return 1
    fi
    
    image_count=$(ls -1 ./make/*.png 2>/dev/null | wc -l)
    
    if [[ $image_count -eq 0 ]]; then
        echo "✗ 錯誤: 找不到任何 PNG 圖片"
        return 1
    fi
    
    echo "✓ 圖片數量為 ${image_count}"
    
    # 計算 GIF 播放長度
    gif_length=$(awk "BEGIN {printf \"%.2f\", ${image_count} / ${frame} / ${gifspeed}}")
    echo "✓ GIF 長度為 ${gif_length}s"
    
    # 計算幀率校正係數
    correction=$(awk "BEGIN {printf \"%.4f\", ${desired_fps} / ${frame}}")
    echo "✓ 幀率校正係數為 ${correction}"
}

# ============================================
# 3. 壓縮參數計算
# ============================================
calculate_compression_ratio() {
    local z_contants=$1
    local gifspeed=$2
    local size_factor=$3
    local w_cut=$4
    local h_cut=$5
    local desired_fps=$6
    local gif_length=$7
    local gif_size=$8
    
    # 計算壓縮比率
    compression_ratio=$(awk -v gs="$gifspeed" -v z="$z_contants" -v sf="$size_factor" \
        'BEGIN {
            if (gs < 1) {
                printf "%.4f", z / sf
            } else {
                printf "%.4f", (gs/10 + z) / sf
            }
        }')
    
    echo "✓ 壓縮參數為 ${compression_ratio}"
    
    # 計算長寬比
    aspect_ratio=$(awk "BEGIN {printf \"%.4f\", ${w_cut} / ${h_cut}}")
    
    # 計算目標寬度
    # size = ceil(sqrt((gif_size*8*aspect_ratio)/(giffps*compression_ratio*gif_length))*1024)
    giffps=$(awk "BEGIN {printf \"%.2f\", ${frame} * ${gifspeed}}")
    
    size=$(awk -v gs="$gif_size" -v ar="$aspect_ratio" -v gfps="$giffps" \
        -v cr="$compression_ratio" -v gl="$gif_length" \
        'BEGIN {
            val = (gs * 8 * ar) / (gfps * cr * gl)
            size = int(sqrt(val) * 1024)
            if (size == int(size)) {
                print size
            } else {
                print int(size) + 1
            }
        }')
    
    # 驗證寬度不超過源寬度
    if [[ $size -gt $w_cut ]]; then
        echo "  ⚠ Size 超過 w_cut，使用 ${w_cut}"
        size=$w_cut
    fi
    
    echo "✓ GIF 尺寸為 ${size}"
}

# ============================================
# 4. 倒帶過濾器配置
# ============================================
configure_reverse() {
    if [[ $reverse_gif -eq 1 ]]; then
        reverse_filter="-reverse"
        echo "✓ 倒帶效果已啟用"
    else
        reverse_filter=""
        echo "✓ 倒帶效果已禁用"
    fi
}

# ============================================
# 5. 動畫轉換執行
# ============================================
create_gif() {
    local output_file="${timestamp}_${size}_${gifspeed}_${gif_length}s_${remark}.webp"
    
    echo ""
    echo "開始轉換……"
    
    # 準備臨時目錄用於處理中間文件
    local tmp_dir=".tmp_convert_$$"
    mkdir -p "$tmp_dir"
    
    # 第一步：裁剪和縮放所有圖片
    local geometry="${w_cut}x${h_cut}+${x_cutpoint}+${y_cutpoint}"
    local scale_geo="${size}x$(awk "BEGIN {printf \"%.0f\", ${size} / ${w_cut} * ${h_cut}}")"
    
    echo "  → 正在處理圖片序列..."
    
    magick \
        -delay $((100 / (frame * gifspeed))) \
        "./make/Base*.png" \
        -crop "$geometry+0+0!" \
        -resize "$scale_geo" \
        -quality 100 \
        $reverse_filter \
        -colorspace sRGB \
        -loop 0 \
        -page +0+0 \
        "$output_file" 2>/dev/null || {
            echo "✗ 轉換失敗"
            rm -rf "$tmp_dir"
            return 1
        }
    
    rm -rf "$tmp_dir"
    echo "轉換結束！"
    echo "✓ 輸出檔案: ${output_file}"
}

# ============================================
# 6. 文件大小驗證與自動調整
# ============================================
verify_and_adjust_size() {
    if [[ ! -f "$output_file" ]]; then
        echo "✗ 輸出文件不存在"
        return 1
    fi
    
    # 獲取實際輸出大小（MB）
    local file_size_bytes=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
    actual_size=$(awk "BEGIN {printf \"%.2f\", ${file_size_bytes} / 1024 / 1024}")
    
    echo ""
    echo "輸出檔案大小為: ${actual_size}MB"
    
    # 定義容許範圍 ±4%
    min_size=$(awk "BEGIN {printf \"%.2f\", ${gif_size} * 0.96}")
    max_size=$(awk "BEGIN {printf \"%.2f\", ${gif_size} * 1.04}")
    
    # 檢查是否在容許範圍內
    if (( $(echo "$actual_size >= $min_size" | bc -l) )) && \
       (( $(echo "$actual_size <= $max_size" | bc -l) )); then
        echo "✓ 文件大小在容許範圍內 [${min_size}, ${max_size}]"
        return 0
    fi
    
    # 需要調整
    echo "⚠ 文件大小超出範圍，正在調整參數..."
    
    # 計算新的尺寸因子
    size_factor=$(awk "BEGIN {printf \"%.4f\", ${gif_size} / ${actual_size}}")
    echo "  尺寸因子為 ${size_factor}"
    
    # 刪除舊文件
    rm -f "$output_file"
    
    # 重新計算壓縮參數
    calculate_compression_ratio "$z_contants" "$gifspeed" "$size_factor" "$w_cut" "$h_cut" "$desired_fps" "$gif_length" "$gif_size"
    
    # 重新轉換
    create_gif
    
    # 再次驗證
    verify_and_adjust_size
}

# ============================================
# 7. 整體流程控制
# ============================================
main() {
    echo "========================================="
    echo "    GIF 轉換工具 (ImageMagick 版)"
    echo "========================================="
    echo ""
    
    # 1. 初始化參數
    initialize_parameters "$@"
    echo ""
    
    # 2. 掃描圖片
    scan_images || exit 1
    echo ""
    
    # 3. 配置倒帶
    configure_reverse
    echo ""
    
    # 4. 計算壓縮參數
    calculate_compression_ratio "$z_contants" "$gifspeed" "$size_factor" "$w_cut" "$h_cut" "$desired_fps" "$gif_length" "$gif_size"
    echo ""
    
    # 5. 執行轉換
    create_gif || exit 1
    echo ""
    
    # 6. 驗證和調整
    verify_and_adjust_size || exit 1
    echo ""
    
    echo "實際大小為 ${actual_size}MB，GIF 大小為 ${gif_size}MB"
    echo "========================================="
    echo "✓ 轉換流程完全結束"
    echo "========================================="
}

# ============================================
# 執行主程序
# ============================================
main "$@"