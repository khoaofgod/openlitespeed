#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                          Database Management CLI - Professional Edition       ║
# ║                                                                               ║
# ║   Comprehensive MySQL/MariaDB User & Database Management                     ║
# ║   Features: User creation, Database management, Access control, Auto-config  ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# Disable exit on error for better control
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
ENV_FILE=".env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/$ENV_FILE"

# Database connection variables
DB_TYPE=""
DB_HOST=""
DB_USER=""
DB_PASS=""
DB_PORT=""
DB_CHARSET=""

# Function to print colored output
print_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[→]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[🎉]${NC} $1"
}

print_header() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                          Database Management CLI - Professional Edition       ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# Function to check if root access
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Function to validate database type
validate_db_type() {
    local db_type="$1"
    if [[ "$db_type" == "mysql" ]] || [[ "$db_type" == "mariadb" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate port number
validate_port() {
    local port="$1"
    if [[ "$port" =~ ^[0-9]+$ ]] && [[ "$port" -ge 1 ]] && [[ "$port" -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if .env file exists
check_env_file() {
    if [[ -f "$ENV_PATH" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to create .env file with user input
create_env_file() {
    print_step "Creating database configuration..."
    echo
    
    # Database type
    while true; do
        echo -e "${WHITE}Database Type:${NC}"
        echo "  1. mysql"
        echo "  2. mariadb"
        echo
        read -p "Select database type (1-2): " db_choice
        
        case $db_choice in
            1)
                DB_TYPE="mysql"
                break
                ;;
            2)
                DB_TYPE="mariadb"
                break
                ;;
            *)
                print_error "Invalid choice. Please select 1 or 2."
                ;;
        esac
    done
    
    # Host
    echo
    read -p "Database Host (default: localhost): " DB_HOST
    DB_HOST=${DB_HOST:-"localhost"}
    
    # User
    echo
    read -p "Database User (default: root): " DB_USER
    DB_USER=${DB_USER:-"root"}
    
    # Password
    echo
    read -s -p "Database Password: " DB_PASS
    echo
    
    # Port
    echo
    while true; do
        read -p "Database Port (default: 3306): " DB_PORT
        DB_PORT=${DB_PORT:-"3306"}
        
        if validate_port "$DB_PORT"; then
            break
        else
            print_error "Invalid port number. Please enter a valid port (1-65535)."
        fi
    done
    
    # Charset
    echo
    read -p "Database Charset (default: utf8mb4): " DB_CHARSET
    DB_CHARSET=${DB_CHARSET:-"utf8mb4"}
    
    # Save to .env file
    cat > "$ENV_PATH" << EOF
# Database Configuration
DB_TYPE=$DB_TYPE
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_PORT=$DB_PORT
DB_CHARSET=$DB_CHARSET
EOF
    
    print_success "Database configuration saved to $ENV_FILE"
}

# Function to load .env file
load_env_file() {
    if check_env_file; then
        source "$ENV_PATH"
        
        # Validate required variables
        if [[ -z "$DB_TYPE" ]] || [[ -z "$DB_HOST" ]] || [[ -z "$DB_USER" ]] || [[ -z "$DB_PASS" ]]; then
            print_error "Invalid .env file. Missing required database configuration."
            return 1
        fi
        
        print_info "Database configuration loaded"
        return 0
    else
        print_warning ".env file not found"
        return 1
    fi
}

# Function to test database connection
test_db_connection() {
    print_step "Testing database connection..."
    
    local test_result
    case "$DB_TYPE" in
        "mysql")
            mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1
            test_result=$?
            ;;
        "mariadb")
            mariadb -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1
            test_result=$?
            ;;
        *)
            print_error "Unsupported database type: $DB_TYPE"
            return 1
            ;;
    esac
    
    if [[ $test_result -eq 0 ]]; then
        print_success "Database connection successful!"
        return 0
    else
        print_error "Database connection failed!"
        print_info "Please check your configuration in $ENV_FILE"
        return 1
    fi
}

# Function to execute SQL query
execute_sql() {
    local query="$1"
    local show_output="${2:-false}"
    
    case "$DB_TYPE" in
        "mysql")
            if [[ "$show_output" == "true" ]]; then
                mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "$query" 2>/dev/null
            else
                mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "$query" >/dev/null 2>&1
            fi
            ;;
        "mariadb")
            if [[ "$show_output" == "true" ]]; then
                mariadb -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "$query" 2>/dev/null
            else
                mariadb -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "$query" >/dev/null 2>&1
            fi
            ;;
    esac
    
    return $?
}

# Function to get query result
get_sql_result() {
    local query="$1"
    
    case "$DB_TYPE" in
        "mysql")
            mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -sN -e "$query" 2>/dev/null
            ;;
        "mariadb")
            mariadb -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -sN -e "$query" 2>/dev/null
            ;;
    esac
}

