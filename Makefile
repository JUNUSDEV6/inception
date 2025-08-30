# Variables pour production (VM)
DOCKER_COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/$(shell whoami)/data

# Colors
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[1;33m
NC = \033[0m

.PHONY: all build up down clean fclean re logs ps

all: build

setup:
	@echo "$(YELLOW)Creating data directories...$(NC)"
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@chmod 755 $(DATA_PATH)/wordpress
	@chmod 755 $(DATA_PATH)/mariadb
	@echo "$(GREEN)Data directories created!$(NC)"

build: setup
	@echo "$(YELLOW)Building Docker images...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) build
	@echo "$(GREEN)Build completed!$(NC)"

up: build
	@echo "$(YELLOW)Starting services...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) up -d
	@echo "$(GREEN)Services started!$(NC)"
	@echo "$(GREEN)Access your site at: https://$(shell grep DOMAIN_NAME srcs/.env | cut -d '=' -f2)$(NC)"

down:
	@echo "$(YELLOW)Stopping services...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) down
	@echo "$(GREEN)Services stopped!$(NC)"

logs:
	@docker-compose -f $(DOCKER_COMPOSE_FILE) logs -f

ps:
	@docker-compose -f $(DOCKER_COMPOSE_FILE) ps

clean: down
	@echo "$(YELLOW)Cleaning containers and images...$(NC)"
	@docker system prune -af
	@echo "$(GREEN)Cleanup completed!$(NC)"

fclean: clean
	@echo "$(YELLOW)Removing volumes and data...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) down --volumes
	@sudo rm -rf $(DATA_PATH)/wordpress/*
	@sudo rm -rf $(DATA_PATH)/mariadb/*
	@echo "$(GREEN)Full cleanup completed!$(NC)"

re: fclean all up

help:
	@echo "$(GREEN)Available targets:$(NC)"
	@echo "  setup  - Create data directories"
	@echo "  build  - Build Docker images"
	@echo "  up     - Start all services"
	@echo "  down   - Stop all services"
	@echo "  logs   - View service logs"
	@echo "  ps     - Show running containers"
	@echo "  clean  - Clean containers and images"
	@echo "  fclean - Full cleanup including volumes"
	@echo "  re     - Rebuild everything"