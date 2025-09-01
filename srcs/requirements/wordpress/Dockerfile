FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# PHP 7.4 + extensions utiles pour WordPress
RUN apt-get update && apt-get install -y --no-install-recommends \
    php7.4-fpm php7.4-cli php7.4-mysqli php7.4-curl php7.4-xml php7.4-zip php7.4-gd php7.4-mbstring \
    curl ca-certificates less vim-tiny \
 && rm -rf /var/lib/apt/lists/*

# Dossiers requis
RUN mkdir -p /var/www/html \
 && mkdir -p /run/php \
 && chown -R www-data:www-data /var/www/html

# Forcer php-fpm à écouter en TCP inter-conteneurs + garder l'env
RUN sed -ri "s~^\\s*;?\\s*listen\\s*=.*$~listen = 0.0.0.0:9000~" /etc/php/7.4/fpm/pool.d/www.conf \
 && grep -q "^\\s*clear_env\\s*=\\s*no" /etc/php/7.4/fpm/pool.d/www.conf || echo "clear_env = no" >> /etc/php/7.4/fpm/pool.d/www.conf

# (Optionnel) WP-CLI pour l’admin
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
 && chmod +x /usr/local/bin/wp

# Entrypoint minimal
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm7.4", "-F"]
