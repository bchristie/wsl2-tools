#!/bin/bash
# Sudo NOPASSWD Toggle Script
#
# Add sudo_toggle.sh - Toggle passwordless sudo for current user
#
# This script provides a simple way to enable/disable NOPASSWD sudo
# privileges for the current user in WSL2. It checks for the existence
# of a sudoers configuration file in /etc/sudoers.d/ and toggles the
# setting accordingly:
#
# - If passwordless sudo is enabled, it disables it (requires password)
# - If passwordless sudo is disabled, it enables it (no password required)
#
# The script uses a toggle mechanism for convenience and follows sudo
# best practices by writing to /etc/sudoers.d/ with proper permissions.
#
# Passwordless sudo is particularly useful in WSL2 environments for
# automation scripts, development workflows, and CI/CD pipelines where
# repeated password prompts would interrupt the flow. It's helpful when
# running Docker commands, mounting drives, or managing services during
# development, while still allowing quick toggle back to secure mode
# when not actively developing.
#
# Place this script in your home directory (~/) and run it with:
# $ source ~/sudo_toggle.sh
# Also don't forget to allow execution:
# $ chmod +x ~/sudo_toggle.sh

# --- Configuration ---
# 1. Determine the current user (this is the user who will be affected)
CURRENT_USER=$(whoami)

# 2. Define the path to the configuration file created previously.
# This file governs NOPASSWD privileges for the CURRENT_USER.
# We use the /etc/sudoers.d/ directory to avoid directly editing /etc/sudoers.
SUDO_CONFIG_FILE="/etc/sudoers.d/90-nopasswd-$CURRENT_USER"

# --- Functions ---

# Function to enable passwordless sudo
enable_nopasswd() {
    echo "--- 🔒 Enabling Passwordless Sudo (NOPASSWD) for $CURRENT_USER ---"
    
    # This command requires 'sudo' permission to write to /etc/sudoers.d/
    # You will be prompted for your password here if the sudo cache has expired.
    COMMAND="$CURRENT_USER ALL=(ALL:ALL) NOPASSWD: ALL"
    
    # Use tee to write the configuration to the protected file
    if echo "$COMMAND" | sudo tee "$SUDO_CONFIG_FILE" > /dev/null; then
        # Set restrictive permissions (root-only read/write) as is standard for sudoers files
        sudo chmod 0440 "$SUDO_CONFIG_FILE"
        echo "✅ SUCCESS: Passwordless sudo is now ENABLED for $CURRENT_USER."
        echo "   You will NOT be prompted for a password when using 'sudo'."
    else
        echo "❌ ERROR: Failed to create the NOPASSWD configuration file."
        echo "   (Did the sudo command fail? Check permissions.)"
    fi
}

# Function to disable passwordless sudo
disable_nopasswd() {
    echo "--- 🔑 Disabling Passwordless Sudo (Require Password) for $CURRENT_USER ---"
    
    # This command requires 'sudo' permission to delete the file in /etc/sudoers.d/
    # You will be prompted for your password here if the sudo cache has expired.
    if sudo rm "$SUDO_CONFIG_FILE"; then
        echo "✅ SUCCESS: Passwordless sudo is now DISABLED for $CURRENT_USER."
        echo "   You WILL be prompted for a password when using 'sudo'."
    else
        echo "❌ ERROR: Failed to delete the configuration file."
        echo "   (Did the sudo command fail? Check permissions.)"
    fi
}

# --- Main Logic ---

if [ -f "$SUDO_CONFIG_FILE" ]; then
    # The file exists, so passwordless sudo is currently active.
    disable_nopasswd
else
    # The file does not exist, so passwordless sudo is currently inactive (or not configured this way).
    enable_nopasswd
fi

# --- End of Script ---