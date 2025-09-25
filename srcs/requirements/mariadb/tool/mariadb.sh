#!/bin/bash

# Préparation des répertoires
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

# Initialisation si nécessaire
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Première initialisation..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Démarrer MariaDB en arrière-plan pour configuration
echo "Démarrage temporaire pour configuration..."
mysqld --user=mysql &
MYSQL_PID=$!

# Attendre que MariaDB soit prêt
echo "Attente de MariaDB..."
while ! mysqladmin ping --silent 2>/dev/null; do
    sleep 1
done

echo "Configuration de la base de données..."
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo "Configuration terminée, redémarrage..."
# Arrêter proprement
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait $MYSQL_PID

# Démarrage définitif
echo "Démarrage final de MariaDB..."
exec mysqld --user=mysql