#!/bin/bash

# Function to stop Nginx service if it is running
stop_nginx() {
    if systemctl is-active --quiet nginx; then
        systemctl stop nginx
    else
        echo "Nginx is not running. Skipping stop."
        return 0
    fi
}

# Create directory if it doesn't exist
if [ ! -d /root/cert/ ] || [ ! -d /root/.secrets/ ]; then
    mkdir -p /root/cert/ /root/.secrets/
fi

# Stop Nginx service if it is running
stop_nginx

# Function to generate certificate using Standalone mode
generate_standalone_certificate() {
    read -p "Enter domain name: " domain
    read -p "Enter email address: " email
    ~/.acme.sh/acme.sh \
        --register-account -m $email \
        --issue -d $domain --standalone \
        --installcert -d $domain \
        --key-file /root/cert/private.key \
        --fullchain-file /root/cert/fullchain.crt
        
}

# Function to generate certificate using DNS mode with Cloudflare
generate_dns_certificate() {
    read -p "Enter domain name: " domain
    read -p "Enter Cloudflare API Token: " cloudflare_api_token

    # Export CF_Token
    export CF_Token="$cloudflare_api_token"

    ~/.acme.sh/acme.sh \
        --register-account -m $email \
        --issue --dns dns_cf \
        -d $domain \
        -d *.$domain \
        --installcert -d $domain \
        --key-file /root/cert/private.key \
        --fullchain-file /root/cert/fullchain.crt
        
}

# Main script

# Choose certificate generation mode
echo "Choose certificate generation mode:"
echo "1. Standalone"
echo "2. DNS (Cloudflare)"
read -p "Enter your choice (1 or 2): " mode

case $mode in
    1)
        generate_standalone_certificate
        ;;
    2)
        generate_dns_certificate
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Renew certificate every 60 days
(crontab -l ; echo '0 0 */60 * * service nginx stop && ~/.acme.sh/acme.sh --cron --force && service nginx start') | crontab -

