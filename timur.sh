#!/bin/bash

# URL of the APK to download
FILE_URL="https://raw.githubusercontent.com/marxo/tamerlan/raw/refs/heads/main/app-release.apk"
FILE_NAME=$(basename "$FILE_URL")

# Check if adb is installed
if ! command -v adb &> /dev/null; then
    echo "Error: adb is not installed. Please install it first."
    exit 1
fi

echo "adb is installed."

# Check for connected devices
echo "Checking for connected devices..."
devices=$(adb devices | awk 'NR>1 && $2=="device"{print $1}')

# Wait for devices if none are found
while [ -z "$devices" ]; do
    echo "No devices detected. Waiting for a device to be connected..."
    sleep 5
    devices=$(adb devices | awk 'NR>1 && $2=="device"{print $1}')
done

# If multiple devices, let user pick
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

# Download APK
if command -v wget &> /dev/null; then
    echo "Downloading $FILE_URL using wget..."
    wget -O "$FILE_NAME" "$FILE_URL"
elif command -v curl &> /dev/null; then
    echo "Downloading $FILE_URL using curl..."
    curl -o "$FILE_NAME" "$FILE_URL"
else
    echo "Error: Neither wget nor curl is available."
    exit 1
fi

# Verify download
if [ ! -f "$FILE_NAME" ]; then
    echo "Error: Download failed."
    exit 1
fi

echo "Download complete: $FILE_NAME"

# Install APK
echo "Installing $FILE_NAME on device $device..."
adb -s "$device" install -r "$FILE_NAME"

if [ $? -eq 0 ]; then
    echo "Installation successful."
else
    echo "Installation failed."
    exit 1
fi
