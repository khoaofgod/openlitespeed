#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                    OpenLiteSpeed - VHOST CLI - Professional Edition           ║
# ║                                                                               ║
# ║   Simple, Professional Virtual Host Management for OpenLiteSpeed              ║
# ║   Features: User management, Domain validation, SSL automation, Auto-renewal  ║
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

# Configuration paths
LSWS_CONF="/usr/local/lsws/conf/httpd_config.conf"
LSWS_VHOST_DIR="/usr/local/lsws/conf/vhosts"
CERTBOT_PATH="/usr/bin/certbot"

# Global variables
DOMAIN=""
USERID=""
ADMIN_EMAIL=""
DOC_ROOT=""
VH_ROOT=""
SSL_ENABLED=""
BACKUP_DIR="/home/bready/webserver/backups"

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

# Function to show header
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    OpenLiteSpeed - VHOST CLI - Professional Edition           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# Function to check root access
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Function to check OpenLiteSpeed and install required tools
check_openlitespeed() {
    if [[ ! -f "$LSWS_CONF" ]]; then
        print_error "OpenLiteSpeed configuration not found at $LSWS_CONF"
        print_info "Please install OpenLiteSpeed first"
        exit 1
    fi
    
    if ! systemctl is-active --quiet lsws; then
        print_warning "OpenLiteSpeed is not running. Starting it..."
        systemctl start lsws
    fi
    
    # Check and install Tailscale if not present
    if ! command -v tailscale &> /dev/null; then
        print_step "Tailscale not found. Installing Tailscale..."
        if curl -fsSL https://tailscale.com/install.sh | sh; then
            print_success "Tailscale installed successfully!"
            print_info "To configure Tailscale, run: sudo tailscale up"
        else
            print_warning "Tailscale installation failed, but continuing with virtual host setup"
        fi
    else
        print_info "Tailscale is already installed"
    fi
    
    # Check and install npm if not present
    if ! command -v npm &> /dev/null; then
        print_step "npm not found. Installing Node.js and npm..."
        if curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs; then
            print_success "Node.js and npm installed successfully!"
        else
            print_warning "npm installation failed, but continuing with virtual host setup"
        fi
    else
        print_info "npm is already installed"
    fi
    
    # Check and install Claude Code if not present
    if ! command -v claude &> /dev/null; then
        print_step "Claude Code not found. Installing Claude Code..."
        if npm install -g @anthropic-ai/claude-code; then
            print_success "Claude Code installed successfully!"
            print_info "To use Claude Code, run: claude"
        else
            print_warning "Claude Code installation failed, but continuing with virtual host setup"
        fi
    else
        print_info "Claude Code is already installed"
    fi
}

# Function to get all server IPs
get_server_ips() {
    # IPv4 addresses
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1'
    # IPv6 addresses (optional)
    ip -6 addr show | grep -oP '(?<=inet6\s)[a-f0-9:]+' | grep -v '::1' | grep -v '^fe80'
}

# Function to ping domain and show results
ping_domain() {
    local domain="$1"
    
    print_step "Pinging $domain..."
    echo -n "  "
    
    # Run ping and capture output
    local ping_output=$(ping -c 3 -W 2 "$domain" 2>&1)
    local ping_result=$?
    
    if [[ $ping_result -eq 0 ]]; then
        # Extract IP from ping output
        local domain_ip=$(echo "$ping_output" | grep -oP 'PING .* \(\K[0-9.]+' | head -1)
        echo -e "${GREEN}✓ Reachable${NC} (IP: $domain_ip)"
        
        # Check if IP matches server IPs
        local server_ips=$(get_server_ips)
        local ip_matches=false
        
        for server_ip in $server_ips; do
            if [[ "$domain_ip" == "$server_ip" ]]; then
                ip_matches=true
                break
            fi
        done
        
        if [[ $ip_matches == true ]]; then
            print_info "Domain IP matches server IP - Good!"
        else
            print_warning "Domain IP ($domain_ip) does not match server IPs"
            echo "  Server IPs:"
            for ip in $server_ips; do
                echo "    • $ip"
            done
        fi
        return 0
    else
        echo -e "${RED}✗ Not reachable${NC}"
        echo "  Possible causes:"
        echo "  • Domain does not exist"
        echo "  • DNS not configured"
        echo "  • Network issues"
        return 1
    fi
}

# Function to check if user exists
check_user_exists() {
    local user="$1"
    id "$user" &>/dev/null
}

# Function to find similar users
find_similar_users() {
    local search="$1"
    getent passwd | grep -i "$search" | cut -d: -f1 | head -5
}

