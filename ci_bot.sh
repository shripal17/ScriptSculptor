#!/bin/bash

# Build Configuration: Variables for compiling the ROM
CONFIG_BREAKFAST="voltage_sweet-ap3a-userdebug"
CONFIG_OFFICIAL_FLAG="1"
CONFIG_TARGET="bacon"

# Telegram Configuration
CONFIG_CHATID=""
CONFIG_BOT_TOKEN=""
CONFIG_ERROR_CHATID=""

# PixelDrain API Key for uploading builds
CONFIG_PDUP_API=""

# Shutdown server after build
POWEROFF="false"

# Script Constants
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)
BOLD_GREEN=${BOLD}$(tput setaf 2)
ROOT_DIRECTORY="$(pwd)"
DEVICE="$(sed -e "s/^.*_//" -e "s/-.*//" <<<"$CONFIG_BREAKFAST")"
ROM_NAME="$(basename $(pwd))"
OUT="$(pwd)/out/target/product/$DEVICE"
STICKER_URL="https://raw.githubusercontent.com/Weebo354342432/reimagined-enigma/main/update.webp"

# CLI Parameters: Parse user inputs
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--sync) SYNC="1" ;;
        -c|--clean) CLEAN="1" ;;
        -o|--official)
            if [ -n "$CONFIG_OFFICIAL_FLAG" ]; then
                OFFICIAL="1"
            else
                echo -e "${YELLOW}ERROR: Please specify the official flag in the configuration.${RESET}\n"
                exit 1
            fi ;;
        -h|--help)
            echo -e "\nUsage: ./build_rom.sh [OPTIONS]
Options:
    -s, --sync       Sync sources before building
    -c, --clean      Clean build directory before compilation
    -o, --official   Build official variant\n"
            exit 0 ;;
        *)
            echo -e "${YELLOW}Unknown option: $1${RESET}\n"
            exit 1 ;;
    esac
    shift
done

# Configuration Validation
if [[ -z "$CONFIG_BREAKFAST" || -z "$CONFIG_TARGET" ]]; then
    echo -e "${YELLOW}ERROR: Missing mandatory variables in configuration.${RESET}\n"
    exit 1
fi

# Telegram Environment
BOT_MESSAGE_URL="https://api.telegram.org/bot$CONFIG_BOT_TOKEN/sendMessage"
BOT_FILE_URL="https://api.telegram.org/bot$CONFIG_BOT_TOKEN/sendDocument"
send_message() {
    local MESSAGE_ID=$(curl -s "$BOT_MESSAGE_URL" -d chat_id="$2" -d "parse_mode=html" -d text="$1" | jq '.result.message_id')
    echo "$MESSAGE_ID"
}
send_file() {
    curl -s -F document=@"$1" "$BOT_FILE_URL" -F chat_id="$2" -F "parse_mode=html"
}

# Cleanup Previous Logs
rm -f "out/error.log" "out/.lock" "$ROOT_DIRECTORY/build.log"

# Job Configuration: Set number of cores to use
CORE_COUNT=$(nproc --all)
CONFIG_SYNC_JOBS="$([ "$CORE_COUNT" -gt 8 ] && echo "12" || echo "$CORE_COUNT")"
CONFIG_COMPILE_JOBS="$CORE_COUNT"

# Sync Sources if specified
if [[ -n $SYNC ]]; then
    sync_start_message="🟡 | Syncing sources... ROM: $ROM_NAME, Device: $DEVICE, Cores: $CONFIG_SYNC_JOBS"
    sync_message_id=$(send_message "$sync_start_message" "$CONFIG_CHATID")

    SYNC_START=$(date +"%s")
    if repo sync -c -j$CONFIG_SYNC_JOBS --force-sync --no-clone-bundle --no-tags; then
        SYNC_END=$(date +"%s")
        DIFF=$((SYNC_END - SYNC_START))
        sync_finished_message="🟢 | Sync completed in $((DIFF / 60)) min and $((DIFF % 60)) sec."
        send_message "$sync_finished_message" "$CONFIG_CHATID"
    else
        echo "Sync failed, proceeding with build."
    fi
fi

# Clean Build Directory if specified
if [[ -n $CLEAN ]]; then
    echo -e "${BOLD_GREEN}Cleaning build directory...${RESET}\n"
    rm -rf "out"
fi

# Send notification for build start
build_start_message="🟡 | Building ROM... ROM: $ROM_NAME, Device: $DEVICE, Type: $([ "$OFFICIAL" == "1" ] && echo "Official" || echo "Unofficial")"
build_message_id=$(send_message "$build_start_message" "$CONFIG_CHATID")

BUILD_START=$(date +"%s")

# Initialize build environment
source build/envsetup.sh
breakfast "$CONFIG_BREAKFAST"

if [ $? -eq 0 ]; then
    m installclean -j$CONFIG_COMPILE_JOBS
    m "$CONFIG_TARGET" -j$CONFIG_COMPILE_JOBS 2>&1 | tee -a "$ROOT_DIRECTORY/build.log" &
else
    send_message "🔴 | Failed at breakfast stage." "$CONFIG_CHATID"
    exit 1
fi

# Monitor build progress
until [ -z "$(jobs -r)" ]; do
    progress=$(tail -n 20 "$ROOT_DIRECTORY/build.log" | grep -o '[0-9]*%')
    send_message "🟡 | Build Progress: $progress" "$CONFIG_CHATID"
    sleep 5
done

# Upload build files
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

if [ -s "out/error.log" ]; then
    send_message "🔴 | Build failed, see log." "$CONFIG_ERROR_CHATID"
    send_file "out/error.log" "$CONFIG_ERROR_CHATID"
else
    zip_file=$(ls "$OUT"/*$DEVICE*.zip | tail -n 1)
    recovery_file=$(ls "$OUT"/recovery.img | tail -n 1)

    zip_url=$(curl -T "$zip_file" -u :"$CONFIG_PDUP_API" "https://pixeldrain.com/api/file/" | jq -r '.url')
    recovery_url=$(curl -T "$recovery_file" -u :"$CONFIG_PDUP_API" "https://pixeldrain.com/api/file/" | jq -r '.url')

    build_finished_message="🟢 | Build completed in $((DIFF / 3600)) hr $(((DIFF / 60) % 60)) min. Download: $zip_url, Recovery: $recovery_url"
    send_message "$build_finished_message" "$CONFIG_CHATID"
fi

if [[ $POWEROFF == "true" ]]; then
    echo "Powering off server..."
    sudo poweroff
fi
