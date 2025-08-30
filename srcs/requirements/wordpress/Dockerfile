FROM debian:bullseye

# Install PHP-FPM and extensions
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    curl \
    wget \
    unzip \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Download and install WP-CLI
RUN curl -L https://github.com/wp-cli/wp-cli/releases/download/v2.8.1/wp-cli-2.8.1.phar -o wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info || echo "WP-CLI ready"

# Copy configuration
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/docker-entrypoint.sh /usr/local/bin/

# Make script executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create directories
RUN mkdir -p /var/www/html /run/php \
    && chown -R www-data:www-data /var/www/html /run/php

# Expose port
EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm7.4", "-F"]