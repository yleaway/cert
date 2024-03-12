#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Prompt the user to input the firmware download URL or local path
read -p "请输入固件下载地址或者固件本地路径: " firmware_path

# Check if the input is a URL or local path
if [[ "$firmware_path" =~ ^https?:// || "$firmware_path" =~ ^/ ]]; then
    # If the input is a URL, download the firmware file
    if [[ "$firmware_path" =~ ^https?:// ]]; then
        # Extract filename from URL
        filename=$(basename "$firmware_path")

        # Download the firmware file
        wget "$firmware_path" -P /root/ || { echo -e "${RED}下载固件文件失败。${NC}"; exit 1; }

        # Check if the downloaded file is a .img or .img.gz file
        if [[ "$filename" == *.img ]]; then
            firmware_file="/root/$filename"
        elif [[ "$filename" == *.img.gz ]]; then
            # Extract the .img.gz file to .img
            gunzip "/root/$filename" || { echo -e "${RED}解压固件文件失败。${NC}"; exit 1; }
            firmware_file="/root/${filename%.gz}"
        else
            echo "不支持的文件格式。"
            exit 1
        fi
    else
        # If the input is a local path, set firmware_file to the specified path
        firmware_file="$firmware_path"
    fi
else
    echo "无效的输入。请输入固件下载地址或者固件本地路径。"
    exit 1
fi

# Get the partition offset
root_partition=$((`fdisk -l "$firmware_file" | grep .img2 | awk '{print $2}'` * 512))

# Mount the second partition
mount -o loop,offset=$root_partition "$firmware_file" /root/op || { echo -e "${RED}挂载分区失败。${NC}"; exit 1; }

# Verify mount point exists
if [ ! -d "/root/op" ]; then
    echo -e "${RED}挂载点不存在。${NC}"
    exit 1
fi

# Change directory to the mounted partition
cd /root/op || exit 1

# Get the base name of the file without extension
filename=$(basename "$firmware_file" | sed 's/\(\.img\|\.img\.gz\|\.gz\)$//')

# Prompt the user to input the path for the tar.gz archive
read -p "请输入生成固件的路径，回车将使用默认路径 (/var/lib/vz/template/cache/$filename.tar.gz): " archive_path

# If user input is empty, use default path
if [ -z "$archive_path" ]; then
    archive_path="/var/lib/vz/template/cache/$filename.tar.gz"
else
    # Check if the input path contains filename
    if [[ ! "$archive_path" =~ \.tar\.gz$ ]]; then
        # Append filename to the directory path
        archive_path="${archive_path}/${filename}.tar.gz"
    fi
fi

# Create a tar.gz archive of the files and move it to the specified or default path
tar zcf "$archive_path" * || { echo -e "${RED}创建归档文件失败。${NC}"; exit 1; }

# Display success message and archive file path
echo -e "${GREEN}固件文件创建成功${NC}"：${archive_path}

# Move back to the original directory
cd ..

# Prompt the user to confirm deletion of the source file
read -p "是否删除源文件 ($firmware_file)？(y/N): " confirm_delete

# Check user input
if [[ "$confirm_delete" == "Y" || "$confirm_delete" == "y" ]]; then
    # Delete the source file
    rm -rf "$firmware_file"
    echo -e "${GREEN}源文件已删除。${NC}"
else
    echo -e "${RED}源文件未删除，请手动删除。${NC}"
fi

# Unmount the partition
umount /root/op || { echo -e "${RED}卸载分区失败。${NC}"; exit 1; }
