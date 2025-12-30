#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Function to print warning messages
print_warning() {
    echo -e "${CYAN}⚠ $1${NC}"
}

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not installed or not in PATH"
    print_info "Please run ./setup.sh first to install Docker"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker daemon is not running"
    print_info "Please start Docker service or ensure you have permission to use Docker"
    exit 1
fi

# Check if docker-compose.yaml exists
if [ ! -f "docker-compose.yaml" ]; then
    print_error "docker-compose.yaml not found in current directory"
    exit 1
fi

print_step "Checking Docker Compose status"

# Check if Docker Compose is available
if ! docker compose version >/dev/null 2>&1; then
    print_error "Docker Compose is not available"
    print_info "Please run ./setup.sh to install Docker Compose"
    exit 1
fi

# Load .env file if it exists to check for ENABLE_PGADMIN
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

# Determine which profiles to use
COMPOSE_PROFILES=""
if [ "${ENABLE_PGADMIN:-false}" = "true" ] || [ "${ENABLE_PGADMIN:-false}" = "1" ] || [ "${ENABLE_PGADMIN:-false}" = "yes" ]; then
    COMPOSE_PROFILES="--profile pgadmin"
fi

# Get list of running containers
RUNNING_CONTAINERS=$(docker compose $COMPOSE_PROFILES ps --services --filter "status=running" 2>/dev/null)

if [ -z "$RUNNING_CONTAINERS" ]; then
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                    ℹ No services are currently running${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    print_info "Nothing to stop. All services are already stopped."
    echo ""
    exit 0
fi

# Show what will be stopped
echo -e "\n${CYAN}Running containers that will be stopped:${NC}"
for container in $RUNNING_CONTAINERS; do
    print_warning "  $container"
done

print_step "Stopping Docker Compose services"

if docker compose $COMPOSE_PROFILES down; then
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}                    ✓ Services stopped successfully!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    print_info "All services have been stopped."
    print_info "Data volumes are preserved. To start again, run: ./run.sh"
    echo ""
else
    print_error "Failed to stop services"
    print_info "Check the logs with: docker compose logs"
    exit 1
fi

