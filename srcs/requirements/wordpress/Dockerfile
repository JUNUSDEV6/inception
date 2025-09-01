FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# PHP 7.4 + extensions WordPress
RUN apt-get update && apt-get install -y --no-install-recommends \
    php7.4-fpm php7.4-cli php7.4-mysqli php7.4-curl php7.4-xml php7.4-zip php7.4-gd php7.4-mbstring \
    curl ca-certificates less \
 && rm -rf /var/lib/apt/lists/*

# Dossiers requis
RUN mkdir -p /var/www/html /run/php \
 && chown -R www-data:www-data /var/www/html

# Pool FPM (notre conf www.conf)
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# WP-CLI (optionnel mais pratique)
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
 && chmod +x /usr/local/bin/wp

# Entrypoint (droits + (auto)install + URLs + lancement FPM)
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm7.4", "-F"]
