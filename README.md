# 🐳 Inception - Docker Infrastructure Project

A complete web infrastructure using Docker containers with NGINX, WordPress, and MariaDB services. This project creates a secure, scalable environment for hosting WordPress websites using best practices for containerization.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Available Commands](#available-commands)
- [Services](#services)
- [Security Features](#security-features)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)

## 🔍 Overview

This project implements a complete web infrastructure using Docker containers:
- **NGINX**: Reverse proxy and web server with SSL/TLS encryption
- **WordPress**: Content management system with PHP-FPM
- **MariaDB**: Database server for WordPress data storage

All services run in separate Docker containers and communicate through a dedicated network, ensuring isolation and security.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     NGINX       │    │   WordPress     │    │    MariaDB      │
│   (Port 443)    │◄───│   (PHP-FPM)     │◄───│   (Database)    │
│   SSL/TLS       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                        │                        │
         │                        ▼                        ▼
    User Request              wordpress_data          mariadb_data
   (HTTPS Only)              (Volume Mount)          (Volume Mount)
```

## 📋 Prerequisites

- Docker Engine (20.10+)
- Docker Compose (2.0+)
- Make utility
- Linux/Unix system with sudo privileges
- At least 2GB of free disk space

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Configure environment variables**
   ```bash
   cp srcs/env.example srcs/.env
   nano srcs/.env  # Edit with your configuration
   ```

3. **Set up and start the infrastructure**
   ```bash
   make all
   ```

4. **Access your website**
   - Open your browser and go to `https://yourdomain.42.fr`
   - Accept the self-signed certificate warning (for development)

## 🔧 Usage

### Basic Operations

```bash
# Start all services
make all

# Stop all services
make clean

# Complete cleanup (removes containers, images, volumes)
make fclean

# Restart services
make reboot

# Check service status
make status

# Verify all services are working
make check

# Rebuild and restart everything
make re
```

### Development Mode

For development with live reloading:
```bash
# Start development environment
make -f Makefile.dev dev-up

# Stop development environment
make -f Makefile.dev dev-down
```

## ⚙️ Configuration

### Environment Variables

Edit `srcs/.env` with your specific configuration:

```env
# Domain configuration
DOMAIN_NAME=yourdomain.42.fr

# Database configuration
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
MYSQL_PASSWORD=your_secure_db_password

# WordPress Admin configuration
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=your_secure_admin_password
WP_ADMIN_EMAIL=admin@yourdomain.42.fr

# WordPress User configuration
WP_USER=user
WP_USER_EMAIL=user@yourdomain.42.fr
WP_USER_PASSWORD=your_secure_user_password
```

### Host Configuration

Add your domain to `/etc/hosts`:
```bash
echo "127.0.0.1 yourdomain.42.fr" | sudo tee -a /etc/hosts
```

## 📝 Available Commands

| Command | Description |
|---------|-------------|
| `make all` | Set up directories, configure hosts, and start all services |
| `make setup` | Create data directories and configure system |
| `make clean` | Stop all containers |
| `make fclean` | Complete cleanup (containers, images, volumes, data) |
| `make status` | Show status of all containers, networks, and volumes |
| `make check` | Verify that all services are running correctly |
| `make reboot` | Restart all services |
| `make re` | Full rebuild (fclean + all) |

## 🔧 Services

### NGINX
- **Port**: 443 (HTTPS only)
- **Features**: SSL/TLS encryption, reverse proxy, static file serving
- **Configuration**: Custom SSL certificates, security headers
- **Health Check**: Accessible via web browser

### WordPress
- **Technology**: PHP-FPM with WordPress CMS
- **Features**: Auto-installation, user creation, theme support
- **Dependencies**: MariaDB for data storage
- **Volumes**: Persistent storage for uploads and themes

### MariaDB
- **Port**: Internal only (not exposed to host)
- **Features**: Optimized for WordPress, automatic database creation
- **Backup**: Data persisted in mounted volumes
- **Security**: User isolation, password authentication

## 🔐 Security Features

- **HTTPS Only**: All traffic encrypted with SSL/TLS
- **Network Isolation**: Services communicate through dedicated Docker network
- **User Privileges**: Non-root users in containers where possible
- **Data Persistence**: Secure volume mounting with proper permissions
- **Password Protection**: Environment variable-based secret management

## 🔧 Troubleshooting

### Common Issues

1. **Port 443 already in use**
   ```bash
   sudo lsof -i :443
   # Stop the conflicting service or change the port
   ```

2. **Permission denied on data directories**
   ```bash
   sudo chown -R $USER:$USER /home/$USER/data
   sudo chmod -R 755 /home/$USER/data
   ```

3. **Domain not resolving**
   ```bash
   # Verify /etc/hosts entry
   grep "yourdomain.42.fr" /etc/hosts
   ```

4. **Services not starting**
   ```bash
   # Check logs
   cd srcs && docker compose logs
   
   # Check individual service
   docker logs nginx
   docker logs wordpress
   docker logs mariadb
   ```

### Health Checks

```bash
# Check container status
make status

# Verify services are responding
make check

# Manual verification
curl -k https://yourdomain.42.fr
```

## 📁 Project Structure

```
inception/
├── Makefile                    # Main build commands
├── Makefile.dev               # Development-specific commands
├── README.md                  # This file
├── srcs/                      # Source files
│   ├── docker-compose.yml     # Main compose configuration
│   ├── docker-compose.dev.yml # Development compose configuration
│   ├── .env                   # Environment variables (create from env.example)
│   ├── env.example            # Environment variables template
│   └── requirements/          # Service configurations
│       ├── nginx/             # NGINX container
│       │   ├── Dockerfile     # NGINX image build
│       │   └── conf/          # NGINX configuration files
│       ├── wordpress/         # WordPress container
│       │   ├── Dockerfile     # WordPress image build
│       │   ├── conf/          # PHP-FPM configuration
│       │   └── tool/          # WordPress setup scripts
│       └── mariadb/           # MariaDB container
│           ├── Dockerfile     # MariaDB image build
│           ├── conf/          # MariaDB configuration
│           └── tool/          # Database setup scripts
└── utils/                     # Utility scripts
    ├── create-lubuntu-vm.sh   # VM creation script
    ├── manage-vm.sh           # VM management
    ├── setup-lubuntu.sh       # VM setup automation
    └── instalation_guide_vm.md # VM installation guide
```

## 🎯 Learning Objectives

This project demonstrates:
- **Docker containerization** best practices
- **Multi-service orchestration** with Docker Compose
- **Network security** and service isolation
- **SSL/TLS implementation** for secure communications
- **Database management** in containerized environments
- **Infrastructure as Code** principles
- **Automated deployment** and configuration management

---

## 📄 License

This project is part of the 42 School curriculum. Please refer to your institution's academic integrity policies regarding code sharing and collaboration.