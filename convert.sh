#!/bin/bash

# Prompt the user to input the firmware download URL
read -p "请输入固件下载网址: " firmware_url

# Extract filename from URL
filename=$(basename "$firmware_url")

# Download the firmware file
wget "$firmware_url" -P /root/

# Check if the downloaded file is a .img or .img.gz file
if [[ "$filename" == *.img ]]; then
    firmware_file="/root/$filename"
elif [[ "$filename" == *.img.gz ]]; then
    # Extract the .img.gz file to .img
    gunzip "/root/$filename"
    firmware_file="/root/${filename%.gz}"
else
    echo "不支持的文件格式。"
    exit 1
fi

# Get the partition offset
root_partition=$((`fdisk -l "$firmware_file" | grep .img2 | awk '{print $2}'` * 512))

# Mount the second partition
mount -o loop,offset=$root_partition "$firmware_file" /root/op

# Change directory to the mounted partition
cd /root/op || exit 1

# Create a tar.gz archive of the files and move it to the template cache directory
tar zcf "/var/lib/vz/template/cache/$filename.tar.gz" * 

# Move back to the original directory
cd ..

# Unmount the partition and remove the image file
umount /root/op && rm -rf "$firmware_file"
