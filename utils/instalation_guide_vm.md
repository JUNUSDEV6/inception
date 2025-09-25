# ��️ Guide d'Installation VM Lubuntu - Inception

Guide d'installation d'une VM Lubuntu avec interface graphique pour le projet Inception sur les ordinateurs de l'école.

## �� Prérequis

- Accès à un ordinateur école avec VirtualBox
- Minimum 3GB d'espace libre dans `/goinfre`
- 2GB RAM disponible pour la VM
- Processeur 64-bit (obligatoire)

## �� Installation Rapide

### 1. Téléchargement de Lubuntu

```bash
# Télécharger Lubuntu 22.04 LTS (ISO ~1.8GB)
curl -O https://cdimage.ubuntu.com/lubuntu/releases/jammy/release/lubuntu-22.04.3-desktop-amd64.iso
```

### 2. Création automatique de la VM

Le script automatisé `utils/create-lubuntu-vm.sh` configure automatiquement la VM avec toutes les spécifications optimales :

```bash
./utils/create-lubuntu-vm.sh ugerkens /goinfre/$USER/inception-vm-lubuntu/lubuntu-22.04.3-desktop-amd64.iso
```

### 3. Démarrage de la VM et installation Lubuntu

```bash
# Utiliser le script de gestion interactif (détecte automatiquement votre VM)
./utils/manage-vm.sh
# Sélectionner option 1: "🚀 Démarrer la VM"
```

1. **Choisir "Try or Install Lubuntu"** dans le menu de démarrage
2. **Sélectionner langue** : Français (ou English)  
3. **Installer Lubuntu** directement (recommandé)

#### 3.1 Installation Configuration

4. **Keyboard** : US only
5. **Installation type** : "Erase disk and install Lubuntu"
   - **Swap configuration** : ✅ **"Swap to file"** (recommended)
   - **File system** : ✅ **ext4** (default, optimal for Docker)
   - ❌ **"Use Active Directory"** : Uncheck (not needed for personal VM)
6. **Time zone** : Europe/Brussels (or your zone)

#### 3.2 Utilisateur et configuration

8. **Votre nom** : ugerkens
9. **Nom ordinateur** : lubuntu-inception
10. **Nom utilisateur** : ugerkens
11. **Mot de passe** : Choisir un mot de passe fort
12. **Connexion automatique** : ✅ (pour faciliter l'évaluation)

#### 3.3 Finalisation

13. **Installation** : Attendre 10-15 minutes selon la machine
14. **Redémarrer maintenant** quand demandé
15. **Retirer l'ISO** : VirtualBox le fait automatiquement

### 4. Installation des services dans la VM

**Le script `create-lubuntu-vm.sh` a automatiquement créé un dossier partagé** avec tous les scripts utilitaires nécessaires.

Après l'installation de Lubuntu :

```bash
# Dans Lubuntu : Ouvrir le terminal (Ctrl+Alt+T)
# Accéder au dossier partagé (auto-monté)
cd /media/sf_inception-utils

# Exécuter le script de setup
./setup-lubuntu.sh

# Redémarrer pour que les groupes Docker prennent effet
sudo reboot
```

### 5. Installation Git et clonage du projet

```bash
# Dans Lubuntu : Configurer SSH
ssh-keygen -t ed25519 -C "votre-email@student.42.fr"
cat ~/.ssh/id_ed25519.pub  # Ajouter à GitHub/GitLab

# Cloner le projet complet
cd ~
git clone git@github.com:votre-username/inception.git