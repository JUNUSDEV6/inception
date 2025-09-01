FROM debian:bullseye

# Éviter les prompts interactifs
ENV DEBIAN_FRONTEND=noninteractive

# Installer NGINX + OpenSSL
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx openssl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Répertoires & logs vers stdout/stderr (bonne pratique Docker)
RUN mkdir -p /etc/nginx/ssl /var/www/html \
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# Copier la conf globale + le vhost + l'entrypoint
COPY conf/nginx.conf            /etc/nginx/nginx.conf
COPY conf/default.conf          /etc/nginx/sites-available/default
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Activer l'entrypoint et désactiver tout site enabled par défaut
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
 && rm -f /etc/nginx/sites-enabled/default

EXPOSE 443

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
