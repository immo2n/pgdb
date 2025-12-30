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
    print_info "This script will install Java 17 (Temurin) using APT package manager."
else
    print_error "System detected: $DISTRO_NAME"
    print_error "This script is optimized for Debian-based systems (Ubuntu, Debian, etc.)"
    exit 1
fi

echo ""
read -p "Do you want to continue with the Java 17 installation? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled by user."
    exit 0
fi

# Check if Java is already installed
if command_exists java; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    print_info "Java appears to be already installed: $JAVA_VERSION"
    read -p "Do you want to continue with the installation anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
fi

print_step "Step 1/5: Installing required dependencies"
print_info "Installing: wget, apt-transport-https, ca-certificates, gnupg"
if sudo apt update && sudo apt install -y wget apt-transport-https ca-certificates gnupg; then
    print_success "Dependencies installed successfully"
else
    print_error "Failed to install dependencies"
    exit 1
fi

print_step "Step 2/5: Adding Adoptium GPG key"
print_info "Downloading and adding Adoptium GPG key..."
if wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc > /dev/null; then
    print_success "Adoptium GPG key added successfully"
else
    print_error "Failed to add Adoptium GPG key"
    exit 1
fi

print_step "Step 3/5: Adding Adoptium repository"
ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)
print_info "Architecture: $ARCH"
print_info "Distribution: $CODENAME"

if echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $CODENAME main" | \
    sudo tee /etc/apt/sources.list.d/adoptium.list > /dev/null; then
    print_success "Adoptium repository configured successfully"
else
    print_error "Failed to configure Adoptium repository"
    exit 1
fi

print_step "Step 4/5: Updating package index"
if sudo apt update; then
    print_success "Package index updated with Adoptium repository"
else
    print_error "Failed to update package index"
    exit 1
fi

print_step "Step 5/5: Installing Java 17 (Temurin)"
print_info "Installing: temurin-17-jdk"
if sudo apt install -y temurin-17-jdk; then
    print_success "Java 17 (Temurin) installed successfully"
else
    print_error "Failed to install Java 17"
    exit 1
fi

# Verify installation
print_step "Verifying Installation"

JAVA_VERSION=$(java -version 2>&1 | head -n 1)
JAVA_HOME_PATH=$(readlink -f /usr/bin/java | sed "s:bin/java::")

if [ -n "$JAVA_VERSION" ]; then
    print_success "Java installation verified"
    print_info "Java version: $JAVA_VERSION"
    print_info "JAVA_HOME: $JAVA_HOME_PATH"
    
    # Check if JAVA_HOME is set in environment
    if [ -z "$JAVA_HOME" ]; then
        echo -e "\n${YELLOW}⚠ IMPORTANT:${NC}"
        echo -e "   JAVA_HOME is not set in your current session."
        echo -e "   Add this to your ${YELLOW}~/.bashrc${NC} or ${YELLOW}~/.zshrc${NC}:"
        echo -e "   ${BLUE}export JAVA_HOME=$JAVA_HOME_PATH${NC}"
        echo -e "   ${BLUE}export PATH=\$JAVA_HOME/bin:\$PATH${NC}"
        echo ""
        read -p "Do you want to add JAVA_HOME to your ~/.bashrc now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if ! grep -q "JAVA_HOME" ~/.bashrc 2>/dev/null; then
                echo "" >> ~/.bashrc
                echo "# Java 17 (Temurin)" >> ~/.bashrc
                echo "export JAVA_HOME=$JAVA_HOME_PATH" >> ~/.bashrc
                echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
                print_success "JAVA_HOME added to ~/.bashrc"
                print_info "Run 'source ~/.bashrc' or restart your terminal to apply changes"
            else
                print_info "JAVA_HOME already exists in ~/.bashrc"
            fi
        fi
    else
        print_success "JAVA_HOME is already set: $JAVA_HOME"
    fi
else
    print_error "Java installation verification failed"
    exit 1
fi

# Final summary
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}                    ✓ Java 17 (Temurin) setup completed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

print_info "Java version: $JAVA_VERSION"
print_info "Installation path: $JAVA_HOME_PATH"

echo -e "\n${BLUE}Next steps:${NC}"
echo -e "   If JAVA_HOME was added to ~/.bashrc, run: ${YELLOW}source ~/.bashrc${NC}"
echo -e "   Or simply restart your terminal session."
echo -e "   Verify installation: ${YELLOW}java -version${NC}"
echo ""

