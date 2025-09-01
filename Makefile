# =======================
# Variables
# =======================
PROJECT_ROOT        := $(shell pwd)
DOCKER_COMPOSE_FILE := $(PROJECT_ROOT)/srcs/docker-compose.yml
DATA_PATH           := /home/$(shell whoami)/data

# Détecter docker compose (V2) ou docker-compose (V1)
DC := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

# Couleurs
GREEN  = \033[0;32m
RED    = \033[0;31m
YELLOW = \033[1;33m
NC     = \033[0m

.PHONY: all setup build up down logs ps clean fclean re help

# =======================
# Cibles
# =======================
all: build

setup:
	@echo "$(YELLOW)Creating data directories...$(NC)"
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	# Donner les bons owners par dossier (ne pas chown tout $(DATA_PATH))
	@sudo chown -R 33:33  $(DATA_PATH)/wordpress || true
	@sudo chown -R 101:101 $(DATA_PATH)/mariadb   || true
	# Permissions raisonnables
	@sudo find $(DATA_PATH)/wordpress -type d -exec chmod 755 {} \; || true
	@sudo find $(DATA_PATH)/wordpress -type f -exec chmod 644 {} \; || true
	@sudo find $(DATA_PATH)/mariadb   -type d -exec chmod 750 {} \; || true
	@sudo find $(DATA_PATH)/mariadb   -type f -exec chmod 640 {} \; || true
	@echo "$(GREEN)Data directories ready!$(NC)"

build: setup
	@echo "$(YELLOW)Building Docker images...$(NC)"
	@$(DC) -f $(DOCKER_COMPOSE_FILE) build
	@echo "$(GREEN)Build completed!$(NC)"

up: build
	@echo "$(YELLOW)Starting services...$(NC)"
	@$(DC) -f $(DOCKER_COMPOSE_FILE) up -d --build
	@$(DC) -f $(DOCKER_COMPOSE_FILE) ps
	@echo "$(GREEN)Access your site at: https://$(shell grep -E '^DOMAIN_NAME=' srcs/.env | cut -d '=' -f2)$(NC)"

down:
	@echo "$(YELLOW)Stopping services...$(NC)"
	@$(DC) -f $(DOCKER_COMPOSE_FILE) down
	@echo "$(GREEN)Services stopped!$(NC)"

logs:
	@$(DC) -f $(DOCKER_COMPOSE_FILE) logs -f

ps:
	@$(DC) -f $(DOCKER_COMPOSE_FILE) ps

clean: down
	@echo "$(YELLOW)Docker prune (images, networks, cache)...$(NC)"
	@docker system prune -af
	@echo "$(GREEN)Cleanup completed!$(NC)"

# ⚠️ Supprime les données locales WordPress/MariaDB
fclean: down
	@echo "$(RED)Removing local data directories (wordpress/mariadb)$(NC)"
	@sudo rm -rf $(DATA_PATH)/wordpress/* $(DATA_PATH)/mariadb/*
	@echo "$(GREEN)Local data cleaned$(NC)"

re: fclean all up

help:
	@echo "$(GREEN)Available targets:$(NC)"
	@echo "  setup  - Create data directories with proper permissions"
	@echo "  build  - Build Docker images"
	@echo "  up     - Start all services (build + run)"
	@echo "  down   - Stop and remove services"
	@echo "  logs   - Tail all services logs"
	@echo "  ps     - Show running containers"
	@echo "  clean  - Prune Docker resources (no data deletion)"
	@echo "  fclean - Full cleanup including local data volumes"
	@echo "  re     - Rebuild everything from scratch"

docker compose -f srcs/docker-compose.yml exec -T --user www-data wordpress sh -lc '
set -e
WP_PATH="";
for p in /var/www/html /var/www/wordpress /usr/src/wordpress /var/www; do
  if [ -f "$p/wp-config.php" ] || [ -d "$p/wp-admin" ]; then
    WP_PATH="$p"; break;
  fi
done
[ -n "$WP_PATH" ] || { echo "WP introuvable"; exit 1; }
echo "WP_PATH=$WP_PATH"
wp --path="$WP_PATH" config get DB_NAME
wp --path="$WP_PATH" config get DB_USER
wp --path="$WP_PATH" config get DB_PASSWORD
wp --path="$WP_PATH" config get DB_HOST
'