#!/bin/bash
set -e

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
while ! mysqladmin ping -h mariadb -u root -p"$MYSQL_ROOT_PASSWORD" --silent; do
    echo "Waiting for database connection..."
    sleep 2
done

# Test database connection specifically for WordPress user
echo "Testing WordPress database connection..."
while ! mysql -h mariadb -u "$WP_DB_USER" -p"$WP_DB_PASSWORD" -e "SELECT 1" 2>/dev/null; do
    echo "WordPress user cannot connect to database, waiting..."
    sleep 2
done

echo "Database connection successful!"

# Change to WordPress directory
cd /var/www/html

# Check if WordPress is already installed and working
if [ -f wp-config.php ] && wp core is-installed --allow-root 2>/dev/null; then
    echo "WordPress is already installed and configured"
else
    echo "Setting up WordPress..."
    
    # Clean up any partial installation
    rm -f wp-config.php
    
    # Download WordPress if not present or corrupted
    if [ ! -f wp-load.php ]; then
        wp core download --allow-root
    fi
    
    # Create wp-config.php
    wp config create \
        --dbname="$WP_DB_NAME" \
        --dbuser="$WP_DB_USER" \
        --dbpass="$WP_DB_PASSWORD" \
        --dbhost="$WP_DB_HOST" \
        --allow-root
    
    # Install WordPress only if not already installed
    if ! wp core is-installed --allow-root 2>/dev/null; then
        wp core install \
            --url="https://$DOMAIN_NAME" \
            --title="Inception WordPress" \
            --admin_user="$WP_ADMIN_USER" \
            --admin_password="$WP_ADMIN_PASSWORD" \
            --admin_email="$WP_ADMIN_EMAIL" \
            --allow-root
        
        # Create additional user
        wp user create \
            "$WP_USER" \
            "$WP_USER_EMAIL" \
            --user_pass="$WP_USER_PASSWORD" \
            --role=author \
            --allow-root 2>/dev/null || echo "User may already exist"
    fi
    
    echo "WordPress setup completed!"
fi

# Fix permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Start PHP-FPM
exec "$@"