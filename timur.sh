#!/bin/bash

# === CONFIG ===
BASE_URL="https://raw.githubusercontent.com/marxo/tamerlan/main"
APK_NAME="bi.apk"
SHA256_FILE="sha256sum.txt"
# ==============

# Defaults
VERSION="latest"
SKIP_SHA256=false

# === Parse flags ===
usage() {
    echo "Usage: $0 [-v version] [-s]"
    echo "  -v version   Specify version (default: latest)"
    echo "  -s           Skip sha256 checksum verification"
    exit 1
}

while getopts ":v:s" opt; do
  case $opt in
    v) VERSION="$OPTARG" ;;
    s) SKIP_SHA256=true ;;
    *) usage ;;
  esac
done

# Build URLs
if [ "$VERSION" = "latest" ]; then
    FILE_URL="$BASE_URL/$APK_NAME"
    SHA256_URL="$BASE_URL/$SHA256_FILE"
else
    FILE_URL="$BASE_URL/$VERSION/$APK_NAME"
    SHA256_URL="$BASE_URL/$VERSION/$SHA256_FILE"
fi

FILE_NAME=$(basename "$FILE_URL")

# === Check adb ===
if ! command -v adb &> /dev/null; then
    echo "Error: adb is not installed. Please install it first."
    exit 1
fi
echo "adb is installed."

# === Check for devices ===
echo "Checking for connected devices..."
devices=$(adb devices | awk 'NR>1 && $2=="device"{print $1}')

while [ -z "$devices" ]; do
    echo "No devices detected. Waiting for a device to be connected..."
    sleep 5
    devices=$(adb devices | awk 'NR>1 && $2=="device"{print $1}')
done

device_count=$(echo "$devices" | wc -l)
if [ "$device_count" -gt 1 ]; then
    echo "Multiple devices detected:"
    select chosen_device in $devices; do
        if [ -n "$chosen_device" ]; then
            device="$chosen_device"
            break
        else
            echo "Invalid selection. Try again."
        fi
    done
else
    device="$devices"
fi
echo "Using device: $device"

# === Download APK ===
if command -v wget &> /dev/null; then
    echo "Downloading $FILE_URL..."
    wget -O "$FILE_NAME" "$FILE_URL" || exit 1
    $SKIP_SHA256 || wget -O "$SHA256_FILE" "$SHA256_URL" || exit 1
elif command -v curl &> /dev/null; then
    echo "Downloading $FILE_URL..."
    curl -o "$FILE_NAME" "$FILE_URL" || exit 1
    $SKIP_SHA256 || curl -o "$SHA256_FILE" "$SHA256_URL" || exit 1
else
    echo "Error: Neither wget nor curl is available."
    exit 1
fi

# === Verify checksum ===
if [ "$SKIP_SHA256" = false ]; then
    echo "Verifying checksum for $FILE_NAME..."
    if ! grep " $FILE_NAME" "$SHA256_FILE" | sha256sum -c -; then
        echo "Error: SHA256 checksum verification failed!"
        rm -f "$FILE_NAME"
        exit 1
    fi
    echo "Checksum verified successfully."
else
    echo "Skipping checksum verification (user requested)."
fi

# === Install APK ===
echo "Installing $FILE_NAME on device $device..."
adb -s "$device" install -r "$FILE_NAME"

if [ $? -eq 0 ]; then
    echo "Installation successful."
else
    echo "Installation failed."
    exit 1
fi
