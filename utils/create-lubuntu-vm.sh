#!/bin/bash

# 🖥️ Script d'automatisation VirtualBox pour VM Lubuntu Inception
# Crée automatiquement une VM Lubuntu optimisée pour le projet Inception
# Usage: ./create-lubuntu-vm.sh [username] [optional-iso-path]

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

# Check if VBoxManage is available
if ! command -v VBoxManage &> /dev/null; then
    print_error "VBoxManage not found. Please install VirtualBox first."
    exit 1
fi

# Get username and ISO path from parameters
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <username> <iso-path>"
    echo "Example: $0 ugerkens /path/to/lubuntu-22.04.5-desktop-amd64.iso"
    echo ""
    echo "Please download Lubuntu ISO from:"
    echo "  https://lubuntu.me/downloads/"
    echo "  https://releases.ubuntu.com/lubuntu/22.04/"
    exit 1
fi

USERNAME="$1"
# Convert relative path to absolute path before changing directories
ISO_PATH="$(realpath "$2")"

# Configuration variables
VM_NAME="${USERNAME}-lubuntu-inception"
VM_FOLDER="/sgoinfre/students/$USER/inception-vm-lubuntu"

# VM Configuration
VM_MEMORY=2048          # 2GB RAM
VM_CPUS=2              # 2 CPU cores
VM_VRAM=128            # 128MB Video RAM
DISK_SIZE=15360        # 15GB disk (in MB)

print_step "🚀 Creating Lubuntu VM for Inception project..."
echo "VM Name: $VM_NAME"
echo "VM Folder: $VM_FOLDER"

