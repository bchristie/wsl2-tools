#!/bin/bash
# PostgreSQL Database Creator with User Management
#
# This script automates the creation of PostgreSQL databases with dedicated
# users and secure random passwords. It provides formatted connection strings
# and optionally creates .env files for easy integration with development
# projects.
#
# Features:
# - Creates a new PostgreSQL database
# - Generates a unique user with a secure random password
# - Grants appropriate privileges to the user
# - Displays connection strings in multiple formats (URI, individual params)
# - Optionally creates a .env file with database credentials
# - Useful for quickly spinning up isolated database environments for projects
#
# Usage:
# $ ./pg_create_db.sh <database_name> [output_directory_for_env]
# $ chmod +x ~/pg_create_db.sh

# --- Configuration ---
DB_NAME="$1"
OUTPUT_DIR="${2:-.}"

# --- Validation ---
if [ -z "$DB_NAME" ]; then
    echo "❌ ERROR: Database name is required."
    echo "Usage: $0 <database_name> [output_directory_for_env]"
    exit 1
fi

# Check if PostgreSQL is installed and running
if ! command -v psql &> /dev/null; then
    echo "❌ ERROR: PostgreSQL (psql) is not installed or not in PATH."
    exit 1
fi

# Check if PostgreSQL service is running
if ! sudo service postgresql status &> /dev/null; then
    echo "⚠️  PostgreSQL service is not running. Starting it now..."
    sudo service postgresql start
    sleep 2
fi

# --- Generate User and Password ---
DB_USER="${DB_NAME}_user"
DB_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-20)

echo "--- 🐘 Creating PostgreSQL Database ---"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Password: $DB_PASSWORD"
echo ""

# --- Create Database and User ---
# Connect as postgres superuser to create resources
sudo -u postgres psql <<EOF
-- Create the user with the generated password
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';

-- Create the database
CREATE DATABASE $DB_NAME OWNER $DB_USER;

-- Grant all privileges on the database to the user
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Connect to the new database and grant schema privileges
\c $DB_NAME
GRANT ALL ON SCHEMA public TO $DB_USER;

\q
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS: Database '$DB_NAME' created with user '$DB_USER'"
    echo ""
    echo "--- 📋 Connection Information ---"
    echo ""
    echo "Connection URI:"
    echo "postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
    echo ""
    echo "Individual Parameters:"
    echo "  Host:     localhost"
    echo "  Port:     5432"
    echo "  Database: $DB_NAME"
    echo "  User:     $DB_USER"
    echo "  Password: $DB_PASSWORD"
    echo ""
    
    # Ask if user wants to create .env file
    read -p "Create .env file? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ENV_FILE="$OUTPUT_DIR/.env.${DB_NAME}"
        cat > "$ENV_FILE" <<ENVEOF
# PostgreSQL Database Configuration for $DB_NAME
# Generated on $(date)

DB_HOST=localhost
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
ENVEOF
        echo "✅ Environment file created: $ENV_FILE"
    fi
else
    echo "❌ ERROR: Failed to create database or user."
    exit 1
fi

echo ""
echo "--- 🔗 Quick Test Connection ---"
echo "Run: psql postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
