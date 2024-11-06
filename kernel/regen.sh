#!/bin/bash

# Color definitions for easy customization
green='\033[0;32m'
white='\033[0m'

# Function to regenerate the sweet_user_defconfig
regenerate_config() {
    local target_folder="$1"

    # Check if the target folder exists
    if [ ! -d "$target_folder" ]; then
        echo -e "$green << Error: Folder '$target_folder' does not exist! >> $white"
        exit 1
    fi

    # Change to the specified directory
    cd "$target_folder" || { echo -e "$green << Failed to change directory to '$target_folder' >> $white"; exit 1; }

    # Set architecture and regenerate config
    export ARCH=arm64
    make vendor/sweet_user_defconfig
    mv .config arch/arm64/configs/vendor/sweet_user_defconfig

    # Print success message
    echo -e "$green << regenerated sweet_user_defconfig in '$target_folder' >> $white"
}

# Check if folder argument is provided
if [ $# -eq 0 ]; then
    # No argument provided, default to 'kernel' folder
    echo -e "$green << No folder specified, using default 'kernel' folder >> $white"
    regenerate_config "kernel"
elif [ "$1" == "kernelsu" ]; then
    # Use 'kernelsu' folder if specified
    echo -e "$green << Using 'kernelsu' folder >> $white"
    regenerate_config "kernelsu"
else
    # Invalid folder argument
    echo -e "$green << Error: Invalid folder specified. Use 'kernel' or 'kernelsu'. >> $white"
    exit 1
fi
