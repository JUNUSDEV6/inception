#!/bin/bash
set -e

# Generate SSL certificates if they don't exist
if [ ! -f /etc/nginx/ssl/server.crt ]; then
    echo "Generating SSL certificates..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/server.key \
        -out /etc/nginx/ssl/server.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42School/OU=42/CN=$DOMAIN_NAME"
    echo "SSL certificates generated!"
fi

# Replace domain name in configuration
sed -i "s/DOMAIN_NAME/$DOMAIN_NAME/g" /etc/nginx/sites-available/default

# Enable site
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

# Start NGINX
exec "$@"