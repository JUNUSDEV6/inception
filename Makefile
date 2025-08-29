# Variables
DOCKER_COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/&(schell whoami)/DATA_PATH

#colors for output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[1;33m
NC = \033[0m # No Color

.PHONY: all build up down clean fclean re logs ps

# default target
all: build

#create data directories
setup:
	@echo "$"