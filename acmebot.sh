#!/bin/bash

# Create directory if it doesn't exist
if [ ! -d /root/cert ]; then
    mkdir -p /root/cert
fi

# Function to generate certificate using Standalone mode
generate_standalone_certificate() {
    read -p "Enter email address: " email
    read -p "Enter domain name: " domain

    # Check if nginx is running
    nginx_running=$(ps -ef | grep -v grep | grep nginx)

    # Generate certificate
    if [ -n "$nginx_running" ]; then
        ~/.acme.sh/acme.sh \
            --register-account -m $email \
        && ~/.acme.sh/acme.sh \
            --issue -d $domain --standalone \
            --pre-hook "service nginx stop" \
        && ~/.acme.sh/acme.sh \
            --install-cert -d $domain \
            --key-file /root/cert/private.key \
            --fullchain-file /root/cert/fullchain.crt \
            --post-hook "service nginx start"
    else
        ~/.acme.sh/acme.sh \
            --register-account -m $email \
        && ~/.acme.sh/acme.sh \
            --issue -d $domain --standalone \
        && ~/.acme.sh/acme.sh \
            --install-cert -d $domain \
            --key-file /root/cert/private.key \
            --fullchain-file /root/cert/fullchain.crt
    fi
}

# Function to generate certificate using DNS mode with Cloudflare
generate_dns_certificate() {
    read -p "Enter email address: " email
    read -p "Enter domain name: " domain
    read -p "Enter Cloudflare API Token: " cloudflare_api_token
    # read -p "Enter Cloudflare Account ID: " cf_account_id

    # Export CF_Token
    export CF_Token="$cloudflare_api_token"
    # Export CF_Token and CF_Account_ID
    # export CF_Token="$cloudflare_api_token" && export CF_Account_ID="$cf_account_id"

    # Check if the domain starts with '*.'
    if [[ $domain == "*."* ]]; then
        # Extract base domain from input (remove leading '*')
        base_domain=${domain#*.}
        domains="-d $base_domain -d *.$base_domain"
    else
        domains="-d $domain"
        base_domain=$domain
    fi

    # Generate certificate
    ~/.acme.sh/acme.sh --register-account -m $email \
    && ~/.acme.sh/acme.sh --issue --dns dns_cf $domains \
    && ~/.acme.sh/acme.sh \
        --installcert -d $base_domain \
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


# (crontab -l ; echo "00 03 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null") | crontab -
