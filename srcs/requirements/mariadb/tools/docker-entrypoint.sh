#!/bin/bash
set -euo pipefail

# Variables d'env (fournies par docker-compose via .env)
: "${MARIADB_ROOT_PASSWORD:?MARIADB_ROOT_PASSWORD manquant}"
: "${MARIADB_DATABASE:?MARIADB_DATABASE manquant}"
: "${MARIADB_USER:?MARIADB_USER manquant}"
: "${MARIADB_PASSWORD:?MARIADB_PASSWORD manquant}"

# Préparer /run/mysqld
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Initialisation au premier démarrage (si /var/lib/mysql/mysql absent)
if [ ! -d /var/lib/mysql/mysql ]; then
  echo "[mariadb] Initialisation du datadir…"
  chown -R mysql:mysql /var/lib/mysql
  mysqld --user=mysql --initialize-insecure

  echo "[mariadb] Démarrage temporaire (socket)…"
  mysqld --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  # Attendre disponibilité via le socket
  for i in {1..30}; do
    mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock ping && break
    sleep 1
  done

  echo "[mariadb] Création root/db/user…"
  mysql --protocol=socket --socket=/run/mysqld/mysqld.sock <<-SQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
    CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
    FLUSH PRIVILEGES;
SQL

  echo "[mariadb] Arrêt du serveur temporaire…"
  mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock -p"${MARIADB_ROOT_PASSWORD}" shutdown || kill "$pid" || true
fi

echo "[mariadb] Lancement MariaDB…"
exec "$@"