# Function to select or create user
select_user() {
    while true; do
        echo
        read -p "Enter User ID to run the site: " USERID
        
        if check_user_exists "$USERID"; then
            print_info "User '$USERID' exists"
            break
        else
            print_warning "User '$USERID' does not exist"
            
            # Find similar users
            local similar_users=$(find_similar_users "$USERID")
            if [[ -n "$similar_users" ]]; then
                echo
                print_info "Found similar existing users:"
                echo
                local i=1
                while IFS= read -r user; do
                    echo "  $i. $user"
                    ((i++))
                done <<< "$similar_users"
                
                echo
                echo "Choose an option:"
                echo "  1-$((i-1)). Use existing user (enter number)"
                echo "  n. Create new user: $USERID"
                echo "  r. Re-enter different User ID"
                echo
                read -p "Your choice: " choice
                
                if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -lt $i ]]; then
                    USERID=$(echo "$similar_users" | sed -n "${choice}p")
                    print_info "Selected existing user: $USERID"
                    break
                elif [[ "$choice" == "n" ]]; then
                    print_step "Creating new user: $USERID"
                    useradd -m -d "/home/$USERID" -s /bin/bash "$USERID"
                    print_info "User created successfully"
                    break
                elif [[ "$choice" == "r" ]]; then
                    continue
                else
                    print_error "Invalid choice"
                fi
            else
                echo
                echo "Choose an option:"
                echo "  n. Create new user: $USERID"
                echo "  r. Re-enter different User ID"
                echo
                read -p "Your choice: " choice
                
                if [[ "$choice" == "n" ]]; then
                    print_step "Creating new user: $USERID"
                    useradd -m -d "/home/$USERID" -s /bin/bash "$USERID"
                    print_info "User created successfully"
                    break
                elif [[ "$choice" == "r" ]]; then
                    continue
                else
                    print_error "Invalid choice"
                fi
            fi
        fi
    done
}

# Function to check if vhost exists
check_vhost_exists() {
    local domain="$1"
    grep -q "virtualhost $domain {" "$LSWS_CONF"
}

# Function to backup existing vhost
backup_vhost() {
    local domain="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/${domain}_backup_${timestamp}"
    
    print_step "Creating backup..."
    mkdir -p "$backup_path"
    
    # Backup vhost config directory
    if [[ -d "$LSWS_VHOST_DIR/$domain" ]]; then
        cp -r "$LSWS_VHOST_DIR/$domain" "$backup_path/vhost_config"
        print_info "VHost config backed up"
    fi
    
    # Backup main config entry
    awk -v domain="$domain" '
        /^virtualhost '"$domain"' \{/ { p=1 }
        p { print > "'"$backup_path/main_config_entry.conf"'" }
        p && /^\}/ { p=0 }
    ' "$LSWS_CONF"
    
    print_info "Backup completed: $backup_path"
}

# Function to remove existing vhost
remove_vhost() {
    local domain="$1"
    
    print_step "Removing existing configuration..."
    
    # Remove from main config
    local temp_file="/tmp/lsws_conf_$$"
    awk -v domain="$domain" '
        /^virtualhost '"$domain"' \{/ { skip=1 }
        !skip { print }
        skip && /^\}/ { skip=0 }
    ' "$LSWS_CONF" > "$temp_file"
    mv "$temp_file" "$LSWS_CONF"
    
    # Remove from listeners
    awk -v domain="$domain" '
        !/map.*'"$domain"'/ { print }
    ' "$LSWS_CONF" > "$temp_file"
    mv "$temp_file" "$LSWS_CONF"
    
    # Remove vhost directory
    rm -rf "$LSWS_VHOST_DIR/$domain"
    
    print_info "Existing configuration removed"
}

# Function to select domain
select_domain() {
    while true; do
        echo
        read -p "Enter Domain Name: " DOMAIN
        
        # Validate domain format
        if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            print_error "Invalid domain format"
            continue
        fi
        
        # Ping domain
        echo
        ping_domain "$DOMAIN"
        
        # Ping www subdomain
        echo
        ping_domain "www.$DOMAIN"
        
        # Check if vhost exists
        if check_vhost_exists "$DOMAIN"; then
            echo
            print_warning "Virtual host for '$DOMAIN' already exists"
            echo
            echo "Choose an option:"
            echo "  o. Override existing configuration (will backup)"
            echo "  r. Re-enter different domain name"
            echo
            read -p "Your choice: " choice
            
            if [[ "$choice" == "o" ]]; then
                echo
                read -p "Are you sure you want to override? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    backup_vhost "$DOMAIN"
                    remove_vhost "$DOMAIN"
                    break
                fi
            elif [[ "$choice" == "r" ]]; then
                continue
            else
                print_error "Invalid choice"
            fi
        else
            break
        fi
    done
}

