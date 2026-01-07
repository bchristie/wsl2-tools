#!/bin/bash
# PostgreSQL Database Backup Script
#
# Creates a compressed backup of a specified PostgreSQL database using pg_dump.
# Backups are timestamped and saved to a specified directory.
#
# Features:
# - Creates compressed SQL dumps of databases
# - Automatically timestamps backup files
# - Configurable backup directory
# - Validates database exists before backup
# - Useful for quick backups before major changes or regular backup routines
#
# Usage:
# $ ./pg_backup.sh <database_name> [backup_directory]
# $ chmod +x ~/pg_backup.sh

# --- Configuration ---
DB_NAME="$1"
BACKUP_DIR="${2:-$HOME/pg_backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"

# --- Validation ---
if [ -z "$DB_NAME" ]; then
    echo "❌ ERROR: Database name is required."
    echo "Usage: $0 <database_name> [backup_directory]"
    exit 1
fi

# Check if PostgreSQL is installed
if ! command -v pg_dump &> /dev/null; then
    echo "❌ ERROR: PostgreSQL (pg_dump) is not installed or not in PATH."
    exit 1
fi

# Check if PostgreSQL service is running
if ! sudo service postgresql status &> /dev/null; then
    echo "❌ ERROR: PostgreSQL service is not running."
    echo "Start it with: sudo service postgresql start"
    exit 1
fi

# Check if database exists
DB_EXISTS=$(sudo -u postgres psql -t -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" | xargs)
if [ "$DB_EXISTS" != "1" ]; then
    echo "❌ ERROR: Database '$DB_NAME' does not exist."
    echo ""
    echo "Available databases:"
    sudo -u postgres psql -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1') ORDER BY datname;"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "--- 🐘 PostgreSQL Database Backup ---"
echo "Database:    $DB_NAME"
echo "Backup File: $BACKUP_FILE"
echo ""
echo "Creating backup..."

# Perform backup
sudo -u postgres pg_dump "$DB_NAME" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ] && [ -f "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo ""
    echo "✅ SUCCESS: Backup created successfully"
    echo "   File: $BACKUP_FILE"
    echo "   Size: $BACKUP_SIZE"
    echo ""
    echo "--- 📋 Restore Instructions ---"
    echo "To restore this backup:"
    echo "  gunzip -c $BACKUP_FILE | sudo -u postgres psql $DB_NAME"
    echo ""
    echo "To restore to a new database:"
    echo "  sudo -u postgres createdb new_database_name"
    echo "  gunzip -c $BACKUP_FILE | sudo -u postgres psql new_database_name"
else
    echo "❌ ERROR: Backup failed."
    exit 1
fi
