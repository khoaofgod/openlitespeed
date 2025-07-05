# Changelog

All notable changes to this project will be documented in this file.

## [2.1.2] - 2025-07-05

### Added
- 📦 **npm Auto-installation** - Automatically installs Node.js and npm when not present
- 🤖 **Claude Code Auto-installation** - Automatically installs @anthropic-ai/claude-code globally
- 🛠️ **Development Tools Setup** - Complete development environment setup

### Enhanced
- 🚀 **Setup Process** - Now includes npm and Claude Code installation
- 📋 **Documentation** - Updated with development tools information

## [2.1.1] - 2025-07-05

### Added
- 🌐 **Tailscale Auto-installation** - Automatically installs Tailscale when not present
- 🔗 **Secure Networking Setup** - Provides easy access to Tailscale configuration

### Enhanced
- 🚀 **Setup Process** - Now includes Tailscale installation alongside OpenLiteSpeed verification
- 📋 **Requirements** - Updated documentation to reflect Tailscale integration

## [2.1.0] - 2025-07-05

### Added
- 🔧 **SSL Auto-troubleshooting System** - Automatically detects and fixes SSL issues
- 🩺 **SSL Health Check Tool** - Comprehensive SSL verification with `--ssl-check` option
- 🛠️ **SSL Auto-fix Tool** - Automatic SSL issue resolution with `--ssl-fix` option
- 📋 **Help System** - Added `--help` option with detailed usage information
- 🔍 **SSL Listener Auto-configuration** - Automatically fixes missing SSL certificate configuration
- ✅ **Port 443 Binding Verification** - Ensures SSL listener properly binds to port 443
- 🎯 **Enhanced Summary Display** - Shows detailed SSL status with health indicators
- 🔄 **Smart SSL Detection** - Detects existing certificates before creating new ones
- 📊 **Comprehensive Diagnostics** - Detailed SSL troubleshooting information

### Fixed
- 🐛 **SSL Listener Configuration** - Automatically adds missing keyFile and certFile parameters
- 🔒 **HTTPS Binding Issues** - Resolves cases where certificates exist but port 443 doesn't listen
- ⚡ **SSL Verification Logic** - Enhanced SSL connectivity testing and validation
- 🔧 **Configuration Syntax** - Better error detection and handling for OpenLiteSpeed config
- 📝 **Bash Comparison Bug** - Fixed SSL enabled status display in configuration review

### Enhanced
- 🚀 **Setup Process** - SSL setup now includes automatic troubleshooting and verification
- 📈 **Error Handling** - Better error messages and recovery options for SSL issues
- 🎨 **User Interface** - Improved status indicators and progress reporting
- 📚 **Documentation** - Updated README with new SSL troubleshooting features

### Technical Improvements
- Added `check_ssl_listener_config()` function
- Added `fix_ssl_listener_config()` function  
- Added `verify_ssl_working()` function
- Added `troubleshoot_ssl()` function
- Added `ssl_health_check()` function
- Enhanced `setup_ssl()` with auto-troubleshooting capabilities
- Added command-line argument parsing for new tools

## [2.0.0] - 2025-07-05

### Added
- ✅ **Fixed ping functionality** - Shows actual ping results and IP addresses
- ✅ **Complete vhost configuration** - All required settings for production use
- ✅ **ACME context support** - Proper Let's Encrypt challenge directory configuration
- ✅ **Auto-renewal setup** - Cron job for certificate renewal
- ✅ **Listener scanning** - Shows all listeners and their ports
- ✅ **Better error handling** - Continues on errors instead of exiting
- ✅ **User management** - Smart user detection and creation
- ✅ **Backup system** - Automatic backup before overriding configurations
- ✅ **Domain validation** - Ping tests and IP verification

### Fixed
- 🐛 **Document root variable** - Corrected $VH_HOST typo to $VH_ROOT
- 🔧 **Virtual host configuration** - Added all missing required settings
- 📁 **Directory structure** - Proper directory creation and permissions
- 🔐 **SSL configuration** - Enhanced SSL setup and validation

### Initial Release Features
- Interactive virtual host creation
- Let's Encrypt SSL integration
- User and domain management
- OpenLiteSpeed configuration
- Backup and recovery system