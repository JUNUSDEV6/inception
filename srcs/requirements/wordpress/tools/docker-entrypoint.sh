#!/bin/bash
set -euo pipefail

# Répertoires runtime
mkdir -p /run/php

# Droits sur le volume /var/www/html
chown -R www-data:www-data /var/www/html || true
find /var/www/html -type d -exec chmod 755 {} \; || true
find /var/www/html -type f -exec chmod 644 {} \; || true

# Auto-install si l'instance n'existe pas encore
if [ ! -f /var/www/html/wp-config.php ]; then
  echo "[wordpress] Installation WordPress…"
  su -s /bin/sh -c '
    set -e
    cd /var/www/html
    wp core download --allow-root

    wp config create \
      --dbname="$WP_DB_NAME" \
      --dbuser="$WP_DB_USER" \
      --dbpass="$WP_DB_PASSWORD" \
      --dbhost="$WP_DB_HOST" \
      --skip-check \
      --allow-root

    wp core install \
      --url="https://$DOMAIN_NAME" \
      --title="Inception WordPress" \
      --admin_user="$WP_ADMIN_USER" \
      --admin_password="$WP_ADMIN_PASSWORD" \
      --admin_email="$WP_ADMIN_EMAIL" \
      --skip-email \
      --allow-root

    if [ -n "${WP_USER:-}" ] && [ -n "${WP_USER_PASSWORD:-}" ] && [ -n "${WP_USER_EMAIL:-}" ]; then
      wp user create "$WP_USER" "$WP_USER_EMAIL" --user_pass="$WP_USER_PASSWORD" --role=author --allow-root || true
    fi

    wp option update siteurl "https://$DOMAIN_NAME" --allow-root
    wp option update home    "https://$DOMAIN_NAME" --allow-root
    wp cache flush --allow-root
  ' www-data
else
  echo "[wordpress] Instance WP détectée — mise à jour des URLs…"
  su -s /bin/sh -c '
    set -e
    cd /var/www/html
    wp option update siteurl "https://$DOMAIN_NAME" --allow-root || true
    wp option update home    "https://$DOMAIN_NAME" --allow-root || true
    wp cache flush --allow-root || true
  ' www-data
fi

# Lancer php-fpm en foreground (PID 1)
exec "$@"
