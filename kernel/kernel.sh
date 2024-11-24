#!/bin/bash
#set -e
#Replace links accordingly

# Initialize Toolchains
echo -e "$green Checking for GCC directories... $white"
if [ -d "$PWD/gcc64" ] && [ -d "$PWD/gcc32" ]; then
    echo -e "$green GCC directories already exist. Skipping clone. $white"
else
    echo -e "$green Cloning GCC toolchains... $white"
    git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 "$PWD"/gcc64
    git clone --depth=1 https://github.com/mvaisakh/gcc-arm "$PWD"/gcc32
    echo -e "$green GCC toolchains cloned successfully. $white"
fi

# Initialize Clang
echo -e "$green Checking for Clang directory... $white"
if [ -d "$PWD/clang" ]; then
    echo -e "$green Clang directory already exists. Skipping clone. $white"
else
    echo -e "$green Cloning Clang... $white"
    git clone --depth=1 https://gitlab.com/SwapnilVicky/clang-r450784d "$PWD"/clang
    echo -e "$green Clang cloned successfully. $white"
fi

# Initialize Kernel
echo -e "$green Checking for Kernel directory... $white"
if [ -d "kernel_phoenix" ]; then
    echo -e "$green Kernel directory 'kernel_phoenix' already exists. Skipping clone. $white"
else
    echo -e "$green Cloning Kernel repository... $white"
    git clone https://github.com/narikootam-dev/kernel_xiaomi_msm4.14 -b 15 kernel
    echo -e "$green Kernel repository cloned successfully. $white"
fi

# Begin kernel compilation
cd kernel_phoenix
KERNEL_DEFCONFIG=phoenix_defconfig
date=$(date +"%Y-%m-%d-%H%M")
export ARCH=arm64
export SUBARCH=arm64
export zipname="Pure-phoenix-${date}.zip"
export PATH="$PWD/gcc64/bin:$PWD/gcc32/bin:$PATH"
export STRIP="$PWD/gcc64/aarch64-elf/bin/strip"
export KBUILD_COMPILER_STRING=$($PWD/gcc64/bin/aarch64-elf-gcc --version | head -n 1)
export PATH="$PWD/clang/bin:$PATH"
export KBUILD_COMPILER_STRING=$($PWD/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

# Notify Telegram about the start of compilation
echo "Kernel compilation started for device 'Phoenix'."
COMMIT=$(git log --pretty=format:"%s" -5)
echo "<b>Recent Changelogs:</b>%0A$COMMIT"

# Speed up build process
MAKE="./makeparallel"
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo "**** Kernel defconfig set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          STARTING KERNEL BUILD          "
echo -e "***********************************************$nocol"
make $KERNEL_DEFCONFIG O=out CC=clang
make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              LLVM=1 \
                              LLVM_IAS=1 \
                              AR=llvm-ar \
                              NM=llvm-nm \
                              LD=ld.lld \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              STRIP=llvm-strip \
                              CC=clang \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi-  2>&1 |& tee error.log

echo -e "$blue-------------- KERNEL BUILD COMPLETED -----------"

# Check if build was successful
export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz
export dtbo="$MY_DIR"/out/arch/arm64/boot/dtbo.img
export dtb="$MY_DIR"/out/arch/arm64/boot/dtb.img

find out/arch/arm64/boot/dts/ -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb
if [ -f "out/arch/arm64/boot/Image.gz" ] && [ -f "out/arch/arm64/boot/dtbo.img" ] && [ -f "out/arch/arm64/boot/dtb" ]; then
    git clone -q https://github.com/shripal17/AnyKernel3
    cp out/arch/arm64/boot/Image.gz AnyKernel3
    cp out/arch/arm64/boot/dtb AnyKernel3
    cp out/arch/arm64/boot/dtbo.img AnyKernel3
    rm -f *zip
    cd AnyKernel3
    sed -i "s/is_slot_device=0/is_slot_device=auto/g" anykernel.sh
    zip -r9 "../${zipname}" * -x '*.git*' README.md *placeholder >> /dev/null
    cd ..
    rm -rf AnyKernel3
    echo -e "Build completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)!"
    echo ""
    echo -e "Kernel package '${zipname}' is ready!"
    echo ""
    rm -rf out
    rm -rf error.log
    #rm -rf ${zipname}
else
    echo "Kernel build failed."
    echo "error.log" 
fi
