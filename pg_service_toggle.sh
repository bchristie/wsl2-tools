#!/bin/bash
# PostgreSQL Service Toggle Script
#
# Toggles the PostgreSQL service on/off in WSL2. This is useful for managing
# system resources when you're not actively developing with PostgreSQL.
#
# Features:
# - Checks current PostgreSQL service status
# - Starts the service if stopped
# - Stops the service if running
# - Displays service status after toggle
# - Helps conserve system resources in WSL2 when database is not needed
#
# Usage:
# $ ./pg_service_toggle.sh
# $ chmod +x ~/pg_service_toggle.sh

# --- Validation ---
# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ ERROR: PostgreSQL is not installed or not in PATH."
    echo "Install it with: sudo apt-get install postgresql postgresql-contrib"
    exit 1
fi

# --- Functions ---

# Function to start PostgreSQL service
start_postgres() {
    echo "--- 🐘 Starting PostgreSQL Service ---"
    sudo service postgresql start
    
    if [ $? -eq 0 ]; then
        sleep 1
        echo "✅ SUCCESS: PostgreSQL service is now RUNNING"
        show_status
    else
        echo "❌ ERROR: Failed to start PostgreSQL service"
        exit 1
    fi
}

# Function to stop PostgreSQL service
stop_postgres() {
    echo "--- 🛑 Stopping PostgreSQL Service ---"
    sudo service postgresql stop
    
    if [ $? -eq 0 ]; then
        echo "✅ SUCCESS: PostgreSQL service is now STOPPED"
    else
        echo "❌ ERROR: Failed to stop PostgreSQL service"
        exit 1
    fi
}

# Function to show service status
show_status() {
    STATUS=$(sudo service postgresql status 2>&1)
    
    if echo "$STATUS" | grep -q "online"; then
        echo "   Status: ✅ Running"
        
        # Get PostgreSQL version
        VERSION=$(sudo -u postgres psql -t -c "SELECT version();" 2>/dev/null | head -n1 | xargs)
        if [ -n "$VERSION" ]; then
            echo "   Version: $(echo $VERSION | cut -d',' -f1)"
        fi
        
        # Count databases
        DB_COUNT=$(sudo -u postgres psql -t -c "SELECT COUNT(*) FROM pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1');" 2>/dev/null | xargs)
        if [ -n "$DB_COUNT" ]; then
            echo "   Databases: $DB_COUNT user database(s)"
        fi
    else
        echo "   Status: 🔴 Stopped"
    fi
}

# --- Main Logic ---

echo ""

# Check current status and toggle
if sudo service postgresql status &> /dev/null; then
    # Service is running, so stop it
    stop_postgres
else
    # Service is stopped, so start it
    start_postgres
fi

echo ""
