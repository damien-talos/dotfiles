#!/bin/sh

# First, attempt to create the lock directory, which ensures that this script only runs once
if mkdir /tmp/ramdisk.lock 2>/dev/null; then
    echo "Creating RAM disk..."
    [ -d '/Volumes/RAMDisk' ] || hdiutil attach -nomount ram://16777216 | xargs diskutil erasevolume HFS+ "RAMDisk"
else
    echo "RAM disk lock already exists, skipping..."
    exit 0
fi
