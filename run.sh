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
    print_info "You may need to log out and log back in after running setup.sh"
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

# Get list of all containers defined in docker-compose.yaml (regardless of running status)
ALL_CONTAINERS=$(docker compose $COMPOSE_PROFILES config --services 2>/dev/null)

if [ -z "$ALL_CONTAINERS" ]; then
    print_warning "No services found in docker-compose.yaml"
    exit 1
fi

# Check which containers are running
RUNNING_CONTAINERS=$(docker compose $COMPOSE_PROFILES ps --services --filter "status=running" 2>/dev/null)

# Count containers
TOTAL_COUNT=$(echo "$ALL_CONTAINERS" | wc -l)
RUNNING_COUNT=$(echo "$RUNNING_CONTAINERS" | grep -v '^$' | wc -l)

print_info "Total services defined: $TOTAL_COUNT"
print_info "Currently running: $RUNNING_COUNT"

# Show status of each container
if [ -n "$RUNNING_CONTAINERS" ]; then
    echo -e "\n${CYAN}Running containers:${NC}"
    for container in $RUNNING_CONTAINERS; do
        CONTAINER_NAME=$(docker compose $COMPOSE_PROFILES ps -q "$container" 2>/dev/null | head -1)
        if [ -n "$CONTAINER_NAME" ]; then
            STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
            HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null 2>/dev/null || echo "N/A")
            if [ "$HEALTH" != "N/A" ] && [ -n "$HEALTH" ]; then
                print_success "  $container: $STATUS (health: $HEALTH)"
            else
                print_success "  $container: $STATUS"
            fi
        fi
    done
fi

# Check for stopped containers
STOPPED_CONTAINERS=$(docker compose $COMPOSE_PROFILES ps --services --filter "status=stopped" 2>/dev/null)
if [ -n "$STOPPED_CONTAINERS" ]; then
    echo -e "\n${YELLOW}Stopped containers:${NC}"
    for container in $STOPPED_CONTAINERS; do
        print_warning "  $container: stopped"
    done
fi

# Determine action needed
if [ "$RUNNING_COUNT" -eq "$TOTAL_COUNT" ] && [ "$TOTAL_COUNT" -gt 0 ]; then
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}                    ✓ All services are already running!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    print_info "No action needed. All containers are up and running."
    echo -e "\n${BLUE}Useful commands:${NC}"
    echo -e "   View logs: ${YELLOW}docker compose logs -f${NC}"
    echo -e "   Stop services: ${YELLOW}docker compose down${NC}"
    echo -e "   Restart services: ${YELLOW}docker compose restart${NC}"
    echo ""
    exit 0
fi

# Some containers need to be started
if [ "$RUNNING_COUNT" -lt "$TOTAL_COUNT" ]; then
    print_step "Starting Docker Compose services"
    
    if [ "$RUNNING_COUNT" -gt 0 ]; then
        print_info "Some containers are already running. Starting remaining services..."
    else
        print_info "Starting all services..."
    fi
    
    # Check for .env file
    if [ ! -f ".env" ]; then
        print_warning ".env file not found. Services may need environment variables."
        print_info "Make sure POSTGRES_USER, POSTGRES_PASSWORD, and POSTGRES_DB are set"
    fi
    
    # Show pgAdmin status
    if [ -n "$COMPOSE_PROFILES" ]; then
        print_info "pgAdmin is enabled (ENABLE_PGADMIN=true)"
    else
        print_info "pgAdmin is disabled (set ENABLE_PGADMIN=true in .env to enable)"
    fi
    
    if docker compose $COMPOSE_PROFILES up -d; then
        echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}                    ✓ Services started successfully!${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        # Wait a moment for containers to initialize
        sleep 2
        
        # Show final status
        print_info "Container status:"
        docker compose $COMPOSE_PROFILES ps
        
        echo -e "\n${BLUE}Useful commands:${NC}"
        echo -e "   View logs: ${YELLOW}docker compose logs -f${NC}"
        echo -e "   Stop services: ${YELLOW}docker compose down${NC}"
        echo -e "   Restart services: ${YELLOW}docker compose restart${NC}"
        echo ""
    else
        print_error "Failed to start services"
        print_info "Check the logs with: docker compose logs"
        exit 1
    fi
fi

