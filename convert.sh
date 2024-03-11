#!/bin/bash
# 函数：下载IMG固件
download_firmware() {
    local firmware_url=$1
    local output_file=$2
    
    echo "正在下载固件..."
    wget -q "$firmware_url" -O "$output_file"
    if [ $? -ne 0 ]; then
        echo "错误: 下载固件失败"
        exit 1
    fi
    echo "固件下载完成: $output_file"
}

# 获取固件下载URL
read -p "请输入固件下载URL: " firmware_url

# 获取输入IMG文件路径
read -p "请输入输入IMG文件路径: " input_img

# 获取输出目录路径
read -p "请输入输出目录路径: " output_dir

# 检查输入文件是否存在
if [ ! -f "$input_img" ]; then
    echo "错误: 输入IMG文件 '$input_img' 不存在"
    exit 1
fi

# 提取文件名（不包含扩展名）
filename=$(basename "$input_img" | sed 's/\.img\.gz$//')

# 检查是否有临时目录，如果没有则创建
temp_dir=$(mktemp -d)
if [ $? -ne 0 ]; then
    echo "错误: 无法创建临时目录"
    exit 1
fi

# 解压缩IMG固件（如果是img.gz格式）
if [[ "$input_img" == *.img.gz ]]; then
    echo "正在解压缩固件..."
    gzip -d "$input_img" -c > "$temp_dir/$filename.img"
    if [ $? -ne 0 ]; then
        echo "错误: 解压缩固件失败"
        exit 1
    fi
    input_img="$temp_dir/$filename.img"
fi

# 挂载IMG文件到临时目录
sudo mount -o loop "$input_img" "$temp_dir"
if [ $? -ne 0 ]; then
    echo "错误: 无法挂载IMG文件到临时目录"
    rm -rf "$temp_dir"
    exit 1
fi

# 创建tar.gz文件
tar_gz_output="$output_dir/$filename.tar.gz"
tar -czf "$tar_gz_output" -C "$temp_dir" .

# 卸载临时目录
sudo umount "$temp_dir"
if [ $? -ne 0 ]; then
    echo "警告: 无法卸载临时目录，请手动卸载：sudo umount $temp_dir"
fi

# 删除临时目录
rm -rf "$temp_dir"

echo "转换完成: $tar_gz_output"
