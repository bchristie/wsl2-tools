#!/bin/bash
# PostgreSQL Database Lister
#
# Lists all PostgreSQL databases with their owners and sizes, and optionally
# displays connection strings for non-system databases.
#
# Features:
# - Lists all databases with owner and size information
# - Filters out system databases (postgres, template0, template1)
# - Shows connection strings for user databases
# - Useful for quick overview of all database environments
#
# Usage:
# $ ./pg_list_dbs.sh
# $ ./pg_list_dbs.sh --with-connections
# $ chmod +x ~/pg_list_dbs.sh

# --- Configuration ---
SHOW_CONNECTIONS=false

if [ "$1" == "--with-connections" ] || [ "$1" == "-c" ]; then
    SHOW_CONNECTIONS=true
fi

# --- Validation ---
# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ ERROR: PostgreSQL (psql) is not installed or not in PATH."
    exit 1
fi

# Check if PostgreSQL service is running
if ! sudo service postgresql status &> /dev/null; then
    echo "❌ ERROR: PostgreSQL service is not running."
    echo "Start it with: sudo service postgresql start"
    exit 1
fi

echo "--- 🐘 PostgreSQL Databases ---"
echo ""

# Get list of databases with details
sudo -u postgres psql -t -c "
SELECT 
    d.datname as database,
    pg_catalog.pg_get_userbyid(d.datdba) as owner,
    pg_size_pretty(pg_database_size(d.datname)) as size
FROM pg_catalog.pg_database d
WHERE d.datname NOT IN ('postgres', 'template0', 'template1')
ORDER BY d.datname;
" | while IFS='|' read -r dbname owner size; do
    # Trim whitespace
    dbname=$(echo "$dbname" | xargs)
    owner=$(echo "$owner" | xargs)
    size=$(echo "$size" | xargs)
    
    if [ -n "$dbname" ]; then
        echo "📊 Database: $dbname"
        echo "   Owner:    $owner"
        echo "   Size:     $size"
        
        if [ "$SHOW_CONNECTIONS" == true ]; then
            echo "   URI:      postgresql://$owner:PASSWORD@localhost:5432/$dbname"
        fi
        echo ""
    fi
done

# Count total databases
TOTAL=$(sudo -u postgres psql -t -c "SELECT COUNT(*) FROM pg_catalog.pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1');" | xargs)

echo "Total user databases: $TOTAL"
echo ""

if [ "$SHOW_CONNECTIONS" == false ]; then
    echo "💡 Tip: Use --with-connections to show connection URIs"
fi
