#!/bin/bash
#set -e
cd meraki
export ARCH=arm64 
make vendor/sweet_user_defconfig
mv .config arch/arm64/configs/vendor/sweet_user_defconfig
echo -e "$green << regenerated sweet_user_defconfig >> \n $white"
