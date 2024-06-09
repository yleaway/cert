#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Create directory if it doesn't exist
if [ ! -d /root/cert ]; then
    mkdir -p /root/cert
fi

# Function to generate certificate using Standalone mode
generate_standalone_certificate() {
    read -p "Enter email address: " email
    read -p "Enter domain name: " domain

    # Generate certificate
    ~/.acme.sh/acme.sh \
        --register-account -m $email \
    && ~/.acme.sh/acme.sh \
        --issue -d $domain --standalone \
        --pre-hook "service nginx stop || true" \
    && ~/.acme.sh/acme.sh \
        --install-cert -d $domain \
        --key-file /root/cert/private.key \
        --fullchain-file /root/cert/fullchain.crt \
        --reloadcmd "service nginx start || true"
}

# Function to generate certificate using DNS mode with Cloudflare
generate_dns_certificate() {
    read -p "Enter email address: " email
    read -p "Enter domain name: " domain
    read -p "Enter Cloudflare API Token: " cloudflare_api_token

    # Export CF_Token
    export CF_Token="$cloudflare_api_token"

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

# Function to enable Telegram notification
enable_telegram_notification() {
    read -p "Do you want to enable Telegram notification? (yes/no): " enable_notification
    if [ "$enable_notification" == "yes" ]; then
        read -p "Enter your Telegram Bot token: " bot_token
        read -p "Enter your Telegram Chat ID: " chat_id
        read -p "Choose notify level (0|1|2|3, default:2): " notify_level
        # Use default value 2 if no input is provided
        notify_level=${notify_level:-2}

        # Prompt the user to choose a notify mode, with default value 0 in bold
        read -p "Choose notify mode (0|1, default:0): " notify_mode
        # Use default value 0 if no input is provided
        notify_mode=${notify_mode:-0}

        echo "You chose notify level: $notify_level"
        echo "You chose notify mode: $notify_mode"

        echo -e "${GREEN}Telegram notification enabled with notify level $notify_level and notify mode $notify_mode.${NC}"
        
        # Export Token and ChatID
        export TELEGRAM_BOT_APITOKEN="$bot_token"
        export TELEGRAM_BOT_CHATID="$chat_id"
        ~/.acme.sh/acme.sh --set-notify --notify-level $notify_level --notify-mode $notify_mode --notify-hook telegram
    else
        echo -e "${RED}Telegram notification not enabled.${NC}"
    fi
}

# Main script

# Choose certificate generation mode
echo "Choose certificate generation mode:"
echo "1. Standalone"
echo "2. DNS (Cloudflare)"
echo "3. Telegram notification"
read -p "Enter your choice: " mode

case $mode in
    1)
        generate_standalone_certificate
        enable_telegram_notification
        ;;
    2)
        generate_dns_certificate
        enable_telegram_notification
        ;;
    3)
        enable_telegram_notification  
        ;;        
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Add cron job for acme.sh certificate renewal
# (crontab -l ; echo '00 3 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null') | crontab -
