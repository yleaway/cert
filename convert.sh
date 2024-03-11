#!/bin/bash

# 检查参数是否正确
if [ $# -ne 0 ]; then
    echo "用法: $0"
    exit 1
fi

# 获取固件下载URL
read -p "请输入固件下载地址: " firmware_url

# 下载固件
echo "正在下载固件..."
wget -q "$firmware_url" -O firmware.img.gz
if [ $? -ne 0 ]; then
    echo "错误: 下载固件失败"
    exit 1
fi

# 提取文件名（不包含扩展名）
filename=$(basename "$firmware_url" | sed 's/\.[^.]*$//')

# 解压缩固件（如果是img.gz格式）
if [[ "$firmware_url" == *".gz" ]]; then
    echo "正在解压缩固件..."
    gunzip -f firmware.img.gz || echo "警告: 解压缩固件失败"
fi

# 创建临时目录
temp_dir=$(mktemp -d)
if [ $? -ne 0 ]; then
    echo "错误: 无法创建临时目录"
    exit 1
fi

# 挂载IMG文件到临时目录
sudo mount -o loop firmware.img "$temp_dir"
if [ $? -ne 0 ]; then
    echo "错误: 无法挂载IMG文件到临时目录"
    rm -rf "$temp_dir"
    exit 1
fi

# 创建tar.gz文件
output_tar_gz="$PWD/$filename.tar.gz"
tar -czf "$output_tar_gz" -C "$temp_dir" .

# 卸载临时目录
sudo umount "$temp_dir"
if [ $? -ne 0 ]; then
    echo "警告: 无法卸载临时目录，请手动卸载：sudo umount $temp_dir"
fi

# 删除临时目录和下载的固件文件
rm -rf "$temp_dir" firmware.img firmware.img.gz

echo "转换完成: $output_tar_gz"
