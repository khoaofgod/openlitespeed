# OpenLiteSpeed VHOST CLI - Professional Edition

## 🚀 Overview

A simple, professional command-line tool for managing OpenLiteSpeed virtual hosts with automated SSL setup and user management.

## ✨ Features

### Core Features
- **User Management**: Create new users or select from existing ones with smart suggestions
- **Domain Validation**: Ping domains to verify they point to the server
- **Backup System**: Automatic backup before overriding existing configurations  
- **SSL Automation**: Let's Encrypt integration with auto-renewal
- **Complete Configuration**: All required OpenLiteSpeed settings including:
  - External processors
  - Script handlers
  - ACME challenge context for Let's Encrypt
  - Error pages
  - Log rotation
  - Compression settings

### Key Improvements  
- ✅ **SSL Auto-troubleshooting** - Automatically detects and fixes SSL issues
- ✅ **SSL Listener Auto-config** - Fixes missing SSL certificate configuration
- ✅ **SSL Health Checks** - Comprehensive SSL verification and diagnostics
- ✅ **Port 443 Auto-fix** - Automatically resolves SSL binding issues
- ✅ **Fixed ping functionality** - Shows actual ping results and IP addresses
- ✅ **Fixed document root** - Corrected $VH_HOST typo to $VH_ROOT
- ✅ **Complete vhost config** - All required settings for production use
- ✅ **ACME context** - Proper Let's Encrypt challenge directory
- ✅ **Auto-renewal** - Cron job for certificate renewal
- ✅ **Listener scanning** - Shows all listeners and their ports
- ✅ **Better error handling** - Continues on errors instead of exiting

## 📋 Requirements

- Root/sudo access
- OpenLiteSpeed installed
- Internet connection (for SSL certificates)
- `certbot` installed (for SSL)

## 🎯 Usage

### Interactive Virtual Host Setup
```bash
sudo /home/bready/webserver/vhost-add.sh
```

### SSL Troubleshooting Tools
```bash
# Check SSL health for a domain
sudo /home/bready/webserver/vhost-add.sh --ssl-check domain.com

# Auto-fix SSL issues for a domain  
sudo /home/bready/webserver/vhost-add.sh --ssl-fix domain.com

# Show help and all options
sudo /home/bready/webserver/vhost-add.sh --help
```

## 📖 Workflow

1. **User Selection**
   - Enter username
   - If user doesn't exist, shows similar users
   - Option to create new user or select existing

2. **Domain Setup**
   - Enter domain name
   - Pings domain and shows IP
   - Pings www subdomain
   - Checks if IP matches server
   - If vhost exists, offers backup & override

3. **Configuration**
   - Enter admin email
   - Set document root (default: $VH_ROOT/public)
   - Set vhost root (default: /home/domain)
   - Choose SSL setup

4. **Installation**
   - Shows all listeners and ports
   - Creates directory structure
   - Adds virtualhost definition
   - Creates complete vhost configuration
   - Adds to port 80 listeners
   - If SSL enabled:
     - Adds to port 443 listeners
     - Creates Let's Encrypt certificate
     - Sets up auto-renewal

## 🔧 Configuration Details

### Virtual Host Configuration Includes
- Document root and domain settings
- Index files with autoindex disabled
- Error and access logs with rotation
- PHP processing via LSAPI
- External processor with resource limits
- Script handler for PHP
- ACME challenge context at `/usr/local/lsws/Example/html/.well-known/acme-challenge`
- Rewrite rules with .htaccess support
- SSL configuration (when enabled)

### Directory Structure
```
/home/domain/
├── public/          # Website files
├── logs/            # Error and access logs
├── tmp/             # Temporary files
└── backup/          # Backup directory
```

### Backup Location
```
/home/bready/webserver/backups/
└── domain_backup_YYYYMMDD_HHMMSS/
    ├── vhost_config/
    └── main_config_entry.conf
```

## 🔐 SSL Configuration

### Automatic Setup & Auto-Fixing
- Uses Let's Encrypt for free certificates
- **Auto-detects SSL issues** and fixes them automatically
- **Fixes SSL listener configuration** when certificates exist but port 443 isn't working
- **Verifies SSL functionality** with comprehensive health checks
- **Automatic port 443 binding** verification and troubleshooting
- Creates renewal hook for OpenLiteSpeed reload
- Sets up daily cron job at 3 AM

### SSL Troubleshooting Tools
The script includes advanced SSL troubleshooting capabilities:

```bash
# Check SSL health status
sudo ./vhost-add.sh --ssl-check domain.com

# Auto-fix SSL issues
sudo ./vhost-add.sh --ssl-fix domain.com
```

### What the Auto-Fix Handles
✅ Missing SSL listener certificate configuration  
✅ SSL certificates exist but port 443 not listening  
✅ OpenLiteSpeed SSL binding issues  
✅ Certificate validation problems  
✅ Configuration syntax errors  
✅ Service restart issues  

### Manual SSL Setup
If automatic setup fails:
```bash
certbot certonly --webroot -w /home/domain/public -d domain.com
```

## 🛠️ Useful Commands

```bash
# Restart OpenLiteSpeed
systemctl restart lsws

# Check virtual host logs
tail -f /home/domain/logs/error.log

# Check SSL certificates
certbot certificates

# Manual SSL renewal
certbot renew

# Test configuration
/usr/local/lsws/bin/lshttpd -t
```

## 🐛 Troubleshooting

### Domain Not Reachable
- Check DNS settings
- Verify firewall allows ports 80/443
- Ensure domain points to server IP

### SSL Setup Failed
- **Try the auto-fix first**: `sudo ./vhost-add.sh --ssl-fix domain.com`
- Domain must be accessible via HTTP first
- Check firewall for port 80/443
- Verify DNS is properly configured
- Check `/var/log/letsencrypt/` for errors
- **Use SSL health check**: `sudo ./vhost-add.sh --ssl-check domain.com`

### Virtual Host Not Working
- Check OpenLiteSpeed error log: `/usr/local/lsws/logs/error.log`
- Verify user permissions
- Check virtual host logs in domain directory

## 📝 Example Session

```
Enter User ID to run the site: john
[⚠] User 'john' does not exist

[✓] Found similar existing users:
  1. john123
  2. johnny

Choose an option:
  1-2. Use existing user (enter number)
  n. Create new user: john
  r. Re-enter different User ID

Your choice: n
[→] Creating new user: john
[✓] User created successfully

Enter Domain Name: example.com
[→] Pinging example.com...
  ✓ Reachable (IP: 192.168.1.100)
[✓] Domain IP matches server IP - Good!

[→] Pinging www.example.com...
  ✗ Not reachable

Enter Admin Email: admin@example.com
Document Root (default: $VH_ROOT/public): 
Virtual Host Root (default: /home/example.com): 

SSL Configuration:
Enable SSL with Let's Encrypt? (y/n): y

🚀 Starting Virtual Host Setup...

[→] Scanning all listeners...
  • Listener: Default | Port: 80
  • Listener: SSL | Port: 443

[✓] Virtual host created successfully!
```

## 🔄 Version History

- **v2.0** - Complete rewrite with all fixes:
  - Fixed ping functionality
  - Fixed document root variable
  - Added complete vhost configuration
  - Added ACME context for Let's Encrypt
  - Improved error handling
  - Added listener scanning