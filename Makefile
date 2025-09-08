NAME = inception
DATA_PATH := /home/$(USER)/data
HOSTS_CMD := echo "127.0.0.1 yohanafi.42.fr" | sudo tee -a /etc/hosts
CLEAN_CMD := sudo rm -rf

GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
RESET := \033[0m

export DATA_PATH

all: setup $(NAME)

setup:
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@sudo chown -R $(USER):$(USER) $(DATA_PATH)
	@sudo chmod -R 755 $(DATA_PATH)
	@$(HOSTS_CMD)

$(NAME):
	@cd srcs && docker compose up --build -d

clean:
	@cd srcs && docker compose down

fclean: clean
	@docker stop $$(docker ps -qa) 2>/dev/null || true
	@docker rm $$(docker ps -qa) 2>/dev/null || true
	@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker network rm $$(docker network ls -q) 2>/dev/null || true
	@$(CLEAN_CMD) $(DATA_PATH)/wordpress
	@$(CLEAN_CMD) $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress        
	@mkdir -p $(DATA_PATH)/mariadb

status:
	@echo "$(BLUE)Statut des conteneurs:$(RESET)"
	@docker ps -a
	@echo "\n$(BLUE)Réseaux:$(RESET)"
	@docker network ls
	@echo "\n$(BLUE)Volumes:$(RESET)"
	@docker volume ls

check:
	@echo "$(BLUE)Vérification des services...$(RESET)"
	@docker ps | grep -q nginx && echo "$(GREEN)✓ NGINX est en cours d'exécution$(RESET)" || echo "$(RED)✗ NGINX n'est pas en cours d'exécution$(RESET)"
	@docker ps | grep -q wordpress && echo "$(GREEN)✓ WordPress est en cours d'exécution$(RESET)" || echo "$(RED)✗ WordPress n'est pas en cours d'exécution$(RESET)"
	@docker ps | grep -q mariadb && echo "$(GREEN)✓ MariaDB est en cours d'exécution$(RESET)" || echo "$(RED)✗ MariaDB n'est pas en cours d'exécution$(RESET)"
	@curl -s -k -o /dev/null -w "$(GREEN)✓ Site web accessible: %{http_code}$(RESET)\n" https://yohanafi.42.fr || true

reboot:
	@cd srcs && docker compose restart

re: fclean all

.PHONY: all setup clean fclean reboot re
