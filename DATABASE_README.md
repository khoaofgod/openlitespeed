# Database Management CLI - Professional Edition

## 🎯 Overview

A comprehensive command-line tool for managing MySQL/MariaDB users and databases with automatic configuration, user-friendly interface, and complete access control management.

## ✨ Features

### 🔧 **Auto-Configuration**
- **Environment Management** - Automatically creates and manages `.env` configuration
- **Connection Testing** - Validates database connectivity before operations
- **Type Support** - Works with both MySQL and MariaDB
- **Smart Defaults** - Uses optimal settings (utf8mb4 charset, standard ports)

### 👥 **User Management**
- **User Search** - Find users by partial name matching
- **User Creation** - Create users with both localhost and external access (`@localhost` and `@%`)
- **Password Updates** - Update passwords for both local and external access
- **Access Listing** - View all databases accessible by a user

### 🗄️ **Database Management**
- **Database Creation** - Create databases with proper charset (utf8mb4)
- **Access Control** - Grant database access to users
- **Owner Assignment** - Automatically assign database ownership during creation
- **External Access** - Always configure for both local and external connections

### 🛡️ **Security & Best Practices**
- **Dual Host Support** - Creates users for both `@localhost` and `@%` for maximum compatibility
- **Secure Password Input** - Hidden password prompts
- **Connection Validation** - Tests all operations before execution
- **Error Handling** - Comprehensive error checking and user feedback

## 📋 Requirements

- Root/sudo access
- MySQL or MariaDB server installed and running
- Network connectivity to database server (if remote)

## 🎯 Usage

```bash
# Run the database management tool
sudo ./database.sh
```

## 📖 Workflow

### 1. **Initial Setup (First Run)**
The script will prompt for database configuration:

```
Database Type:
  1. mysql
  2. mariadb

Select database type (1-2): 1
Database Host (default: localhost): 
Database User (default: root): 
Database Password: [hidden input]
Database Port (default: 3306): 
Database Charset (default: utf8mb4): 
```

Configuration is saved to `.env` file and reused on subsequent runs.

### 2. **Main Menu**
```
📊 Database Management Menu

1. 👥 User Management
2. 🗄️  Database Management  
3. 🔑 Update User Password
4. 🔐 Grant Database Access
5. ⚙️  Reconfigure Database Connection
6. 🚪 Exit
```

### 3. **User Management Flow**
```
Enter username to search: john

Users matching 'john':
  1. john_dev
  2. johnsmith

Select an option:
  s. Select existing user
  n. Create new user: john
  b. Back to search
```

### 4. **Database Operations**
- **Create Database**: Automatically sets utf8mb4 charset
- **Grant Access**: Configures access for both local and external connections
- **List Access**: Shows all databases accessible by a user

## 🔧 Configuration

### Environment File (`.env`)
```bash
# Database Configuration
DB_TYPE=mysql
DB_HOST=localhost
DB_USER=root
DB_PASS=your_password
DB_PORT=3306
DB_CHARSET=utf8mb4
```

### Character Set
- **Default**: `utf8mb4` with `utf8mb4_unicode_ci` collation
- **Reason**: Full UTF-8 support including emojis and 4-byte Unicode characters
- **Compatibility**: Works with both MySQL 5.7+ and MariaDB 10.2+

## 🛠️ Advanced Features

### Dual Host Configuration
The script automatically creates users with both access types:
- `user@localhost` - Local server access
- `user@%` - External network access

This ensures maximum compatibility and eliminates common connection issues.

### Smart User Search
- **Partial Matching**: Find users with partial name input
- **List All**: Use `list` command to see all users
- **Create on Demand**: Option to create users that don't exist

### Error Recovery
- **Connection Testing**: Validates database connectivity
- **Operation Validation**: Checks if operations succeeded
- **Graceful Fallback**: Continues operation even if some steps fail

## 🐛 Troubleshooting

### Connection Issues
- Verify database server is running
- Check firewall settings for database port
- Validate credentials in `.env` file
- Test network connectivity to database host

### Permission Issues
- Run script with `sudo` (required)
- Ensure database user has administrative privileges
- Check database server user limits

### User Creation Failures
- Verify user doesn't already exist
- Check database user creation limits
- Ensure sufficient privileges for user management

## 📝 Examples

### Create User with Database
```bash
# 1. Run script
sudo ./database.sh

# 2. Select "User Management"
# 3. Enter new username: "myapp"
# 4. Choose "Create new user"  
# 5. Enter password
# 6. User created with @localhost and @% access
```

### Grant Database Access
```bash
# 1. Select "Grant Database Access"
# 2. Enter database name: "myapp_db"
# 3. Enter username: "myapp"
# 4. Access granted for both local and external connections
```

### Update Password
```bash
# 1. Select "Update User Password"
# 2. Enter username: "myapp"
# 3. Enter new password
# 4. Password updated for both @localhost and @% hosts
```

## 🔐 Security Notes

- Passwords are entered securely (hidden input)
- Database credentials stored in `.env` file (add to .gitignore)
- All operations require root privileges
- Users created with both local and external access for flexibility
- Connection testing prevents unauthorized access attempts

## 🚀 Integration

This tool works seamlessly with the OpenLiteSpeed VHOST CLI and can be used to:
- Create database users for web applications
- Set up databases for virtual hosts
- Manage development and production database access
- Automate database provisioning workflows