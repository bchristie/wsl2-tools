#!/bin/bash
# WSL2 Memory Reclaim Script
#
# Forces WSL2 to release cached memory back to Windows. WSL2 can consume
# significant memory over time and may not release it automatically.
#
# Features:
# - Shows current memory usage before and after
# - Drops Linux caches (page cache, dentries, inodes)
# - Compacts memory to release fragmented pages
# - Useful when WSL is consuming excessive memory
#
# WSL2 memory management:
# WSL2 uses a virtual machine that dynamically allocates memory but may not
# release it back to Windows automatically. This script forces Linux to drop
# caches and compact memory, which can free up several GB of RAM.
#
# Useful when:
# - WSL2 is consuming too much memory according to Task Manager
# - You need to free up RAM for Windows applications
# - Running memory-intensive operations that created large caches
# - Before suspending/hibernating your system
#
# Usage:
# $ ./memory_reclaim.sh
# $ chmod +x ~/memory_reclaim.sh

echo "--- 💾 WSL2 Memory Reclaim Script ---"
echo ""

# --- Show memory before ---
echo "📊 Memory Usage BEFORE:"
free -h
echo ""

# Get memory values for comparison
MEM_BEFORE=$(free -m | awk 'NR==2{print $3}')

echo "--- 🧹 Reclaiming Memory ---"
echo ""

# Sync to ensure all data is written to disk
echo "1. Syncing filesystems..."
sync

# Drop page cache
echo "2. Dropping page cache..."
echo 1 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# Drop dentries and inodes
echo "3. Dropping dentries and inodes..."
echo 2 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# Drop page cache, dentries and inodes
echo "4. Dropping all caches..."
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# Compact memory
echo "5. Compacting memory..."
echo 1 | sudo tee /proc/sys/vm/compact_memory > /dev/null 2>&1

echo ""
echo "✅ Cache clearing complete"
echo ""

# Small delay to let system stabilize
sleep 1

# --- Show memory after ---
echo "📊 Memory Usage AFTER:"
free -h
echo ""

# Calculate memory freed
MEM_AFTER=$(free -m | awk 'NR==2{print $3}')
MEM_FREED=$((MEM_BEFORE - MEM_AFTER))

if [ $MEM_FREED -gt 0 ]; then
    echo "✅ Freed approximately ${MEM_FREED}MB of memory"
else
    echo "ℹ️  Memory usage similar (caches may have been small)"
fi

echo ""
echo "--- 💡 Additional Tips ---"
echo ""
echo "To limit WSL2 memory usage permanently:"
echo "  1. Create/edit: %USERPROFILE%\\.wslconfig (in Windows)"
echo "  2. Add the following:"
echo ""
echo "     [wsl2]"
echo "     memory=4GB"
echo "     swap=2GB"
echo ""
echo "  3. Restart WSL: wsl --shutdown (from PowerShell)"
echo ""
echo "To see WSL memory usage from Windows:"
echo "  - Task Manager > Performance > Memory"
echo "  - Look for 'Vmmem' process"
echo ""
echo "This script can be run periodically or added to a cron job."