# Function to list all database users
list_all_users() {
    print_step "Listing all database users..."
    echo
    
    local users=$(get_sql_result "SELECT DISTINCT User FROM mysql.user WHERE User != '' ORDER BY User;")
    
    if [[ -n "$users" ]]; then
        echo -e "${WHITE}Available Users:${NC}"
        local i=1
        while IFS= read -r user; do
            echo "  $i. $user"
            ((i++))
        done <<< "$users"
        echo
    else
        print_warning "No users found"
    fi
}

# Function to search users by pattern
search_users() {
    local pattern="$1"
    local users=$(get_sql_result "SELECT DISTINCT User FROM mysql.user WHERE User LIKE '%$pattern%' AND User != '' ORDER BY User;")
    
    if [[ -n "$users" ]]; then
        echo -e "${WHITE}Users matching '$pattern':${NC}"
        local i=1
        while IFS= read -r user; do
            echo "  $i. $user"
            ((i++))
        done <<< "$users"
        echo "$users"
    else
        echo ""
    fi
}

# Function to check if user exists
user_exists() {
    local username="$1"
    local count=$(get_sql_result "SELECT COUNT(*) FROM mysql.user WHERE User = '$username';")
    
    if [[ "$count" -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to list databases accessible by user
list_user_databases() {
    local username="$1"
    
    print_step "Listing databases accessible by user '$username'..."
    echo
    
    # Get grants for localhost and % hosts
    local grants_localhost=$(get_sql_result "SHOW GRANTS FOR '$username'@'localhost';" 2>/dev/null)
    local grants_wildcard=$(get_sql_result "SHOW GRANTS FOR '$username'@'%';" 2>/dev/null)
    
    local all_grants="$grants_localhost$grants_wildcard"
    
    if [[ -n "$all_grants" ]]; then
        echo -e "${WHITE}Database Access for '$username':${NC}"
        
        # Parse grants to extract database names
        local databases=$(echo "$all_grants" | grep -oP "GRANT .* ON \K[^*]*" | grep -v "mysql\|information_schema\|performance_schema\|sys" | sort -u)
        
        if [[ -n "$databases" ]]; then
            local i=1
            while IFS= read -r db; do
                if [[ "$db" != "*" ]] && [[ -n "$db" ]]; then
                    echo "  $i. $db"
                    ((i++))
                fi
            done <<< "$databases"
        fi
        
        echo
        echo -e "${CYAN}Full Grants:${NC}"
        echo "$all_grants" | sed 's/^/  /'
        echo
    else
        print_warning "No database access found for user '$username'"
    fi
}

# Function to create new database user
create_new_user() {
    local username="$1"
    local password="$2"
    
    print_step "Creating user '$username'..."
    
    # Create user for both localhost and % (external access)
    local create_localhost="CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';"
    local create_wildcard="CREATE USER '$username'@'%' IDENTIFIED BY '$password';"
    
    if execute_sql "$create_localhost" && execute_sql "$create_wildcard"; then
        print_success "User '$username' created successfully for both localhost and external access"
        
        # Flush privileges
        execute_sql "FLUSH PRIVILEGES;"
        return 0
    else
        print_error "Failed to create user '$username'"
        return 1
    fi
}

# Function to update user password
update_user_password() {
    local username="$1"
    local new_password="$2"
    
    print_step "Updating password for user '$username'..."
    
    # Update password for both localhost and % hosts
    local update_localhost="ALTER USER '$username'@'localhost' IDENTIFIED BY '$new_password';"
    local update_wildcard="ALTER USER '$username'@'%' IDENTIFIED BY '$new_password';"
    
    local success=true
    
    # Try to update localhost
    if ! execute_sql "$update_localhost"; then
        print_warning "Could not update password for '$username'@'localhost' (user might not exist)"
        success=false
    fi
    
    # Try to update wildcard
    if ! execute_sql "$update_wildcard"; then
        print_warning "Could not update password for '$username'@'%' (user might not exist)"
        success=false
    fi
    
    if [[ "$success" == "true" ]]; then
        execute_sql "FLUSH PRIVILEGES;"
        print_success "Password updated successfully for user '$username'"
        return 0
    else
        print_error "Failed to update password for user '$username'"
        return 1
    fi
}

# Function to create database
create_database() {
    local dbname="$1"
    local owner="$2"
    
    print_step "Creating database '$dbname'..."
    
    # Create database
    local create_db="CREATE DATABASE \`$dbname\` CHARACTER SET $DB_CHARSET COLLATE ${DB_CHARSET}_unicode_ci;"
    
    if execute_sql "$create_db"; then
        print_success "Database '$dbname' created successfully"
        
        # Grant privileges to user if specified
        if [[ -n "$owner" ]]; then
            print_step "Granting privileges to user '$owner'..."
            grant_database_access "$dbname" "$owner"
        fi
        
        return 0
    else
        print_error "Failed to create database '$dbname'"
        return 1
    fi
}

# Function to grant database access to user
grant_database_access() {
    local dbname="$1"
    local username="$2"
    
    print_step "Granting access to database '$dbname' for user '$username'..."
    
    # Grant privileges for both localhost and % hosts
    local grant_localhost="GRANT ALL PRIVILEGES ON \`$dbname\`.* TO '$username'@'localhost';"
    local grant_wildcard="GRANT ALL PRIVILEGES ON \`$dbname\`.* TO '$username'@'%';"
    
    if execute_sql "$grant_localhost" && execute_sql "$grant_wildcard"; then
        execute_sql "FLUSH PRIVILEGES;"
        print_success "Access granted to database '$dbname' for user '$username'"
        return 0
    else
        print_error "Failed to grant access to database '$dbname' for user '$username'"
        return 1
    fi
}

# Function to show main menu
show_main_menu() {
    echo
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    📊 Database Management Menu                ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo "1. 👥 User Management"
    echo "2. 🗄️  Database Management"
    echo "3. 🔑 Update User Password"
    echo "4. 🔐 Grant Database Access"
    echo "5. ⚙️  Reconfigure Database Connection"
    echo "6. 🚪 Exit"
    echo
}

# Function to handle user management
user_management_menu() {
    while true; do
        echo
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                       👥 User Management                      ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        read -p "Enter username to search (or 'list' for all users, 'back' to return): " user_input
        
        case "$user_input" in
            "back")
                return
                ;;
            "list")
                list_all_users
                ;;
            "")
                print_error "Please enter a username"
                continue
                ;;
            *)
                # Search for users
                local matching_users=$(search_users "$user_input")
                
                if [[ -n "$matching_users" ]]; then
                    echo "$matching_users"
                    
                    # Ask which user to select
                    echo "Select an option:"
                    echo "  s. Select existing user"
                    echo "  n. Create new user: $user_input"
                    echo "  b. Back to search"
                    echo
                    
                    read -p "Your choice: " choice
                    
                    case "$choice" in
                        "s")
                            read -p "Enter exact username: " selected_user
                            if user_exists "$selected_user"; then
                                list_user_databases "$selected_user"
                                
                                echo "Options for user '$selected_user':"
                                echo "  1. Create new database for this user"
                                echo "  2. Grant access to existing database"
                                echo "  3. Back"
                                echo
                                
                                read -p "Your choice: " user_action
                                
                                case "$user_action" in
                                    "1")
                                        read -p "Enter new database name: " new_db
                                        create_database "$new_db" "$selected_user"
                                        ;;
                                    "2")
                                        read -p "Enter database name to grant access: " grant_db
                                        grant_database_access "$grant_db" "$selected_user"
                                        ;;
                                esac
                            else
                                print_error "User '$selected_user' does not exist"
                            fi
                            ;;
                        "n")
                            read -s -p "Enter password for new user '$user_input': " new_password
                            echo
                            create_new_user "$user_input" "$new_password"
                            ;;
                    esac
                else
                    echo "No users found matching '$user_input'"
                    echo
                    echo "Options:"
                    echo "  n. Create new user: $user_input"
                    echo "  b. Back to search"
                    echo
                    
                    read -p "Your choice: " choice
                    
                    if [[ "$choice" == "n" ]]; then
                        read -s -p "Enter password for new user '$user_input': " new_password
                        echo
                        create_new_user "$user_input" "$new_password"
                    fi
                fi
                ;;
        esac
    done
}

