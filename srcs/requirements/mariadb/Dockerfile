FROM debian:bullseye

RUN apt update -y && apt upgrade -y && apt-get install mariadb-server -y

RUN mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    && chmod -R 770 /var/lib/mysql /var/run/mysqld

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

COPY tool/mariadb.sh /usr/local/bin/mariadb.sh
RUN chmod +x /usr/local/bin/mariadb.sh

EXPOSE 3306

CMD ["/usr/local/bin/mariadb.sh"]