# Clean up existing sgoinfre space and set proper permissions
print_step "0. Setting up sgoinfre directory..."
SGOINFRE_USER_DIR="/sgoinfre/students/$USER"
if [ -d "$SGOINFRE_USER_DIR" ]; then
    print_warning "Cleaning existing sgoinfre directory: $SGOINFRE_USER_DIR"
    rm -rf "$SGOINFRE_USER_DIR"/*
    print_success "Existing files cleaned"
else
    print_step "Creating sgoinfre user directory: $SGOINFRE_USER_DIR"
    mkdir -p "$SGOINFRE_USER_DIR"
fi

# Set proper permissions (700 as recommended)
chmod 700 "$SGOINFRE_USER_DIR"
print_success "Directory permissions set to 700 (user access only)"

# Create VM directory
print_step "1. Creating VM directory..."
mkdir -p "$VM_FOLDER"
cd "$VM_FOLDER"

# Validate ISO file function
validate_iso() {
    local iso_path="$1"
    local min_size=2800000000       # Minimum acceptable size (2.6GB)
    
    print_step "🔍 Validating ISO file..."
    
    # Check if file exists
    if [ ! -f "$iso_path" ]; then
        print_error "ISO file not found: $iso_path"
        return 1
    fi
    
    # Check file permissions
    if [ ! -r "$iso_path" ]; then
        print_error "ISO file is not readable: $iso_path"
        print_warning "Fixing permissions..."
        chmod 644 "$iso_path" 2>/dev/null || {
            print_error "Failed to fix permissions. Please run: chmod 644 '$iso_path'"
            return 1
        }
        print_success "Permissions fixed"
    fi
    
    # Check file size
    local file_size
    file_size=$(stat -f%z "$iso_path" 2>/dev/null || stat -c%s "$iso_path" 2>/dev/null || echo "0")
    
    if [ "$file_size" -eq 0 ]; then
        print_error "Cannot determine file size or file is empty"
        return 1
    fi
    
    local size_mb=$((file_size / 1024 / 1024))
    print_step "ISO file size: ${size_mb}MB (${file_size} bytes)"
    
    if [ "$file_size" -lt "$min_size" ]; then
        print_error "ISO file too small (${size_mb}MB). Expected ~2800MB+"
        print_warning "The download may be incomplete or corrupted"
        print_warning "Please check if this is the correct ISO file"
        return 1
    fi
    
    # Test if file is a valid ISO format
    print_step "Testing ISO format..."
    
    # Check if file has ISO 9660 signature
    if command -v file &> /dev/null; then
        local file_type
        file_type=$(file "$iso_path" 2>/dev/null || echo "unknown")
        if [[ ! "$file_type" =~ (ISO|DVD|CD-ROM) ]]; then
            print_error "File does not appear to be a valid ISO format"
            print_error "File type detected: $file_type"
            return 1
        fi
    else
        # Basic header check for ISO 9660 signature
        if ! head -c 32768 "$iso_path" | tail -c +32769 | head -c 5 | grep -q "CD001" 2>/dev/null; then
            print_error "File does not contain ISO 9660 signature"
            return 1
        fi
    fi
    
    print_success "ISO file validation passed"
    return 0
}

# Validate the provided ISO file
print_step "2. Validating provided ISO file..."
if ! validate_iso "$ISO_PATH"; then
    print_error "Provided ISO file validation failed"
    print_warning "Please provide a valid Lubuntu ISO file"
    exit 1
fi

# Check if VM already exists
if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    print_warning "VM '$VM_NAME' already exists. Removing it..."
    VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
    sleep 2
    VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
    print_success "Existing VM removed"
fi

# Create the virtual machine
print_step "3. Creating virtual machine..."
VBoxManage createvm \
    --name "$VM_NAME" \
    --basefolder "$VM_FOLDER" \
    --ostype "Ubuntu_64" \
    --register

print_success "VM '$VM_NAME' created"

# Configure VM settings
print_step "4. Configuring VM settings..."

# System configuration
VBoxManage modifyvm "$VM_NAME" \
    --memory "$VM_MEMORY" \
    --cpus "$VM_CPUS" \
    --vram "$VM_VRAM" \
    --graphicscontroller "vmsvga" \
    --accelerate3d on \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none

print_success "System settings configured (${VM_MEMORY}MB RAM, ${VM_CPUS} CPUs)"

# Network configuration
print_step "5. Configuring network and port forwarding..."
VBoxManage modifyvm "$VM_NAME" \
    --nic1 nat \
    --natpf1 "SSH,tcp,,2222,,22" \
    --natpf1 "HTTPS,tcp,,8443,,443" \
    --natpf1 "Adminer,tcp,,8080,,8080" \
    --natpf1 "Static,tcp,,8081,,8081" \
    --natpf1 "DOSBox,tcp,,8082,,8082"

print_success "Network configured with port forwarding"

# Shared settings
VBoxManage modifyvm "$VM_NAME" \
    --clipboard-mode bidirectional \
    --draganddrop bidirectional

print_success "Clipboard and drag-drop enabled"

# Create and attach hard disk
print_step "6. Creating virtual hard disk..."
DISK_PATH="$VM_FOLDER/$VM_NAME/$VM_NAME.vdi"

VBoxManage createhd \
    --filename "$DISK_PATH" \
    --size "$DISK_SIZE" \
    --format VDI \
    --variant Standard

print_success "Virtual disk created (${DISK_SIZE}MB)"

# Create storage controllers
print_step "7. Setting up storage controllers..."

# SATA controller for hard disk
VBoxManage storagectl "$VM_NAME" \
    --name "SATA Controller" \
    --add sata \
    --controller IntelAhci \
    --portcount 2

# Attach hard disk
VBoxManage storageattach "$VM_NAME" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "$DISK_PATH"

# IDE controller for DVD
VBoxManage storagectl "$VM_NAME" \
    --name "IDE Controller" \
    --add ide

# Attach ISO with error handling
print_step "7.1. Attaching ISO to VM..."
if ! VBoxManage storageattach "$VM_NAME" \
    --storagectl "IDE Controller" \
    --port 0 \
    --device 0 \
    --type dvddrive \
    --medium "$ISO_PATH" 2>/dev/null; then
    
    print_error "Failed to attach ISO to VM"
    print_warning "This usually indicates:"
    print_warning "  1. ISO file is corrupted or invalid format"
    print_warning "  2. VirtualBox cannot read the file"
    print_warning "  3. File permissions issue"
    print_warning ""
    print_warning "Troubleshooting steps:"
    print_warning "  1. Check ISO file: ls -la '$ISO_PATH'"
    print_warning "  2. Test file readability: file '$ISO_PATH'"
    print_warning "  3. Try re-downloading: rm '$ISO_PATH' && ./create-lubuntu-vm.sh"
    print_warning "  4. Check VirtualBox version: VBoxManage --version"
    
    # Cleanup failed VM
    print_warning "Cleaning up failed VM..."
    VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
    exit 1
fi

print_success "Storage configured and ISO attached"

# Audio and USB configuration (optional)
print_step "8. Configuring additional features..."
VBoxManage modifyvm "$VM_NAME" \
    --audio-driver pulse \
    --audio-controller hda \
    --audio-enabled on \
    --usb-ehci on

print_success "Audio and USB configured"

# Create shared folder with utils scripts
print_step "9. Setting up shared folder with utils scripts..."
UTILS_SHARED_FOLDER="$VM_FOLDER/shared-utils"
mkdir -p "$UTILS_SHARED_FOLDER"

# Copy utils scripts to shared folder
SCRIPT_DIR="$(dirname "$(dirname "$0")")"  # Go back to project root
if [ -d "$SCRIPT_DIR/utils" ]; then
    cp -r "$SCRIPT_DIR/utils"/* "$UTILS_SHARED_FOLDER/"
    print_success "Utils scripts copied to shared folder"
else
    print_warning "Utils directory not found at $SCRIPT_DIR/utils"
    print_warning "Manual copy will be needed"
fi

# Add shared folder to VM
VBoxManage sharedfolder add "$VM_NAME" \
    --name "inception-utils" \
    --hostpath "$UTILS_SHARED_FOLDER" \
    --automount \
    --auto-mount-point "/media/sf_inception-utils"

print_success "Shared folder 'inception-utils' configured"

# Show VM info
print_step "10. VM Configuration Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VM Name:        $VM_NAME"
echo "Location:       $VM_FOLDER/$VM_NAME"
echo "RAM:            ${VM_MEMORY}MB"
echo "CPUs:           $VM_CPUS"
echo "Video RAM:      ${VM_VRAM}MB"
echo "Disk Size:      ${DISK_SIZE}MB (~15GB)"
echo "ISO:            $ISO_PATH"
echo "Shared Folder:  /media/sf_inception-utils (auto-mounted)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_step "🌐 Port Forwarding Configuration:"
echo "Host Port → Guest Port  Service"
echo "2222      → 22          SSH (optional)"
echo "8443      → 443         WordPress HTTPS"
echo "8080      → 8080        Adminer"
echo "8081      → 8081        Static Site"
echo "8082      → 8082        DOSBox Game"

print_success "✅ VM '$VM_NAME' created successfully!"

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Start the VM:"
echo "   VBoxManage startvm \"$VM_NAME\""
echo "   # Or use VirtualBox GUI"
echo ""
echo "2. Install Lubuntu following the GUI installer"
echo ""
echo "3. After installation, in Lubuntu terminal:"
echo "   # Access shared utils folder"
echo "   cd /media/sf_inception-utils"
echo "   chmod +x setup-lubuntu.sh"
echo "   ./setup-lubuntu.sh"
echo ""

echo -e "\n${YELLOW}Installation ready! 🚀${NC}"