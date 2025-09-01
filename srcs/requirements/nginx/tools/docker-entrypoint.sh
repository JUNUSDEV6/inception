#!/bin/bash
set -euo pipefail

# Domaine requis (fourni par .env via docker-compose)
: "${DOMAIN_NAME:?DOMAIN_NAME non défini}"

# Générer les certificats si absents (avec SAN pour navigateurs récents)
if [ ! -f /etc/nginx/ssl/server.crt ] || [ ! -f /etc/nginx/ssl/server.key ]; then
    echo "[entrypoint] Génération certificat auto-signé pour ${DOMAIN_NAME}…"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/server.key \
        -out    /etc/nginx/ssl/server.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42School/OU=42/CN=${DOMAIN_NAME}" \
        -addext "subjectAltName=DNS:${DOMAIN_NAME}"
    echo "[entrypoint] Certificat généré."
fi

# Activer le site (link sites-available -> sites-enabled) et injecter le domaine
mkdir -p /etc/nginx/sites-enabled
cp /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/nginx/sites-enabled/default

# Vérifier la conf
nginx -t

# Démarrer nginx au premier plan (CMD)
exec "$@"
