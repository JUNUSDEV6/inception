#!/bin/bash

# 🖥️ Inception Project VM Setup Script for Lubuntu 22.04 LTS
# Essential tools: Docker + Docker Compose + development tools
# For Lubuntu 22.04 LTS Desktop

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if running on Lubuntu/Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    print_error "This script is designed for Ubuntu/Lubuntu systems."
    exit 1
fi

# Check if running as root
if [ "$(id -u)" = "0" ]; then
    print_error "This script should not be run as root. Run as regular user."
    exit 1
fi

print_step "🚀 Starting Lubuntu setup for Inception project..."

# Update package index
print_step "1. Updating package repositories..."
sudo apt update

# Upgrade system packages
print_step "2. Upgrading system packages..."
sudo apt upgrade -y

# Install essential development tools
print_step "3. Installing essential tools..."
sudo apt install -y \
    curl \
    wget \
    git \
    make \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
print_step "4. Installing Docker..."

# Remove old docker installations
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with Docker repo
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $(whoami)


# Install development tools
print_step "5. Installing development tools..."
sudo apt install -y \
    vim \
    htop \
    tree

# Install Claude Code CLI
print_step "6. Installing Claude Code CLI..."
if curl -fsSL https://claude.ai/install.sh | bash; then
    print_success "Claude Code CLI installed"
    # Add Claude to PATH for bash shell
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
else
    print_error "Claude Code CLI installation failed"
    print_warning "You can install manually later with: curl -fsSL https://claude.ai/install.sh | bash"
fi

# Configure /etc/hosts for Inception project  
print_step "7. Configuring /etc/hosts..."
read -r -p "Enter your 42 login name: " LOGIN_NAME
if [ -n "$LOGIN_NAME" ]; then
    HOSTS_ENTRY="127.0.0.1    ${LOGIN_NAME}.42.fr"
    if ! grep -q "${LOGIN_NAME}.42.fr" /etc/hosts; then
        echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts > /dev/null
        print_success "Added ${LOGIN_NAME}.42.fr to /etc/hosts"
    else
        print_success "${LOGIN_NAME}.42.fr already in /etc/hosts"
    fi
else
    print_error "Login name required. Please add manually: echo '127.0.0.1 YOUR_LOGIN.42.fr' | sudo tee -a /etc/hosts"
fi

# Generate SSH keys for Git repositories
print_step "8. Generating SSH keys for Git repositories..."

# Set email addresses for SSH keys
SCHOOL_EMAIL="ugerkens@student.s19.be"
GITHUB_EMAIL="hello@ugks.site"

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key for school repository (42 intra)
print_step "8.1. Generating SSH key for 42 school repository..."
if [ ! -f ~/.ssh/id_ed25519_school ]; then
    ssh-keygen -t ed25519 -C "$SCHOOL_EMAIL" -f ~/.ssh/id_ed25519_school -N ""
    print_success "School SSH key generated: ~/.ssh/id_ed25519_school"
else
    print_success "School SSH key already exists: ~/.ssh/id_ed25519_school"
fi

# Generate SSH key for GitHub
print_step "8.2. Generating SSH key for GitHub..."
if [ ! -f ~/.ssh/id_ed25519_github ]; then
    ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f ~/.ssh/id_ed25519_github -N ""
    print_success "GitHub SSH key generated: ~/.ssh/id_ed25519_github"
else
    print_success "GitHub SSH key already exists: ~/.ssh/id_ed25519_github"
fi

# Configure SSH config for different hosts
print_step "8.3. Configuring SSH config..."
cat > ~/.ssh/config << EOF
# 42 School Repository
Host vogsphere-v2.s19.be
    HostName vogsphere-v2.s19.be
    User git
    IdentityFile ~/.ssh/id_ed25519_school
    IdentitiesOnly yes

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config
print_success "SSH configuration created at ~/.ssh/config"

# Start SSH agent and add keys
print_step "8.4. Adding SSH keys to agent..."
eval "$(ssh-agent -s)" > /dev/null
ssh-add ~/.ssh/id_ed25519_school > /dev/null 2>&1
ssh-add ~/.ssh/id_ed25519_github > /dev/null 2>&1
print_success "SSH keys added to agent"

# Test installations
print_step "9. Testing installations..."

if docker --version >/dev/null 2>&1; then
    print_success "Docker: $(docker --version)"
else
    print_error "Docker installation failed"
    exit 1
fi

if docker compose version >/dev/null 2>&1; then
    print_success "Docker Compose Plugin: $(docker compose version --short)"
else
    print_error "Docker Compose plugin installation failed"
    exit 1
fi


# Firefox is pre-installed in Lubuntu 22.04 LTS

print_step "✅ Lubuntu setup complete!"

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Log out and log back in (or reboot) to activate Docker group membership"
echo "2. Build and start project: cd ~/inception && make"
echo "3. Access services:"
echo "   - WordPress: https://${LOGIN_NAME}.42.fr (in Firefox)"
echo "   - Adminer: http://localhost:8080"
echo "   - Static Site: http://localhost:8081"
echo "   - DOSBox: http://localhost:8082"

echo -e "\n${BLUE}Installed tools:${NC}"
echo "- Git (git)"
echo "- Make (make)" 
echo "- Docker (docker)"
echo "- Docker Compose Plugin (docker compose)"
echo "- Text editor: vim"
echo "- System tools: htop, tree"
echo "- Claude Code CLI (claude)"
echo "- Firefox browser (pre-installed)"

echo -e "\n${GREEN}Lubuntu is ready for containerized development with GUI! 🖥️${NC}"

echo -e "\n${YELLOW}Important:${NC}"
echo "- Reboot or log out/in to activate Docker permissions"
echo "- Firefox is available in the Applications menu"
echo "- Use terminal with Ctrl+Alt+T"
echo "- VM clipboard sharing is enabled in VirtualBox settings"

# Display SSH public keys for copy-paste
echo -e "\n${BLUE}🔑 SSH PUBLIC KEYS (Copy these to your repositories):${NC}"
echo -e "\n${YELLOW}📚 42 SCHOOL REPOSITORY PUBLIC KEY:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ~/.ssh/id_ed25519_school.pub ]; then
    cat ~/.ssh/id_ed25519_school.pub
else
    echo "❌ School SSH key not found"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${YELLOW}🐙 GITHUB PUBLIC KEY:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ~/.ssh/id_ed25519_github.pub ]; then
    cat ~/.ssh/id_ed25519_github.pub
else
    echo "❌ GitHub SSH key not found"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${GREEN}📋 Next Steps:${NC}"
echo "1. Copy the 42 SCHOOL key above and add it to your vogsphere repository"
echo "2. Copy the GITHUB key above and add it to your GitHub account settings"
echo "3. Test connections:"
echo "   - School: ssh -T git@vogsphere-v2.s19.be"
echo "   - GitHub: ssh -T git@github.com"