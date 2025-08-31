#!/bin/bash

# 🎛️ Script de gestion des VMs VirtualBox pour Inception
# Interface interactive pour gérer votre VM Lubuntu Inception
# Usage: ./manage-vm.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Auto-detect VM name based on current user
VM_NAME="${USER}-lubuntu-inception"

print_header() {
    echo -e "\n${CYAN}🎛️  Gestion VM Inception${NC}"
    echo -e "${BLUE}VM: $VM_NAME${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_menu() {
    echo -e "\n${YELLOW}Actions disponibles:${NC}"
    echo "1) 🚀 Démarrer la VM"
    echo "2) ⏹️  Arrêter la VM (gracieux)"
    echo "3) 🔌 Forcer l'arrêt de la VM"
    echo "4) 📊 Voir le statut de la VM"
    echo "5) 📋 Lister toutes les VMs"
    echo "6) ℹ️  Informations détaillées"
    echo "7) 📸 Créer un snapshot d'évaluation"
    echo "8) 🔄 Restaurer le snapshot d'évaluation"
    echo "9) 📋 Lister les snapshots"
    echo "10) 🗑️ Supprimer la VM"
    echo "0) ❌ Quitter"
    echo ""
}

get_user_choice() {
    read -p "Choisissez une action (0-10): " choice
    echo "$choice"
}

check_vm_exists() {
    if ! VBoxManage list vms | grep -q "\"$VM_NAME\""; then
        echo -e "${RED}❌ VM '$VM_NAME' non trouvée${NC}"
        echo -e "${YELLOW}💡 Créez-la d'abord avec: ./utils/create-lubuntu-vm.sh${NC}"
        return 1
    fi
    return 0
}

# Main interactive loop
main() {
    print_header
    
    while true; do
        print_menu
        choice=$(get_user_choice)
        
        case "$choice" in
            "1")
                echo -e "\n${BLUE}🚀 Démarrage de la VM: $VM_NAME${NC}"
                if check_vm_exists; then
                    VBoxManage startvm "$VM_NAME" || echo -e "${YELLOW}⚠️  La VM est peut-être déjà en cours d'exécution${NC}"
                fi
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "2")
                echo -e "\n${YELLOW}⏹️  Arrêt gracieux de la VM: $VM_NAME${NC}"
                if check_vm_exists; then
                    VBoxManage controlvm "$VM_NAME" acpipowerbutton || echo -e "${YELLOW}⚠️  La VM n'est peut-être pas en cours d'exécution${NC}"
                fi
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "3")
                echo -e "\n${RED}🔌 Arrêt forcé de la VM: $VM_NAME${NC}"
                if check_vm_exists; then
                    VBoxManage controlvm "$VM_NAME" poweroff || echo -e "${YELLOW}⚠️  La VM n'est peut-être pas en cours d'exécution${NC}"
                fi
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "4")
                echo -e "\n${BLUE}📊 Statut de la VM: $VM_NAME${NC}"
                if check_vm_exists; then
                    VBoxManage showvminfo "$VM_NAME" | grep -E "(State|Memory size|Number of CPUs|VRAM size)"
                fi
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "5")
                echo -e "\n${BLUE}📋 VMs disponibles:${NC}"
                VBoxManage list vms
                echo -e "\n${BLUE}🔄 VMs en cours d'exécution:${NC}"
                VBoxManage list runningvms
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "6")
                echo -e "\n${BLUE}ℹ️  Informations détaillées pour: $VM_NAME${NC}"
                if check_vm_exists; then
                    VBoxManage showvminfo "$VM_NAME"
                fi
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "7")
                echo -e "\n${BLUE}📸 Création d'un snapshot d'évaluation: $VM_NAME${NC}"
                if check_vm_exists; then
                    # Check if VM is running and stop it if necessary
                    if VBoxManage list runningvms | grep -q "\"$VM_NAME\""; then
                        echo -e "${YELLOW}⚠️  La VM est en cours d'exécution. Arrêt d'abord...${NC}"
                        VBoxManage controlvm "$VM_NAME" acpipowerbutton
                        echo "Attente de l'arrêt de la VM..."
                        sleep 10
                    fi
                    
                    # Delete existing evaluation_snapshot if it exists
                    if VBoxManage snapshot "$VM_NAME" list 2>/dev/null | grep -q "evaluation_snapshot"; then
                        echo -e "${YELLOW}🗑️  Suppression du snapshot existant...${NC}"
                        VBoxManage snapshot "$VM_NAME" delete "evaluation_snapshot"
                    fi
                    
                    # Create new snapshot
                    VBoxManage snapshot "$VM_NAME" take "evaluation_snapshot" --description "Clean state for project evaluation - $(date '+%Y-%m-%d %H:%M:%S')"
                    echo -e "${GREEN}✅ Snapshot d'évaluation créé avec succès!${NC}"
                fi
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "8")
                echo -e "\n${BLUE}🔄 Restauration du snapshot d'évaluation: $VM_NAME${NC}"
                if check_vm_exists; then
                    # Check if evaluation_snapshot exists
                    if ! VBoxManage snapshot "$VM_NAME" list 2>/dev/null | grep -q "evaluation_snapshot"; then
                        echo -e "${RED}❌ Aucun snapshot d'évaluation trouvé${NC}"
                        echo -e "${YELLOW}💡 Créez-en un d'abord avec l'option 7${NC}"
                    else
                        # Stop VM if running
                        if VBoxManage list runningvms | grep -q "\"$VM_NAME\""; then
                            echo -e "${YELLOW}⚠️  Arrêt de la VM en cours...${NC}"
                            VBoxManage controlvm "$VM_NAME" poweroff
                            sleep 3
                        fi
                        
                        # Restore snapshot
                        VBoxManage snapshot "$VM_NAME" restore "evaluation_snapshot"
                        echo -e "${GREEN}✅ VM restaurée au snapshot d'évaluation!${NC}"
                    fi
                fi
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "9")
                echo -e "\n${BLUE}📋 Snapshots pour: $VM_NAME${NC}"
                if check_vm_exists; then
                    VBoxManage snapshot "$VM_NAME" list --machinereadable 2>/dev/null | grep SnapshotName | cut -d'=' -f2 | tr -d '"' || echo "Aucun snapshot trouvé"
                fi
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "10")
                echo -e "\n${RED}🗑️  Suppression de la VM: $VM_NAME${NC}"
                if check_vm_exists; then
                    echo -e "${RED}⚠️  Cela supprimera définitivement la VM: $VM_NAME${NC}"
                    read -p "Êtes-vous sûr? (o/N): " confirm
                    if [[ $confirm == [oO] || $confirm == [oO][uU][iI] ]]; then
                        echo "Arrêt de la VM..."
                        VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
                        sleep 2
                        echo "Suppression de la VM..."
                        VBoxManage unregistervm "$VM_NAME" --delete
                        echo -e "${GREEN}✅ VM supprimée${NC}"
                    else
                        echo "Annulé"
                    fi
                fi
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
                
            "0")
                echo -e "\n${GREEN}👋 Au revoir!${NC}"
                exit 0
                ;;
                
            *)
                echo -e "\n${RED}❌ Choix invalide. Veuillez choisir entre 0 et 10.${NC}"
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
        esac
    done
}

# Run main function
main