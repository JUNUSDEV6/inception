FROM debian:bullseye

RUN apt update -y && apt upgrade -y && \
    apt install -y php-fpm php-mysql mariadb-client curl \
    php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip

RUN mkdir -p /run/php && \
    sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/g' /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i 's/;clear_env = no/clear_env = no/g' /etc/php/7.4/fpm/pool.d/www.conf

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/
COPY tool/wp-config.sh /usr/local/bin/wp-config.sh
RUN chmod +x /usr/local/bin/wp-config.sh



EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-config.sh"]
