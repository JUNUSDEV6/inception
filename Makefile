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

.PHONY: all setup build up down logs ps clean fclean re help fix-perms wp-url wp-rewrite nginx-test env-check

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
# Utilitaires pratiques
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
