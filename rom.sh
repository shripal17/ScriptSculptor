#!/bin/bash
#set -e

# we need to make a folder for the ROM first
mkdir voltageos

# Go to ROM folder.
cd voltageos

# Initialize VoltageOS Source

repo init -u https://github.com/VoltageOS/manifest.git -b 14 --git-lfs

# And to Sync it

repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