# Function to get admin email
get_admin_email() {
    while true; do
        echo
        read -p "Enter Admin Email: " ADMIN_EMAIL
        
        if [[ "$ADMIN_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_error "Invalid email format"
        fi
    done
}

# Function to setup directories
setup_directories() {
    echo
    read -p "Document Root (default: \$VH_ROOT/app/public): " DOC_ROOT
    DOC_ROOT=${DOC_ROOT:-"\$VH_ROOT/app/public"}
    
    read -p "Virtual Host Root (default: /home/$DOMAIN): " VH_ROOT
    VH_ROOT=${VH_ROOT:-"/home/$DOMAIN"}
    
    # Create directories
    print_step "Creating directory structure..."
    mkdir -p "$VH_ROOT"/{app/public,logs,tmp,backup}
    
    # Set ownership
    chown -R "$USERID:$USERID" "$VH_ROOT"
    chmod 755 "$VH_ROOT"
    
    # Create index.html
    cat > "$VH_ROOT/app/public/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to $DOMAIN</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #333; }
        .success { color: #4CAF50; }
    </style>
</head>
<body>
    <h1>Welcome to $DOMAIN</h1>
    <p class="success">✓ Virtual Host is Active!</p>
    <p>OpenLiteSpeed is serving this page.</p>
</body>
</html>
EOF
    
    chown "$USERID:$USERID" "$VH_ROOT/app/public/index.html"
    print_info "Directory structure created"
}

# Function to enable SSL
ask_ssl() {
    echo
    echo -e "${WHITE}SSL Configuration:${NC}"
    echo "  Let's Encrypt provides free SSL certificates automatically."
    echo "  Requirements: Domain must be accessible via HTTP and DNS configured."
    echo
    while true; do
        read -p "Enable SSL with Let's Encrypt? (y/n): " -n 1 -r SSL_ENABLED
        echo
        if [[ $SSL_ENABLED =~ ^[YyNn]$ ]]; then
            break
        fi
        print_error "Please enter 'y' for yes or 'n' for no"
    done
}

# Function to show all listeners
show_all_listeners() {
    print_step "Scanning all listeners..."
    
    local current_listener=""
    local listener_port=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^listener[[:space:]]+([^[:space:]]+)[[:space:]]*\{ ]]; then
            current_listener="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]*address[[:space:]]+.*:([0-9]+) ]]; then
            listener_port="${BASH_REMATCH[1]}"
            echo "  • Listener: $current_listener | Port: $listener_port"
        fi
    done < "$LSWS_CONF"
}

# Function to add virtualhost definition
add_virtualhost() {
    print_step "Adding virtual host definition..."
    
    # Find position before first listener
    local insert_line=$(grep -n "^listener " "$LSWS_CONF" | head -1 | cut -d: -f1)
    
    # Create temp file with vhost definition
    local temp_file="/tmp/vhost_def_$$"
    cat > "$temp_file" << EOF

virtualhost $DOMAIN {
  vhRoot                  $VH_ROOT
  configFile              \$SERVER_ROOT/conf/vhosts/\$VH_NAME/vhost.conf
  allowSymbolLink         1
  enableScript            1
  restrained              1
  setUIDMode              2
  user                    $USERID
  group                   $USERID
}
EOF
    
    # Insert into main config
    if [[ -n "$insert_line" ]]; then
        head -n $((insert_line - 1)) "$LSWS_CONF" > "${LSWS_CONF}.tmp"
        cat "$temp_file" >> "${LSWS_CONF}.tmp"
        tail -n +$insert_line "$LSWS_CONF" >> "${LSWS_CONF}.tmp"
        mv "${LSWS_CONF}.tmp" "$LSWS_CONF"
    else
        cat "$temp_file" >> "$LSWS_CONF"
    fi
    
    rm -f "$temp_file"
    print_info "Virtual host definition added"
}

# Function to create vhost configuration with absolute paths
create_vhost_config() {
    print_step "Creating virtual host configuration..."
    
    mkdir -p "$LSWS_VHOST_DIR/$DOMAIN"
    
    # Convert DOC_ROOT to absolute path
    local abs_doc_root="$DOC_ROOT"
    if [[ "$DOC_ROOT" == *"\$VH_ROOT"* ]]; then
        abs_doc_root="${DOC_ROOT/\$VH_ROOT/$VH_ROOT}"
    fi
    
    cat > "$LSWS_VHOST_DIR/$DOMAIN/vhost.conf" << EOF
docRoot                   $abs_doc_root
vhDomain                  $DOMAIN
vhAliases                 www.$DOMAIN
adminEmails               $ADMIN_EMAIL
enableGzip                1
enableIpGeo               1

index  {
  useServer               0
  indexFiles              index.php, index.html, index.htm
  autoIndex               0
  autoIndexURI            /_autoindex/
}

errorlog $VH_ROOT/logs/error.log {
  useServer               0
  logLevel                WARN
  rollingSize             10M
  keepDays                30
  compressArchive         1
}

accesslog $VH_ROOT/logs/access.log {
  useServer               0
  logFormat               "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\""
  logHeaders              5
  rollingSize             10M
  keepDays                30
  compressArchive         1
}

errorpage 403 {
  url                     /error403.html
}

errorpage 404 {
  url                     /error404.html
}

errorpage 500 {
  url                     /error50x.html
}

scripthandler  {
  add                     lsapi:${USERID} php
}

extprocessor ${USERID} {
  type                    lsapi
  address                 uds://tmp/lshttpd/${USERID}.sock
  maxConns                35
  env                     PHP_LSAPI_CHILDREN=35
  env                     LSAPI_AVOID_FORK=200M
  initTimeout             60
  retryTimeout            0
  persistConn             1
  pcKeepAliveTimeout      60
  respBuffer              0
  autoStart               1
  path                    /usr/local/lsws/lsphp83/bin/lsphp
  backlog                 100
  instances               1
  extUser                 ${USERID}
  extGroup                ${USERID}
  runOnStartUp            2
  priority                0
  memSoftLimit            2047M
  memHardLimit            2047M
  procSoftLimit           1400
  procHardLimit           1500
}

context /.well-known/acme-challenge {
  location                $abs_doc_root/.well-known/acme-challenge
  allowBrowse             1

  rewrite  {
    enable                0
  }
  addDefaultCharset       off
}

rewrite  {
  enable                  1
  autoLoadHtaccess        1
}

module cache {
  storagePath             /usr/local/lsws/cachedata/$DOMAIN
  ls_enabled              1
}
EOF

    # Add SSL section if enabled
    if [[ $SSL_ENABLED =~ ^[Yy]$ ]]; then
        cat >> "$LSWS_VHOST_DIR/$DOMAIN/vhost.conf" << EOF

vhssl  {
  keyFile                 /etc/letsencrypt/live/$DOMAIN/privkey.pem
  certFile                /etc/letsencrypt/live/$DOMAIN/fullchain.pem
  certChain               1
  ciphers                 EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
  enableECDHE             1
  renegProtection         1
  sslSessionCache         1
  sslSessionTickets       1
  enableSpdy              15
  enableQuic              1
  enableStapling          1
  ocspRespMaxAge          86400
}
EOF
    fi
    
    # Set ownership
    chown -R lsadm:nogroup "$LSWS_VHOST_DIR/$DOMAIN"
    chmod 644 "$LSWS_VHOST_DIR/$DOMAIN/vhost.conf"
    
    print_info "Virtual host configuration created"
}

# Function to add domain to listeners
add_to_listeners() {
    local port="$1"
    local purpose="$2"
    
    print_step "Adding domain to $purpose listeners (port $port)..."
    
    local temp_file="/tmp/lsws_listeners_$$"
    local in_listener=false
    local current_listener=""
    local added_count=0
    local found_listeners=()
    
    # First, identify listeners on the target port
    while IFS= read -r line; do
        if [[ "$line" =~ ^listener[[:space:]]+([^[:space:]]+)[[:space:]]*\{ ]]; then
            current_listener="${BASH_REMATCH[1]}"
            in_listener=true
        elif [[ $in_listener == true && "$line" =~ ^[[:space:]]*address[[:space:]]+.*:$port([[:space:]]|$) ]]; then
            found_listeners+=("$current_listener")
        elif [[ $in_listener == true && "$line" =~ ^\} ]]; then
            in_listener=false
        fi
    done < "$LSWS_CONF"
    
    if [[ ${#found_listeners[@]} -eq 0 ]]; then
        print_warning "No $purpose listeners found on port $port"
        return 1
    fi
    
    print_info "Found ${#found_listeners[@]} $purpose listener(s): ${found_listeners[*]}"
    
    # Now add domain to each listener
    cp "$LSWS_CONF" "$temp_file"
    
    for listener in "${found_listeners[@]}"; do
        # Check if domain is already mapped to this listener
        if grep -q "map.*$DOMAIN" "$temp_file" && grep -B 10 "map.*$DOMAIN" "$temp_file" | grep -q "listener $listener"; then
            print_info "Domain already mapped to $listener listener"
            continue
        fi
        
        # Add mapping to this listener
        sed -i "/^listener $listener {/,/^}/ { /secure.*[01]/a\\  map                     $DOMAIN $DOMAIN
        }" "$temp_file"
        
        print_info "✓ Added $DOMAIN to $listener listener"
        ((added_count++))
    done
    
    # Apply changes
    mv "$temp_file" "$LSWS_CONF"
    
    if [[ $added_count -gt 0 ]]; then
        print_info "Successfully added domain to $added_count $purpose listener(s)"
    else
        print_warning "Domain was already mapped to all $purpose listeners"
    fi
}

# Function to check if SSL listener has certificates configured
check_ssl_listener_config() {
    print_step "Checking SSL listener configuration..."
    
    if ! grep -q "keyFile.*\.pem" "$LSWS_CONF"; then
        print_warning "SSL listener missing certificate configuration"
        return 1
    fi
    
    if ! grep -q "certFile.*\.pem" "$LSWS_CONF"; then
        print_warning "SSL listener missing certificate file configuration"
        return 1
    fi
    
    print_info "SSL listener has certificate configuration"
    return 0
}

# Function to fix SSL listener configuration
fix_ssl_listener_config() {
    local domain="$1"
    local cert_path="/etc/letsencrypt/live/$domain"
    
    print_step "Fixing SSL listener configuration..."
    
    # Check if certificates exist
    if [[ ! -f "$cert_path/privkey.pem" ]] || [[ ! -f "$cert_path/fullchain.pem" ]]; then
        print_warning "SSL certificates not found at $cert_path"
        return 1
    fi
    
    # Find SSL listener section
    local ssl_listener_line=$(grep -n "^listener SSL {" "$LSWS_CONF" | cut -d: -f1)
    if [[ -z "$ssl_listener_line" ]]; then
        print_error "SSL listener not found in configuration"
        return 1
    fi
    
    # Check if keyFile and certFile are already configured
    local ssl_end_line=$(tail -n +$ssl_listener_line "$LSWS_CONF" | grep -n "^}" | head -1 | cut -d: -f1)
    ssl_end_line=$((ssl_listener_line + ssl_end_line - 1))
    
    local ssl_section=$(sed -n "${ssl_listener_line},${ssl_end_line}p" "$LSWS_CONF")
    
    if echo "$ssl_section" | grep -q "keyFile.*$domain"; then
        print_info "SSL listener already configured for $domain"
        return 0
    fi
    
    # Add certificate configuration to SSL listener
    local temp_file="/tmp/ssl_fix_$$"
    local insert_line=$((ssl_listener_line + 3)) # After "secure 1"
    
    # Find the line with "secure" to insert after it
    local secure_line=$(sed -n "${ssl_listener_line},${ssl_end_line}p" "$LSWS_CONF" | grep -n "secure.*1" | cut -d: -f1)
    if [[ -n "$secure_line" ]]; then
        insert_line=$((ssl_listener_line + secure_line))
    fi
    
    # Create temp file with certificate configuration
    head -n $insert_line "$LSWS_CONF" > "$temp_file"
    cat >> "$temp_file" << EOF
  keyFile                 $cert_path/privkey.pem
  certFile                $cert_path/fullchain.pem
  certChain               1
EOF
    tail -n +$((insert_line + 1)) "$LSWS_CONF" >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$LSWS_CONF"
    
    print_success "SSL listener configuration updated with certificates"
    return 0
}

# Function to verify SSL is working
verify_ssl_working() {
    local domain="$1"
    local max_attempts=3
    local attempt=1
    
    print_step "Verifying SSL is working..."
    
    while [[ $attempt -le $max_attempts ]]; do
        print_info "Attempt $attempt/$max_attempts: Checking if port 443 is listening..."
        
        if ss -tlnp | grep -q ":443.*litespeed"; then
            print_success "✓ OpenLiteSpeed is listening on port 443"
            
            # Test HTTPS connection
            print_info "Testing HTTPS connection..."
            if curl -sS --connect-timeout 5 --max-time 10 -k "https://$domain/" > /dev/null 2>&1; then
                print_success "✓ HTTPS connection successful"
                return 0
            else
                print_warning "HTTPS connection failed, but port 443 is listening"
                return 1
            fi
        else
            print_warning "Port 443 is not listening (attempt $attempt/$max_attempts)"
            if [[ $attempt -lt $max_attempts ]]; then
                print_info "Restarting OpenLiteSpeed and retrying..."
                systemctl restart lsws
                sleep 5
            fi
        fi
        
        ((attempt++))
    done
    
    print_error "SSL verification failed after $max_attempts attempts"
    return 1
}

# Function to troubleshoot and auto-fix SSL issues
troubleshoot_ssl() {
    local domain="$1"
    
    print_step "🔍 Troubleshooting SSL configuration..."
    
    # 1. Check if SSL listener exists
    if ! grep -q "^listener SSL {" "$LSWS_CONF"; then
        print_error "SSL listener not found in configuration"
        return 1
    fi
    
    # 2. Check if SSL listener has certificate configuration
    if ! check_ssl_listener_config; then
        print_warning "SSL listener missing certificate configuration"
        
        # Try to fix if certificates exist
        if [[ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]]; then
            print_info "Found certificates, attempting to fix SSL listener..."
            if fix_ssl_listener_config "$domain"; then
                print_info "SSL listener configuration fixed, restarting OpenLiteSpeed..."
                systemctl restart lsws
                sleep 5
            else
                print_error "Failed to fix SSL listener configuration"
                return 1
            fi
        else
            print_warning "No SSL certificates found for $domain"
            return 1
        fi
    fi
    
    # 3. Check if port 443 is listening
    if ! ss -tlnp | grep -q ":443.*litespeed"; then
        print_warning "OpenLiteSpeed not listening on port 443"
        
        # Check for certificate file issues
        if [[ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]]; then
            local cert_errors=$(openssl x509 -in "/etc/letsencrypt/live/$domain/fullchain.pem" -noout -checkend 0 2>&1)
            if [[ $? -ne 0 ]]; then
                print_error "SSL certificate appears to be invalid: $cert_errors"
                return 1
            fi
            
            print_info "SSL certificates appear valid, checking configuration..."
            
            # Check for configuration syntax errors
            local config_test=$(/usr/local/lsws/bin/lshttpd -t 2>&1 | grep -i "error\|fail")
            if [[ -n "$config_test" ]]; then
                print_error "OpenLiteSpeed configuration errors detected:"
                echo "$config_test"
                return 1
            fi
            
            print_info "Configuration appears valid, forcing restart..."
            systemctl stop lsws
            sleep 2
            systemctl start lsws
            sleep 5
        else
            print_error "SSL certificates not found at /etc/letsencrypt/live/$domain/"
            return 1
        fi
    fi
    
    # 4. Final verification
    if verify_ssl_working "$domain"; then
        print_success "✅ SSL troubleshooting completed successfully"
        return 0
    else
        print_error "❌ SSL troubleshooting failed"
        
        # Provide detailed diagnostics
        print_info "🔍 Diagnostic information:"
        print_info "• Port 443 status: $(ss -tlnp | grep ':443' || echo 'Not listening')"
        print_info "• SSL certificates: $(ls -la /etc/letsencrypt/live/$domain/ 2>/dev/null || echo 'Not found')"
        print_info "• OpenLiteSpeed status: $(systemctl is-active lsws)"
        
        return 1
    fi
}

# Function to setup SSL with auto-troubleshooting
setup_ssl() {
    if [[ ! $SSL_ENABLED =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_step "🔐 Setting up SSL certificate with auto-troubleshooting..."
    
    # Add to HTTPS listeners first
    add_to_listeners "443" "HTTPS"
    
    # Check if certificates already exist
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]]; then
        print_info "Existing SSL certificates found for $DOMAIN"
        
        # Run SSL troubleshooting to ensure everything is working
        if troubleshoot_ssl "$DOMAIN"; then
            print_success "✅ SSL is already working correctly!"
            setup_ssl_renewal
            return 0
        else
            print_warning "SSL certificates exist but not working properly, will recreate..."
        fi
    fi
    
    # Initial restart
    print_step "Restarting OpenLiteSpeed before certificate creation..."
    systemctl restart lsws
    sleep 3
    
    # Create ACME challenge directory
    local abs_doc_root="$DOC_ROOT"
    if [[ "$DOC_ROOT" == *"\$VH_ROOT"* ]]; then
        abs_doc_root="${DOC_ROOT/\$VH_ROOT/$VH_ROOT}"
    fi
    
    mkdir -p "$abs_doc_root/.well-known/acme-challenge"
    chown -R "$USERID:$USERID" "$abs_doc_root/.well-known"
    
    # Create certificate
    print_step "Creating Let's Encrypt certificate..."
    
    if $CERTBOT_PATH certonly --webroot \
        -w "$abs_doc_root" \
        -d "$DOMAIN" \
        --email "$ADMIN_EMAIL" \
        --agree-tos \
        --non-interactive; then
        
        print_success "SSL certificate created successfully!"
        
        # Auto-fix SSL listener configuration
        print_step "🔧 Auto-configuring SSL listener..."
        if fix_ssl_listener_config "$DOMAIN"; then
            print_success "SSL listener configuration updated"
        else
            print_warning "Could not auto-configure SSL listener, but certificates were created"
        fi
        
        # Restart after certificate creation
        print_step "Restarting OpenLiteSpeed with new certificates..."
        systemctl restart lsws
        sleep 5
        
        # Verify SSL is working
        print_step "🔍 Verifying SSL configuration..."
        if verify_ssl_working "$DOMAIN"; then
            print_success "✅ SSL verification successful!"
        else
            print_warning "SSL verification failed, running troubleshooter..."
            if troubleshoot_ssl "$DOMAIN"; then
                print_success "✅ SSL troubleshooting resolved the issues!"
            else
                print_error "❌ SSL troubleshooting could not resolve all issues"
                print_info "Manual verification may be required"
            fi
        fi
        
        # Setup auto-renewal
        setup_ssl_renewal
        
        return 0
    else
        print_error "SSL certificate creation failed"
        print_info "Possible causes:"
        print_info "  • Domain not accessible from internet (firewall/network issue)"
        print_info "  • DNS not pointing to this server"
        print_info "  • Let's Encrypt rate limits reached"
        print_info ""
        print_info "You can retry manually with:"
        echo "  certbot certonly --webroot -w $abs_doc_root -d $DOMAIN"
        
        # Remove SSL configuration since cert creation failed
        sed -i '/^vhssl/,/^}/d' "$LSWS_VHOST_DIR/$DOMAIN/vhost.conf"
        
        return 1
    fi
}

# Function to setup SSL auto-renewal
setup_ssl_renewal() {
    print_step "Setting up SSL auto-renewal..."
    
    # Create renewal hook
    mkdir -p /etc/letsencrypt/renewal-hooks/post
    cat > /etc/letsencrypt/renewal-hooks/post/reload-lsws.sh << 'EOF'
#!/bin/bash
systemctl reload lsws
EOF
    chmod +x /etc/letsencrypt/renewal-hooks/post/reload-lsws.sh
    
    # Add cron job
    if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
        (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --quiet") | crontab -
        print_info "Auto-renewal cron job added (runs daily at 3 AM)"
    else
        print_info "Auto-renewal already configured"
    fi
}

# Function to perform comprehensive SSL health check
ssl_health_check() {
    local domain="$1"
    
    print_step "🩺 Performing SSL health check for $domain..."
    
    local ssl_status="❌ Failed"
    local ssl_details=""
    
    # Check 1: SSL certificates exist
    if [[ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]] && [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
        ssl_details+="✅ SSL certificates found\n"
        
        # Check 2: Certificate validity
        if openssl x509 -in "/etc/letsencrypt/live/$domain/fullchain.pem" -noout -checkend 0 >/dev/null 2>&1; then
            ssl_details+="✅ SSL certificate is valid\n"
            
            # Check 3: SSL listener configuration
            if grep -q "keyFile.*$domain" "$LSWS_CONF"; then
                ssl_details+="✅ SSL listener properly configured\n"
                
                # Check 4: Port 443 listening
                if ss -tlnp | grep -q ":443.*litespeed"; then
                    ssl_details+="✅ OpenLiteSpeed listening on port 443\n"
                    
                    # Check 5: HTTPS connectivity
                    if curl -sS --connect-timeout 5 --max-time 10 -k "https://$domain/" >/dev/null 2>&1; then
                        ssl_details+="✅ HTTPS connection successful\n"
                        ssl_status="✅ Working"
                    else
                        ssl_details+="❌ HTTPS connection failed\n"
                    fi
                else
                    ssl_details+="❌ Port 443 not listening\n"
                fi
            else
                ssl_details+="❌ SSL listener not configured\n"
            fi
        else
            ssl_details+="❌ SSL certificate is invalid or expired\n"
        fi
    else
        ssl_details+="❌ SSL certificates not found\n"
    fi
    
    echo -e "$ssl_details"
    print_info "SSL Status: $ssl_status"
    
    if [[ "$ssl_status" == "✅ Working" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to show summary
show_summary() {
    echo
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    🎉 Setup Complete! 🎉                     ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo "Configuration Summary:"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ Domain:            $DOMAIN"
    echo "│ User:              $USERID"
    echo "│ Virtual Host Root: $VH_ROOT"
    echo "│ Document Root:     $DOC_ROOT"
    echo "│ Admin Email:       $ADMIN_EMAIL"
    echo "│ HTTP Access:       http://$DOMAIN"
    if [[ $SSL_ENABLED =~ ^[Yy]$ ]]; then
        echo "│"
        echo "│ 🔐 SSL Configuration:"
        if ssl_health_check "$DOMAIN" >/dev/null 2>&1; then
            echo "│ HTTPS Access:      ✅ https://$DOMAIN (Working)"
            echo "│ SSL Certificate:   ✅ Let's Encrypt (Valid)"
            echo "│ Auto-Renewal:      ✅ Enabled (3 AM daily)"
            echo "│ Port 443:          ✅ Listening"
        else
            if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
                echo "│ HTTPS Access:      ⚠️ https://$DOMAIN (Issues detected)"
                echo "│ SSL Certificate:   ⚠️ Let's Encrypt (Created but not working)"
                echo "│ Auto-Renewal:      ✅ Enabled (3 AM daily)"
                echo "│ Port 443:          ❌ Not listening or connection failed"
            else
                echo "│ HTTPS Access:      ❌ SSL setup failed"
                echo "│ SSL Certificate:   ❌ Not created"
                echo "│ Auto-Renewal:      ❌ Not configured"
                echo "│ Port 443:          ❌ Not configured"
            fi
        fi
    else
        echo "│ HTTPS Access:      ➖ Not configured"
    fi
    echo "└─────────────────────────────────────────────────────────────┘"
    echo
    echo "Next Steps:"
    echo "  1. Upload your website files to: $VH_ROOT/app/public/"
    echo "  2. Test your website: http://$DOMAIN"
    if [[ $SSL_ENABLED =~ ^[Yy]$ ]] && [[ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        echo "  3. To retry SSL later, run:"
        echo "     certbot certonly --webroot -w $VH_ROOT/app/public -d $DOMAIN"
    fi
    echo
    echo "Useful Commands:"
    echo "  • Restart OpenLiteSpeed: systemctl restart lsws"
    echo "  • Check logs: tail -f $VH_ROOT/logs/error.log"
    echo "  • Check SSL: certbot certificates"
    echo
}

# Main function
main() {
    # Show header
    show_header
    
    # Check requirements
    check_root
    check_openlitespeed
    
    # Get user input
    select_user
    select_domain
    get_admin_email
    setup_directories
    ask_ssl
    
    # Show configuration review
    echo
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    📋 Configuration Review                    ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo "Please review your configuration:"
    echo
    echo "  User ID:           $USERID"
    echo "  Domain:            $DOMAIN"
    echo "  Admin Email:       $ADMIN_EMAIL"
    echo "  Document Root:     $DOC_ROOT"
    echo "  VHost Root:        $VH_ROOT"
    echo "  SSL Enabled:       $([[ $SSL_ENABLED =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
    echo
    read -p "Continue with this configuration? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Setup cancelled"
        exit 0
    fi
    
    # Start setup
    echo
    echo -e "${WHITE}🚀 Starting Virtual Host Setup...${NC}"
    echo
    
    # Show all listeners
    show_all_listeners
    
    # Create virtual host
    add_virtualhost
    create_vhost_config
    
    # Add to HTTP listeners
    add_to_listeners "80" "HTTP"
    
    # Setup SSL if enabled
    if [[ $SSL_ENABLED =~ ^[Yy]$ ]]; then
        echo
        print_step "🔐 SSL Setup..."
        setup_ssl
    fi
    
    # Final restart and verification
    print_step "Final OpenLiteSpeed restart..."
    systemctl restart lsws
    sleep 5
    
    # Final SSL health check if SSL was enabled
    if [[ $SSL_ENABLED =~ ^[Yy]$ ]]; then
        echo
        print_step "🏁 Final SSL verification..."
        if ssl_health_check "$DOMAIN" >/dev/null 2>&1; then
            print_success "✅ SSL verification passed - HTTPS is working!"
        else
            print_warning "⚠️ SSL verification failed - running final troubleshoot..."
            if troubleshoot_ssl "$DOMAIN"; then
                print_success "✅ SSL issues resolved!"
            else
                print_warning "⚠️ Some SSL issues remain - see summary for details"
            fi
        fi
    fi
    
    # Show comprehensive summary
    show_summary
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to show help
show_help() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                    OpenLiteSpeed - VHOST CLI - Professional Edition           ║
║                               Help & Usage Guide                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝

USAGE:
  sudo ./vhost-add.sh [OPTIONS] [DOMAIN]

OPTIONS:
  --help, -h              Show this help message
  --ssl-check DOMAIN      Run SSL health check for specified domain
  --ssl-fix DOMAIN        Run SSL troubleshooter and auto-fix for specified domain

EXAMPLES:
  sudo ./vhost-add.sh
      Run interactive virtual host setup

  sudo ./vhost-add.sh --ssl-check example.com
      Check SSL configuration for example.com

  sudo ./vhost-add.sh --ssl-fix example.com
      Auto-fix SSL issues for example.com

FEATURES:
  ✅ User Management & Creation
  ✅ Domain Validation with Ping Tests
  ✅ Automatic SSL Certificate Creation
  ✅ SSL Auto-troubleshooting & Fixing
  ✅ Comprehensive Health Checks
  ✅ Backup System
  ✅ Auto-renewal Setup

For more information, see README.md
EOF
}

# Function to run standalone SSL check
standalone_ssl_check() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        print_error "Domain name required for SSL check"
        exit 1
    fi
    
    show_header
    print_step "🩺 Running standalone SSL health check for: $domain"
    
    if ssl_health_check "$domain"; then
        print_success "✅ SSL health check passed!"
        exit 0
    else
        print_error "❌ SSL health check failed!"
        exit 1
    fi
}

# Function to run standalone SSL fix
standalone_ssl_fix() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        print_error "Domain name required for SSL fix"
        exit 1
    fi
    
    show_header
    print_step "🔧 Running standalone SSL troubleshooter for: $domain"
    
    if troubleshoot_ssl "$domain"; then
        print_success "✅ SSL troubleshooting completed successfully!"
        print_info "Running final health check..."
        if ssl_health_check "$domain"; then
            print_success "✅ SSL is now working correctly!"
            exit 0
        else
            print_warning "⚠️ Some issues may remain"
            exit 1
        fi
    else
        print_error "❌ SSL troubleshooting failed!"
        exit 1
    fi
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --ssl-check)
        check_root
        check_openlitespeed
        standalone_ssl_check "$2"
        ;;
    --ssl-fix)
        check_root
        check_openlitespeed
        standalone_ssl_fix "$2"
        ;;
    *)
        # Run main function
        main "$@"
        ;;
esac