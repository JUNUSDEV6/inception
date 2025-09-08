#!/bin/bash

# Vérifier si la base de données est déjà initialisée
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    # Initialiser MariaDB s'il n'y a pas encore de base de données
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Démarrer MariaDB en arrière-plan
    mysqld_safe --datadir=/var/lib/mysql &

    # Attendre que le service MariaDB soit prêt
    until mysqladmin ping >/dev/null 2>&1; do
        sleep 1
    done

    # Créer la base de données et configurer les utilisateurs
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Arrêter proprement MariaDB
    mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown
fi

# Lancer MariaDB en mode sécurisé au premier plan
exec mysqld_safe