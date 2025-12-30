#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print step headers
print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info messages
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root. It will use sudo when needed."
    exit 1
fi

# Check for Debian-based system
print_step "System Compatibility Check"

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_NAME="$NAME"
    DISTRO_ID="$ID"
elif [ -f /etc/debian_version ]; then
    DISTRO_NAME="Debian"
    DISTRO_ID="debian"
else
    DISTRO_NAME="Unknown"
    DISTRO_ID="unknown"
fi

# Check if apt is available (indicator of Debian-based system)
if ! command_exists apt; then
    print_error "This script is designed for Debian-based systems (Ubuntu, Debian, etc.)"
    print_error "Your system appears to be: $DISTRO_NAME"
    print_info "This script uses 'apt' package manager which is not available on your system."
    print_info "Please use the appropriate Docker installation method for your distribution."
    exit 1
fi

# Check if it's a known Debian-based system
DEBIAN_BASED=false
if [ -f /etc/debian_version ]; then
    DEBIAN_BASED=true
elif [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ] || [ "$ID_LIKE" = "debian" ]; then
    DEBIAN_BASED=true
fi

if [ "$DEBIAN_BASED" = true ]; then
    print_success "Detected Debian-based system: $DISTRO_NAME"
    print_info "This script will install Docker using APT package manager."
else
    print_warning "System detected: $DISTRO_NAME"
    print_warning "This script is optimized for Debian-based systems (Ubuntu, Debian, etc.)"
    print_info "Your system may work, but it's not guaranteed."
fi

echo ""
read -p "Do you want to continue with the Docker installation? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Setup cancelled by user."
    exit 0
fi

# Check if Docker is already installed
if command_exists docker && docker --version >/dev/null 2>&1; then
    print_info "Docker appears to be already installed: $(docker --version)"
    read -p "Do you want to continue with the setup anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Setup cancelled."
        exit 0
    fi
fi

print_step "Step 1/6: Updating package lists"
if sudo apt update; then
    print_success "Package lists updated successfully"
else
    print_error "Failed to update package lists"
    exit 1
fi

print_step "Step 2/6: Installing required dependencies"
print_info "Installing: ca-certificates, curl, gnupg, lsb-release"
if sudo apt install -y ca-certificates curl gnupg lsb-release; then
    print_success "Dependencies installed successfully"
else
    print_error "Failed to install dependencies"
    exit 1
fi

print_step "Step 3/6: Adding Docker's official GPG key"
print_info "Creating keyrings directory..."
sudo mkdir -p /etc/apt/keyrings

print_info "Downloading and adding Docker GPG key..."
if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
    print_success "Docker GPG key added successfully"
else
    print_error "Failed to add Docker GPG key"
    exit 1
fi

print_step "Step 4/6: Setting up Docker's APT repository"
ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)
print_info "Architecture: $ARCH"
print_info "Distribution: $CODENAME"

if echo \
    "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $CODENAME stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
    print_success "Docker repository configured successfully"
else
    print_error "Failed to configure Docker repository"
    exit 1
fi

print_step "Step 5/6: Updating package index with Docker repository"
if sudo apt update; then
    print_success "Package index updated with Docker repository"
else
    print_error "Failed to update package index"
    exit 1
fi

print_step "Step 6/6: Installing Docker Engine and plugins"
print_info "Installing: docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin"
if sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    print_success "Docker Engine and plugins installed successfully"
else
    print_error "Failed to install Docker packages"
    exit 1
fi

print_step "Configuring user permissions"
print_info "Adding user '$USER' to docker group..."
if sudo usermod -aG docker "$USER"; then
    print_success "User added to docker group"
else
    print_error "Failed to add user to docker group"
    exit 1
fi

# Final summary
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}                    ✓ Setup completed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

print_info "Docker version: $(docker --version 2>/dev/null || echo 'Please log out and back in to use Docker')"
print_info "Docker Compose version: $(docker compose version 2>/dev/null || echo 'Please log out and back in to use Docker Compose')"

echo -e "\n${YELLOW}⚠ IMPORTANT:${NC}"
echo -e "   You need to ${YELLOW}log out and log back in${NC} (or restart your terminal)"
echo -e "   for the docker group changes to take effect.\n"

echo -e "${BLUE}Next steps:${NC}"
echo -e "   1. Log out and log back in (or run: ${YELLOW}newgrp docker${NC})"
echo -e "   2. Verify Docker is working: ${YELLOW}docker run hello-world${NC}"
echo -e "   3. Start your services: ${YELLOW}./run.sh${NC}\n"
