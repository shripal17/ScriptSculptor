import os
import subprocess

# Function to run shell commands and handle errors
def run_command(command, shell=False):
    try:
        subprocess.run(command, shell=shell, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")

def clone_repo(url, path):
    if os.path.exists(path):
        print(f"Directory '{path}' already exists, skipping clone.")
    else:
        print(f"Cloning from {url} into '{path}'...")
        try:
            subprocess.run(["git", "clone", url, path], check=True)
            print(f"Successfully cloned '{path}'.")
        except subprocess.CalledProcessError:
            print(f"Failed to clone {url} into '{path}'.")

# Repository URLs and their respective clone paths
repos = {
    "device/xiaomi/sweet": "https://github.com/narikootam-dev/device_xiaomi_sweet",
    "vendor/xiaomi/sweet": "https://github.com/narikootam-dev/vendor_xiaomi_sweet",
    "kernel/xiaomi/sweet": "https://github.com/narikootam-dev/kernel_xiaomi_msm4.14",
    "vendor/xiaomi/sweet-miuicamera": "https://gitlab.com/mrfox2003/sweet-miuicamera",
    "hardware/dolby": "https://github.com/narikootam-dev/hardware_dolby",
    "hardware/xiaomi": "https://github.com/narikootam-dev/hardware_xiaomi"
}

# Clone each repository with status messages
for path, url in repos.items():
    clone_repo(url, path)

