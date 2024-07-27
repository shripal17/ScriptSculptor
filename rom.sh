#!/bin/bash
#set -e

# we need to make a folder for the ROM first
mkdir voltageos

# Connect your Github account.
git config --global user.name "Niranjan BR"
git config --global user.email "niranjankannan2003@gmail.com"

# Go to ROM folder.
cd voltageos

# Initialize VoltageOS Source

repo init -u https://github.com/VoltageOS/manifest.git -b 14 --git-lfs

# And to Sync it

repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# Clone device sources

# device tree
git clone https://github.com/narikootam-dev/device_xiaomi_sweet device/xiaomi/sweet 

# vendor tree
git clone https://github.com/narikootam-dev/vendor_xiaomi_sweet vendor/xiaomi/sweet 

# kernel tree
git clone https://github.com/narikootam-dev/kernel_xiaomi_msm4.14 kernel/xiaomi/sweet

# clone extra repos
# miui camera
git clone https://gitlab.com/mrfox2003/sweet-miuicamera vendor/xiaomi/sweet-miuicamera

# dolby
git clone https://github.com/narikootam-dev/hardware_dolby hardware/dolby

# hardware/xiaomi
git clone https://github.com/LineageOS/android_hardware_xiaomi hardware/xiaomi

# Lets build it!

. build/envsetup.sh

brunch sweet
 
