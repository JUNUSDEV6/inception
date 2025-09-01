FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server mariadb-client ca-certificates tzdata \
 && rm -rf /var/lib/apt/lists/*

# Notre conf + entrypoint
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
 && mkdir -p /run/mysqld \
 && chown -R mysql:mysql /run/mysqld

EXPOSE 3306

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld", "--user=mysql", "--console"]
