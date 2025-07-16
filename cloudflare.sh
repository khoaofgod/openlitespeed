#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check if SERVER_IP is loaded from .env
if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}ERROR: SERVER_IP not found in .env file${NC}"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cloudflare DNS Management for OpenLiteSpeed VHosts ===${NC}"
echo -e "${BLUE}Server IP: ${SERVER_IP}${NC}"
echo ""

# Function to get zone ID for a domain
get_zone_id() {
    local domain=$1
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain}" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json")
    
    echo "$response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4
}

# Function to delete existing DNS record
delete_dns_record() {
    local zone_id=$1
    local record_type=$2
    local record_name=$3
    
    local record_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=${record_type}&name=${record_name}" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
    
    if [ ! -z "$record_id" ]; then
        curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
            -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
            -H "Content-Type: application/json" > /dev/null
        return 0
    fi
    return 1
}

# Function to create A record
create_a_record() {
    local zone_id=$1
    local record_name=$2
    local ip=$3
    
    local response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"${record_name}\",\"content\":\"${ip}\",\"ttl\":1}")
    
    if echo "$response" | grep -q '"success":true'; then
        return 0
    else
        return 1
    fi
}

# Function to process domain
process_domain() {
    local domain=$1
    
    echo -e "${YELLOW}Processing domain: ${domain}${NC}"
    
    # Get zone ID
    zone_id=$(get_zone_id "$domain")
    
    if [ -z "$zone_id" ]; then
        echo -e "${RED}  ✗ Domain not found in Cloudflare account${NC}"
        return 1
    fi
    
    echo -e "${GREEN}  ✓ Found zone ID: ${zone_id}${NC}"
    
    # Process @ record
    echo -e "  Processing @ record..."
    delete_dns_record "$zone_id" "A" "$domain"
    delete_dns_record "$zone_id" "CNAME" "$domain"
    
    if create_a_record "$zone_id" "$domain" "$SERVER_IP"; then
        echo -e "${GREEN}    ✓ Created A record: @ → ${SERVER_IP}${NC}"
    else
        echo -e "${RED}    ✗ Failed to create A record for @${NC}"
    fi
    
    # Process www record
    echo -e "  Processing www record..."
    delete_dns_record "$zone_id" "A" "www.${domain}"
    delete_dns_record "$zone_id" "CNAME" "www.${domain}"
    
    if create_a_record "$zone_id" "www.${domain}" "$SERVER_IP"; then
        echo -e "${GREEN}    ✓ Created A record: www → ${SERVER_IP}${NC}"
    else
        echo -e "${RED}    ✗ Failed to create A record for www${NC}"
    fi
    
    echo ""
}

# Get all vhosts from OpenLiteSpeed
echo -e "${BLUE}Scanning OpenLiteSpeed vhosts...${NC}"
vhosts=$(sudo ls -1 /usr/local/lsws/conf/vhosts/ | grep -v "^Example$")

if [ -z "$vhosts" ]; then
    echo -e "${RED}No vhosts found in OpenLiteSpeed configuration${NC}"
    exit 1
fi

echo -e "${GREEN}Found $(echo "$vhosts" | wc -l) vhosts${NC}"
echo ""

# Process each domain
for vhost in $vhosts; do
    # Skip mail subdomains and other subdomains, focus on main domains
    if [[ "$vhost" =~ ^mail\. ]] || [[ "$vhost" =~ ^www\. ]] || [[ "$vhost" =~ ^.*\..*\..*$ ]]; then
        continue
    fi
    
    process_domain "$vhost"
done

echo -e "${BLUE}=== DNS Management Complete ===${NC}"