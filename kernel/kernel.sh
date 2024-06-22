
#!/bin/bash
#set -e
#Replace links accordingly

TG_CHAT="chat_token" 
TG_BOT="bot_token"
tg_post_msg() {
    curl -s -X POST "https://api.telegram.org/bot$TG_BOT/sendMessage" \
    -d chat_id="$TG_CHAT" \
    -d "disable_web_page_preview=true" \
    -d "parse_mode=html" \
    -d text="$1"
}

tg_post_doc() {
    curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot$TG_BOT/sendDocument" \
    -F chat_id="$TG_CHAT"  \
    -F "disable_web_page_preview=true" \
    -F "parse_mode=html" \
    -F caption="$2"
}

#Initializing the script
# Tool Chain
echo -e "$green << cloning gcc >> \n $white"
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 "$HOME"/gcc64
git clone --depth=1 https://github.com/mvaisakh/gcc-arm "$HOME"/gcc32
echo -e "$green << cloned gcc successfully >> \n $white"

# Clang
echo -e "$green << cloning clang >> \n $white"
git clone -b 14 --depth=1  https://bitbucket.org/shuttercat/clang  "$HOME"/clang
echo -e "$green << cloned  clang successfully >> \n $white"

# Kernel
git clone https://github.com/narikootam-dev/kernel_xiaomi_msm4.14 -b meraki meraki

# Lets start
cd meraki
KERNEL_DEFCONFIG=vendor/sweet_user_defconfig
date=$(date +"%Y-%m-%d-%H%M")
export ARCH=arm64
export SUBARCH=arm64
export zipname="MerakiKernel-sweet-${date}.zip"
export PATH="$HOME/gcc64/bin:$HOME/gcc32/bin:$PATH"
export STRIP="$HOME/gcc64/aarch64-elf/bin/strip"
export KBUILD_COMPILER_STRING=$("$HOME"/gcc64/bin/aarch64-elf-gcc --version | head -n 1)
export PATH="$HOME/clang/bin:$PATH"
export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

# show out
tg_post_msg "Kernel Compiling Started for Sweet !!"
COMMIT=$(git log --pretty=format:"%s" -5)
tg_post_msg "<b>Changelogs</b>%0A$COMMIT"

# Speed up build process
MAKE="./makeparallel"
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
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
                              
                                                          
export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz
export dtbo="$MY_DIR"/out/arch/arm64/boot/dtbo.img
export dtb="$MY_DIR"/out/arch/arm64/boot/dtb.img

find out/arch/arm64/boot/dts/ -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb
if [ -f "out/arch/arm64/boot/Image.gz" ] && [ -f "out/arch/arm64/boot/dtbo.img" ] && [ -f "out/arch/arm64/boot/dtb" ]; then
	git clone -q https://github.com/narikootam-dev/AnyKernel3
	cp out/arch/arm64/boot/Image.gz AnyKernel3
	cp out/arch/arm64/boot/dtb AnyKernel3
	cp out/arch/arm64/boot/dtbo.img AnyKernel3
	rm -f *zip
	cd AnyKernel3
	sed -i "s/is_slot_device=0/is_slot_device=auto/g" anykernel.sh
	zip -r9 "../${zipname}" * -x '*.git*' README.md *placeholder >> /dev/null
	cd ..
	rm -rf AnyKernel3
	echo -e "Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	tg_post_msg "Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo ""
	echo -e ${zipname} " is ready!"
	echo ""
	tg_post_msg "${zipname} is ready!!!!"
	rm -rf out
	rm -rf error.log
	tg_post_doc "${zipname}"
	rm -rf ${zipname}
	
else
 tg_post_msg "Build Failed"
 tg_post_doc "error.log" 
fi
