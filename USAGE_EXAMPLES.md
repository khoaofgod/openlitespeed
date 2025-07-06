# Database Management CLI - Usage Examples

## 🎯 Quick Start

```bash
sudo ./database.sh
```

## 📝 Example Workflows

### 1. First Time Setup
```
sudo ./database.sh

# Initial configuration prompts:
Database Type:
  1. mysql
  2. mariadb
Select database type (1-2): 2

Database Host (default: localhost): db-server
Database User (default: root): root
Database Password: [enter password]
Database Port (default: 3306): 
Database Charset (default: utf8mb4): 

✅ Database configuration saved to .env
✅ Database connection successful!
```

### 2. Create New User and Database
```
📊 Database Management Menu

1. 👥 User Management
2. 🗄️  Database Management
3. 🔑 Update User Password
4. 🔐 Grant Database Access
5. ⚙️  Reconfigure Database Connection
6. 🚪 Exit

Select an option (1-6): 1

👥 User Management
Enter username to search: myapp

No users found matching 'myapp'

Options:
  n. Create new user: myapp
  b. Back to search

Your choice: n
Enter password for new user 'myapp': ********

✅ User 'myapp' created successfully for both localhost and external access
```

### 3. Create Database for User
```
Select an option (1-6): 2

🗄️  Database Management
Enter database name to create: myapp_production
Enter username to grant access (optional): myapp

✅ Database 'myapp_production' created successfully
✅ Access granted to database 'myapp_production' for user 'myapp'
```

### 4. Search and Manage Existing Users
```
Select an option (1-6): 1

👥 User Management
Enter username to search: app

Users matching 'app':
  1. myapp
  2. webapp_user

Select an option:
  s. Select existing user
  n. Create new user: app
  b. Back to search

Your choice: s
Enter exact username: myapp

Database Access for 'myapp':
  1. myapp_production

Options for user 'myapp':
  1. Create new database for this user
  2. Grant access to existing database
  3. Back

Your choice: 1
Enter new database name: myapp_staging

✅ Database 'myapp_staging' created successfully
✅ Access granted to database 'myapp_staging' for user 'myapp'
```

### 5. Update User Password
```
Select an option (1-6): 3

Enter username: myapp
Enter new password: ********

✅ Password updated successfully for user 'myapp'
```

### 6. Grant Database Access
```
Select an option (1-6): 4

Enter database name: shared_db
Enter username: myapp

✅ Access granted to database 'shared_db' for user 'myapp'
```

## 🔧 Advanced Features

### List All Users
```
👥 User Management
Enter username to search: list

Available Users:
  1. UpOHIIun3auheQ
  2. begindeals_user
  3. cyberpanel
  4. myapp
  5. webapp_user
```

### Dual Host Configuration
Every user is automatically created with both:
- `myapp@localhost` - Local server access
- `myapp@%` - External network access

### Connection Testing
The script automatically tests database connectivity before any operations:
```
✅ Database configuration loaded
🔍 Testing database connection...
✅ Database connection successful!
```

## 🛠️ Configuration Management

### View Current Configuration
```bash
cat .env
```
```
# Database Configuration
DB_TYPE=mariadb
DB_HOST=db-server
DB_USER=root
DB_PASS=rootDb123
DB_PORT=3306
DB_CHARSET=utf8mb4
```

### Reconfigure Database Connection
```
Select an option (1-6): 5

✅ Configuration removed. Restart script to reconfigure.
```

## 🔍 Troubleshooting

### Connection Issues
If you see connection failures:
1. Verify database server is running
2. Check network connectivity: `ping db-server`
3. Verify credentials in `.env` file
4. Test manual connection:
   ```bash
   mysql -h db-server -u root -p
   ```

### Client Not Found
The script auto-detects available clients:
- Prefers `mariadb` command if available
- Falls back to `mysql` command
- Shows error if neither is installed

### Permission Denied
Ensure you run with sudo:
```bash
sudo ./database.sh
```

## 📊 Real-World Examples

### Web Application Setup
```bash
# 1. Create application user
sudo ./database.sh
# Select: 1 (User Management)
# Enter: "webapp_prod"
# Choose: "n" (Create new user)
# Enter secure password

# 2. Create production database
# Select: 2 (Database Management)
# Enter: "webapp_production"
# Enter: "webapp_prod"

# 3. Create staging database
# Select: 2 (Database Management)  
# Enter: "webapp_staging"
# Enter: "webapp_prod"
```

### Multiple Environment Setup
```bash
# Development user and database
User: myapp_dev → Database: myapp_development

# Staging user and database  
User: myapp_stage → Database: myapp_staging

# Production user and database
User: myapp_prod → Database: myapp_production
```

## ✨ Key Benefits

- **🔐 Secure**: Dual host support (@localhost and @%)
- **🎯 User-Friendly**: Interactive search and selection
- **⚡ Fast**: Auto-configuration with .env persistence
- **🛡️ Safe**: Connection testing before operations
- **🔄 Flexible**: Works with MySQL and MariaDB
- **📝 Complete**: Full CRUD operations for users and databases

## 🚀 Integration with OpenLiteSpeed

Perfect companion to the `vhost-add.sh` script:
1. Use `vhost-add.sh` to create virtual hosts
2. Use `database.sh` to create database users and databases
3. Configure your web applications with the database credentials

Example workflow:
```bash
# 1. Create virtual host
sudo ./vhost-add.sh
# Domain: myapp.com

# 2. Create database setup
sudo ./database.sh
# User: myapp_user
# Database: myapp_db

# 3. Deploy application with database connection:
# Host: db-server (or localhost)
# User: myapp_user  
# Database: myapp_db
```