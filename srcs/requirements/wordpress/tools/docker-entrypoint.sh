#!/bin/bash
set -euo pipefail

# Assurer les répertoires requis à chaque démarrage
mkdir -p /run/php
chown -R www-data:www-data /var/www/html || true
find /var/www/html -type d -exec chmod 755 {} \; || true
find /var/www/html -type f -exec chmod 644 {} \; || true

# Si tu veux, tu peux ajouter ici une attente DB (mais depends_on: healthy suffit)

# Lancer le process final au premier plan (PID 1)
exec "$@"
