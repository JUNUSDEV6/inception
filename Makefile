# =======================
# Variables
# =======================
PROJECT_ROOT        := $(shell pwd)
COMPOSE_FILE        := $(PROJECT_ROOT)/srcs/docker-compose.yml

# LOGIN prioritaire depuis srcs/.env, sinon whoami
LOGIN               := $(shell grep -E '^LOGIN=' srcs/.env 2>/dev/null | cut -d= -f2)
ifeq ($(LOGIN),)
LOGIN               := $(shell whoami)
endif

DATA_PATH           := /home/$(LOGIN)/data

# Détecter docker compose (V2) ou docker-compose (V1)
DC := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

# Couleurs
GREEN  = \033[0;32m
RED    = \033[0;31m
YELLOW = \033[1;33m
NC     = \033[0m

# Nom réel du projet Compose (sert à retrouver les volumes préfixés)
PROJECT_NAME        := $(shell basename $(dir $(COMPOSE_FILE)))
VOLUME_WP           := $(PROJECT_NAME)_wp_data
VOLUME_DB           := $(PROJECT_NAME)_db_data

.PHONY: all setup build up down logs ps clean fclean re help fix-perms wp-url wp-rewrite nginx-test env-check proof demo db-proof db-proof-php db-proof-sql

# =======================
# Cibles
# =======================
all: build

env-check:
	@echo "$(YELLOW)[env-check]$(NC)"
	@test -f srcs/.env && echo " - srcs/.env: OK" || (echo " - srcs/.env: ABSENT"; exit 1)
	@echo -n " - DOMAIN_NAME: "; echo "$$(grep -E '^DOMAIN_NAME=' srcs/.env | cut -d= -f2 || true)"
	@echo -n " - LOGIN: "; echo "$(LOGIN)"
	@echo -n " - DATA_PATH: "; echo "$(DATA_PATH)"

setup:
	@echo "$(YELLOW)Creating data directories...$(NC)"
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	# WordPress (www-data = 33:33)
	@sudo chown -R 33:33  $(DATA_PATH)/wordpress || true
	@sudo find $(DATA_PATH)/wordpress -type d -exec chmod 755 {} \; || true
	@sudo find $(DATA_PATH)/wordpress -type f -exec chmod 644 {} \; || true
	# MariaDB (mysql = 101:101)
	@sudo chown -R 101:101 $(DATA_PATH)/mariadb || true
	@sudo find $(DATA_PATH)/mariadb -type d -exec chmod 750 {} \; || true
	@sudo find $(DATA_PATH)/mariadb -type f -exec chmod 640 {} \; || true
	@echo "$(GREEN)Data directories ready at $(DATA_PATH)!$(NC)"

build: setup
	@echo "$(YELLOW)Building Docker images...$(NC)"
	@$(DC) -f $(COMPOSE_FILE) build
	@echo "$(GREEN)Build completed!$(NC)"

up: build
	@echo "$(YELLOW)Starting services...$(NC)"
	@$(DC) -f $(COMPOSE_FILE) up -d --build
	@$(DC) -f $(COMPOSE_FILE) ps
	@DOMAIN_NAME=$$(grep -E '^DOMAIN_NAME=' srcs/.env | cut -d= -f2 || true); \
	if [ -z "$$DOMAIN_NAME" ]; then DOMAIN_NAME=localhost; fi; \
	echo "$(GREEN)Access your site at: https://$$DOMAIN_NAME$(NC)"

down:
	@echo "$(YELLOW)Stopping services...$(NC)"
	@$(DC) -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Services stopped!$(NC)"

logs:
	@$(DC) -f $(COMPOSE_FILE) logs -f

ps:
	@$(DC) -f $(COMPOSE_FILE) ps

clean: down
	@echo "$(YELLOW)Docker prune (images, networks, cache)...$(NC)"
	@docker system prune -af
	@echo "$(GREEN)Cleanup completed!$(NC)"

# ⚠️ Destructif sur tes données locales (bind mounts)
fclean: down
	@echo "$(RED)Removing local data: $(DATA_PATH)/wordpress and $(DATA_PATH)/mariadb$(NC)"
	@sudo rm -rf $(DATA_PATH)/wordpress/* $(DATA_PATH)/mariadb/*
	@echo "$(GREEN)Local data cleaned$(NC)"

# Rebuild complet sans double build
re: fclean up

# =======================
# Utilitaires
# =======================
fix-perms:
	@echo "$(YELLOW)Fixing permissions on $(DATA_PATH)...$(NC)"
	@sudo chown -R 33:33  $(DATA_PATH)/wordpress || true
	@sudo chown -R 101:101 $(DATA_PATH)/mariadb  || true
	@echo "$(GREEN)Permissions fixed.$(NC)"

wp-url:
	@$(DC) -f $(COMPOSE_FILE) exec -T --user www-data wordpress sh -lc 'wp --path=/var/www/html option get siteurl && wp --path=/var/www/html option get home'

wp-rewrite:
	@$(DC) -f $(COMPOSE_FILE) exec -T --user www-data wordpress sh -lc 'wp --path=/var/www/html cache flush && wp --path=/var/www/html rewrite flush --hard'

nginx-test:
	@$(DC) -f $(COMPOSE_FILE) exec -T nginx sh -lc 'nginx -t && nginx -T | grep -n "server_name "'

# =======================
# Preuves pour la soutenance
# =======================
proof:
	@echo "$(YELLOW)[TLS only / Ports]$(NC)"
	@$(DC) -f $(COMPOSE_FILE) exec -T nginx sh -lc 'ss -tlnp 2>/dev/null | grep ":443" || echo "KO: 443 not listening"'
	@$(DC) -f $(COMPOSE_FILE) exec -T nginx sh -lc 'ss -tlnp 2>/dev/null | grep ":80"  || echo "OK: no listener on 80"'
	@DOMAIN_NAME=$$(grep -E '^DOMAIN_NAME=' srcs/.env | cut -d= -f2); \
	echo "$(YELLOW)[HTTP 80 check]$(NC)"; \
	curl -sS http://$$DOMAIN_NAME -I || echo "OK: HTTP (80) non accessible"
	@echo "$(YELLOW)[server_name Nginx]$(NC)"
	@$(DC) -f $(COMPOSE_FILE) exec -T nginx nginx -T | grep -n "server_name "
	@echo "$(YELLOW)[Reverse proxy vers PHP-FPM]$(NC)"
	@$(DC) -f $(COMPOSE_FILE) exec -T nginx bash -lc 'exec 3<>/dev/tcp/wordpress/9000 && echo "OK: connexion vers wordpress:9000" || echo "KO: pas de connexion"'
	@echo "$(YELLOW)[WordPress URLs]$(NC)"
	@$(DC) -f $(COMPOSE_FILE) exec -T --user www-data wordpress sh -lc 'wp --path=/var/www/html option get siteurl && wp --path=/var/www/html option get home'
	@echo "$(YELLOW)[Volumes persistants]$(NC)"
	@echo "Volumes attendus: $(VOLUME_WP) et $(VOLUME_DB)"
	@docker volume ls
	@docker volume inspect $(VOLUME_WP) $(VOLUME_DB) 2>/dev/null | grep -E "Mountpoint|/home/$(LOGIN)/data" || echo "⚠️ Vérifie que les volumes existent bien sous ces noms."
	@echo "$(YELLOW)[Images construites localement]$(NC)"
	@docker images | grep -E "inception-(nginx|wordpress|mariadb)" || echo "⚠️ Vérifie les tags d'images"

# --- Preuve DB via WP-CLI (sans mysqlcheck), robuste sans heredoc ---
db-proof:
	@echo "$(YELLOW)[MariaDB reachable from WordPress (WP-CLI, no external mysql)]$(NC)"
	@$(DC) -f $(COMPOSE_FILE) exec -T --user www-data wordpress sh -lc '\
		set -e; \
		cd /var/www/html; \
		printf "%s\n" \
"<?php" \
"global \$$wpdb;" \
"\$$wpdb->hide_errors();" \
"\$$wpdb->query(\"SELECT 1\");" \
"if (\$$wpdb->last_error) { fwrite(STDERR, \"KO: MySQL error: \".\$$wpdb->last_error.\"\\n\"); exit(1); }" \
"echo \"OK: WordPress peut interroger MariaDB\\n\";" \
> /tmp/wp_db_check.php; \
		wp eval-file /tmp/wp_db_check.php --quiet \
	'

# --- Variante: test PHP mysqli pur (sans WP-CLI), robuste sans heredoc ---
db-proof-php:
	@echo "$(YELLOW)[MariaDB reachable from WordPress (PHP mysqli)]$(NC)"
	@$(DC) -f $(COMPOSE_FILE) exec -T wordpress sh -lc '\
		set -e; \
		printf "%s\n" \
"<?php" \
"\$h=getenv(\"WP_DB_HOST\"); \$u=getenv(\"WP_DB_USER\"); \$p=getenv(\"WP_DB_PASSWORD\"); \$d=getenv(\"WP_DB_NAME\");" \
"\$mysqli=@new mysqli(\$h,\$u,\$p,\$d);" \
"if (\$mysqli->connect_errno) { fwrite(STDERR, \"MySQL connect error: \".\$mysqli->connect_error.\"\\n\"); exit(1); }" \
"\$r=\$mysqli->query(\"SELECT 1\");" \
"echo \$r ? \"OK: MySQL query successful\\n\" : \"KO: query failed\\n\";" \
> /tmp/dbcheck.php; \
		php /tmp/dbcheck.php \
	'

# --- Variante: ping côté serveur MariaDB ---
db-proof-sql:
	@echo "$(YELLOW)[MariaDB server alive (root inside mariadb)]$(NC)"
	@$(DC) -f $(COMPOSE_FILE) exec -T mariadb sh -lc '\
		mysqladmin -uroot -p"$$MARIADB_ROOT_PASSWORD" ping && echo "OK: MariaDB répond" || (echo "KO: MariaDB ne répond pas"; exit 1) \
	'

demo: up proof

help:
	@echo "$(GREEN)Targets:$(NC)"
	@echo "  setup       - Create data directories with proper permissions"
	@echo "  build       - Build Docker images"
	@echo "  up          - Start all services (build + run)"
	@echo "  down        - Stop and remove services"
	@echo "  logs        - Tail all services logs"
	@echo "  ps          - Show running containers"
	@echo "  clean       - Prune Docker resources (non-destructive)"
	@echo "  fclean      - Full cleanup (deletes local bind-mounted data)"
	@echo "  re          - Redeploy from scratch"
	@echo "  env-check   - Check env and computed paths"
	@echo "  fix-perms   - Fix owners/permissions on data dirs"
	@echo "  wp-url      - Print WordPress site/home URLs"
	@echo "  wp-rewrite  - Flush WP cache and permalinks"
	@echo "  nginx-test  - Test nginx config & server_name"
	@echo "  proof       - Show proof points for evaluation"
	@echo "  db-proof    - Check DB via WP-CLI"
	@echo "  db-proof-php- Check DB via PHP mysqli"
	@echo "  db-proof-sql- Check MariaDB server ping"
	@echo "  demo        - Run 'up' then 'proof'"
