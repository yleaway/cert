#!/bin/bash

# Create directory if it doesn't exist
if [ ! -d /root/cert/ ] || [ ! -d /root/.secrets/ ]; then
    mkdir -p /root/cert/ /root/.secrets/
fi

# Function to generate certificate using Standalone mode
generate_standalone_certificate() {
    read -p "Enter domain name: " domain

    # Generate certificate
    certbot certonly \
        --standalone \
        -d $domain \
        --deploy-hook "cp /etc/letsencrypt/live/$domain/fullchain.pem /root/cert/fullchain.crt && cp /etc/letsencrypt/live/$domain/privkey.pem /root/cert/private.key"
}

# Function to generate certificate using DNS mode with Cloudflare
generate_dns_certificate() {
    read -p "Enter domain name: " domain
    read -p "Enter Cloudflare API Token: " cloudflare_api_token

    # Check if the domain starts with '*.'
    if [[ $domain == "*."* ]]; then
        # Extract base domain from input (remove leading '*')
        base_domain=${domain#*.}
        domains="-d $base_domain -d *.$base_domain"
    else
        domains="-d $domain"
        base_domain=$domain
    fi

    # Write Cloudflare credentials to .secrets/cloudflare.ini file
    cat > ~/.secrets/cloudflare.ini <<EOF
# Cloudflare API credentials used by Certbot
dns_cloudflare_api_token = $cloudflare_api_token
EOF

    chmod 600 ~/.secrets/cloudflare.ini  # Ensure correct permissions

    # Generate certificate
    certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
        --dns-cloudflare-propagation-seconds 60 \
        $domains \
        --deploy-hook "cp /etc/letsencrypt/live/$base_domain/fullchain.pem /root/cert/fullchain.crt && cp /etc/letsencrypt/live/$base_domain/privkey.pem /root/cert/private.key"
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
(crontab -l ; echo "0 0 */60 * * certbot renew --quiet") | crontab -
#(crontab -l ; echo '0 0 */60 * * certbot renew --quiet --pre-hook "service nginx stop" --post-hook "service nginx start"') | crontab -
