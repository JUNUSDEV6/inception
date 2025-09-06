# 🐳 Inception - Docker Infrastructure Project

WordPress + MariaDB + NGINX infrastructure using Docker Compose.

## 🚀 Quick Start

### Development (VS Code)
```bash
# Add to /etc/hosts: 127.0.0.1 localhost.42.fr
make -f Makefile.dev dev-up
# Access: https://localhost.42.fr

# 1) Crée le bon utilisateur (remplace NOUVEAU par le nom souhaité)
sudo adduser NOUVEAU

# 2) Donne-lui les droits sudo
sudo usermod -aG sudo NOUVEAU

# 3) (Optionnel) Copie le contenu de l'ancien HOME (remplace ANCIEN)
sudo rsync -aXS --exclude='*/.cache/*' /home/ANCIEN/ /home/NOUVEAU/
sudo chown -R NOUVEAU:NOUVEAU /home/NOUVEAU

# 4) (Optionnel) Transfère la clé SSH
sudo mkdir -p /home/NOUVEAU/.ssh
sudo cp -a /home/ANCIEN/.ssh/authorized_keys /home/NOUVEAU/.ssh/authorized_keys
sudo chown -R NOUVEAU:NOUVEAU /home/NOUVEAU/.ssh
sudo chmod 700 /home/NOUVEAU/.ssh
sudo chmod 600 /home/NOUVEAU/.ssh/authorized_keys

# 5) Teste la connexion depuis l'hôte Windows (garde ta session actuelle ouverte)
# Dans PowerShell (Windows), avec la redirection 4242 → VM déjà en place :
# ssh -p 4242 NOUVEAU@127.0.0.1

# 6) Si tout est OK, supprime l'ancien utilisateur et son HOME
sudo deluser --remove-home ANCIEN
# (Alternative Debian/Ubuntu avec backup)
# sudo deluser --remove-home --backup ANCIEN

# Sur Fedora/RHEL (équivalent) :
# sudo userdel -r ANCIEN

