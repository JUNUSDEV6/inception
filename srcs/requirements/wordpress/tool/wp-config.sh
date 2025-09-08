#!/bin/bash

echo "Démarrage du script WordPress..."

# Attente que MariaDB soit prêt
echo "Attente de MariaDB..."
until mysql -h mariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT 1" >/dev/null 2>&1; do
    echo "MariaDB non disponible, attente..."
    sleep 3
done
echo "MariaDB est prêt !"
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
cd /var/www/html

# Vérification si WordPress est installé
if [ ! -s "wp-config.php" ]; then
    echo "Installation de WordPress..."
    
    # Nettoyer complètement le répertoire
    rm -rf *
    
    # Téléchargement de WordPress
    echo "Téléchargement de WordPress..."
    wp core download --allow-root --path=/var/www/html
    
    # Vérifier que le téléchargement a réussi
    if [ ! -f "/var/www/html/wp-config-sample.php" ]; then
        echo "ERREUR: Échec du téléchargement de WordPress"
        exit 1
    fi

    # Création du fichier de configuration
    echo "Configuration de WordPress..."
    wp config create --allow-root \
        --path=/var/www/html \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb \

    # Installation de WordPress
    echo "Installation de WordPress..."
   wp core install --allow-root --url=$WP_URL --title=$WP_TITLE --admin_user=$WP_ADMIN_USER --admin_password=$WP_ADMIN_PASSWORD --admin_email=$WP_ADMIN_EMAIL

    # Création d'un utilisateur supplémentaire
    echo "Création de l'utilisateur supplémentaire..."
    wp user create ${WP_USER} ${WP_USER_EMAIL} \
        --allow-root \
        --path=/var/www/html \
        --role=author \
        --user_pass=${WP_USER_PASSWORD}
        
    echo "WordPress installé et configuré avec succès !"
else
    echo "WordPress est déjà installé"
fi

# Ajuster les permissions


echo "Démarrage de PHP-FPM..."
# Démarrer PHP-FPM en premier plan 
exec php-fpm7.4 -F