# Function to handle database management
database_management_menu() {
    echo
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                     🗄️  Database Management                   ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    read -p "Enter database name to create: " db_name
    
    if [[ -n "$db_name" ]]; then
        read -p "Enter username to grant access (optional): " db_owner
        create_database "$db_name" "$db_owner"
    else
        print_error "Database name cannot be empty"
    fi
}

# Main function
main() {
    # Show header
    clear
    print_header
    
    # Check root access
    check_root
    
    # Check and load environment
    if ! check_env_file; then
        print_warning ".env file not found. Creating database configuration..."
        create_env_file
    fi
    
    if ! load_env_file; then
        print_error "Failed to load database configuration"
        exit 1
    fi
    
    # Test database connection
    if ! test_db_connection; then
        print_error "Cannot connect to database. Please check your configuration."
        exit 1
    fi
    
    # Main menu loop
    while true; do
        show_main_menu
        read -p "Select an option (1-6): " choice
        
        case $choice in
            1)
                user_management_menu
                ;;
            2)
                database_management_menu
                ;;
            3)
                echo
                read -p "Enter username: " username
                read -s -p "Enter new password: " password
                echo
                update_user_password "$username" "$password"
                ;;
            4)
                echo
                read -p "Enter database name: " dbname
                read -p "Enter username: " username
                grant_database_access "$dbname" "$username"
                ;;
            5)
                rm -f "$ENV_PATH"
                print_info "Configuration removed. Restart script to reconfigure."
                exit 0
                ;;
            6)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please select 1-6."
                ;;
        esac
    done
}

# Run main function
main "$@"