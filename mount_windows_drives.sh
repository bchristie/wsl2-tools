#!/bin/bash
# Custom Windows Drive Mount Script
#
# Mounts Windows drives in WSL2 with custom mount points and specific
# permissions. By default, WSL mounts Windows drives at /mnt/c, /mnt/d, etc.,
# but you may want different locations or permissions.
#
# Features:
# - Mounts Windows drives with custom paths
# - Sets specific file permissions (useful for executable scripts)
# - Configures metadata support for better file attribute handling
# - Can remount existing drives with different options
# - Useful for development environments requiring specific permissions
#
# Why custom mounts?
# - Default /mnt/c may have wrong permissions for scripts or SSH keys
# - You may want drives mounted at /c, /d for shorter paths
# - Need case-sensitive file system support
# - Want to enable metadata for chmod/chown to work properly
#
# Usage:
# $ ./mount_windows_drives.sh
# $ ./mount_windows_drives.sh --remount
# $ chmod +x ~/mount_windows_drives.sh

# --- Configuration ---
REMOUNT=false

if [ "$1" == "--remount" ]; then
    REMOUNT=true
fi

echo "--- 💿 Windows Drive Mount Manager ---"
echo ""

# --- Functions ---

mount_drive() {
    local drive_letter=$1
    local mount_point=$2
    local mount_options=$3
    
    # Convert to lowercase for Windows drive
    local win_drive=$(echo "$drive_letter" | tr '[:upper:]' '[:lower:]')
    
    echo "Mounting Windows $drive_letter: drive..."
    
    # Create mount point if it doesn't exist
    if [ ! -d "$mount_point" ]; then
        sudo mkdir -p "$mount_point"
    fi
    
    # Check if already mounted
    if mountpoint -q "$mount_point"; then
        if [ "$REMOUNT" == true ]; then
            echo "  Unmounting existing mount at $mount_point..."
            sudo umount "$mount_point"
        else
            echo "  ⚠️  Already mounted at $mount_point (use --remount to remount)"
            return 0
        fi
    fi
    
    # Mount the drive
    if sudo mount -t drvfs "$drive_letter:" "$mount_point" -o "$mount_options"; then
        echo "  ✅ Mounted at $mount_point"
        return 0
    else
        echo "  ❌ Failed to mount"
        return 1
    fi
}

# --- Main Logic ---

echo "Current Windows drive mounts:"
mount | grep drvfs
echo ""

# --- Mount Configuration ---
# Customize these to your preferences

echo "--- 🔧 Configuring Custom Mounts ---"
echo ""

# Common mount options:
# metadata - Enable metadata support (chmod, chown work properly)
# uid=1000,gid=1000 - Set default user/group
# umask=22 - Default permissions (755 for dirs, 644 for files)
# fmask=111 - File mask (removes execute bits)
# case=off - Case insensitive (Windows default)
# case=dir - Case sensitive for new files

# Default options for most drives
DEFAULT_OPTIONS="metadata,uid=1000,gid=1000,umask=22,fmask=111"

# Options for drives with scripts/executables
EXEC_OPTIONS="metadata,uid=1000,gid=1000,umask=22"

echo "Select mounting configuration:"
echo "1) Default WSL mounts (/mnt/c, /mnt/d, etc.) - No changes needed"
echo "2) Short paths (/c, /d, etc.) with default permissions"
echo "3) Short paths with executable permissions"
echo "4) Custom configuration"
echo ""
read -p "Enter choice (1-4) [default: 1]: " MOUNT_CHOICE
MOUNT_CHOICE=${MOUNT_CHOICE:-1}

case $MOUNT_CHOICE in
    1)
        echo ""
        echo "✅ Using default WSL mounts at /mnt/*"
        echo "No changes needed. Drives are already mounted."
        echo ""
        echo "Current mounts:"
        df -h | grep drvfs
        ;;
        
    2)
        echo ""
        echo "Creating short path mounts with default permissions..."
        echo ""
        mount_drive "C" "/c" "$DEFAULT_OPTIONS"
        mount_drive "D" "/d" "$DEFAULT_OPTIONS"
        # Add more drives as needed
        # mount_drive "E" "/e" "$DEFAULT_OPTIONS"
        ;;
        
    3)
        echo ""
        echo "Creating short path mounts with executable permissions..."
        echo ""
        mount_drive "C" "/c" "$EXEC_OPTIONS"
        mount_drive "D" "/d" "$EXEC_OPTIONS"
        # Add more drives as needed
        ;;
        
    4)
        echo ""
        echo "Custom configuration:"
        read -p "Enter drive letter (e.g., C): " CUSTOM_DRIVE
        read -p "Enter mount point (e.g., /mnt/custom): " CUSTOM_MOUNT
        read -p "Enter mount options (or press Enter for default): " CUSTOM_OPTIONS
        CUSTOM_OPTIONS=${CUSTOM_OPTIONS:-$DEFAULT_OPTIONS}
        
        echo ""
        mount_drive "$CUSTOM_DRIVE" "$CUSTOM_MOUNT" "$CUSTOM_OPTIONS"
        ;;
        
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "--- 📊 Current Mount Status ---"
df -h | grep -E "(Filesystem|drvfs)"

echo ""
echo "--- 💡 Tips ---"
echo ""
echo "To make custom mounts permanent:"
echo "  1. Edit /etc/fstab (requires sudo)"
echo "  2. Or add mount commands to ~/.bashrc"
echo ""
echo "Example fstab entry:"
echo "  C: /c drvfs $DEFAULT_OPTIONS 0 0"
echo ""
echo "To unmount a drive:"
echo "  sudo umount /c"
echo ""
echo "To remount all drives with this script:"
echo "  ./mount_windows_drives.sh --remount"
