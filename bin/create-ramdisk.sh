#!/bin/sh

# First, attempt to create the lock file, which ensures that this script only runs once
if { set -C; 2>/dev/null >/tmp/ramdisk.lock; }; then
    trap "rm -f /tmp/ramdisk.lock" EXIT
    echo "Creating RAM disk..."
    [ -d '/Volumes/RAMDisk' ] || hdiutil attach -nomount ram://16777216 | xargs diskutil erasevolume HFS+ "RAMDisk"
 else
    echo "RAM disk lock already exists, skipping..."
    exit 0
 fi
