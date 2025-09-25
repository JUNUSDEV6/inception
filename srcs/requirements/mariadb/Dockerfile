# ~/inception/srcs/requirements/mariadb/Dockerfile
FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY ./tool/mariadb.sh /usr/local/bin/mariadb.sh

# Fix potential line ending issues
RUN chmod +x /usr/local/bin/mariadb.sh && \
	sed -i 's/\r$//' /usr/local/bin/mariadb.sh 

EXPOSE 3306

CMD ["/usr/local/bin/mariadb.sh"]