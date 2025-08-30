FROM debian:bullseye

# Install MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/docker-entrypoint.sh /usr/local/bin/

# Make script executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create mysql directories
RUN mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql

# Expose port
EXPOSE 3306

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld"]