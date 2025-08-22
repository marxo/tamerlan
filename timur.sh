#!/bin/bash

# URL of the file to download
FILE_URL="https://github.com/marxo/tamerlan/raw/refs/heads/main/app-release.apk"
# Local filename extracted from URL
FILE_NAME=$(basename "$FILE_URL")

# Check if adb is installed
if ! command -v adb &> /dev/null; then
    echo "Error: adb is not installed. Please install it first."
    exit 1
fi

echo "adb is installed."

# Download the file using wget if available, otherwise curl
if command -v wget &> /dev/null; then
    echo "Downloading $FILE_URL using wget..."
    wget -O "$FILE_NAME" "$FILE_URL"
elif command -v curl &> /dev/null; then
    echo "Downloading $FILE_URL using curl..."
    curl -o "$FILE_NAME" "$FILE_URL"
else
    echo "Error: Neither wget nor curl is available for downloading files."
    exit 1
fi

# Check if the download succeeded
if [ ! -f "$FILE_NAME" ]; then
    echo "Error: File download failed."
    exit 1
fi

echo "Download complete: $FILE_NAME"

# Install the APK using adb
echo "Installing $FILE_NAME via adb..."
adb install -r "$FILE_NAME"

# Check if adb install succeeded
if [ $? -eq 0 ]; then
    echo "Installation successful."
else
    echo "Installation failed."
    exit 1
fi
