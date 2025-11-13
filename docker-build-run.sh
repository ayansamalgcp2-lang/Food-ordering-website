#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to check if port is available
check_port() {
    local port=$1
    if sudo lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        return 1
    else
        return 0
    fi
}

# Function to validate port number
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# Function to open in Edge browser
open_in_edge() {
    local url=$1
    local wsl_ip=$(hostname -I | awk '{print $1}')
    
    print_info "Opening in Edge browser..."
    
    # Try different methods to open Edge from WSL
    if command -v explorer.exe &> /dev/null; then
        # Method 1: Using explorer.exe
        explorer.exe "microsoft-edge:$url"
    elif command -v cmd.exe &> /dev/null; then
        # Method 2: Using cmd.exe
        cmd.exe /c start msedge "$url"
    else
        # Method 3: Direct PowerShell
        powershell.exe -Command "Start-Process msedge -ArgumentList '$url'"
    fi
    
    sleep 2
    print_success "Browser should open at: $url"
    print_info "If browser didn't open, manually visit: $url"
    print_info "Alternative URL (WSL IP): http://$wsl_ip:$2"
}

# Header
clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════╗"
echo "║  🐳 Docker Build & Run Automation     ║"
echo "║     with Auto Browser Launch          ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found in current directory!"
    print_info "Please make sure you're in the project directory with a Dockerfile"
    exit 1
fi

print_success "Dockerfile found!"
echo ""

# Get image name
echo -e "${YELLOW}Step 1: Image Configuration${NC}"
echo "─────────────────────────────"
read -p "Enter Docker image name (e.g., food-ordering-website): " IMAGE_NAME

# Validate image name
if [ -z "$IMAGE_NAME" ]; then
    print_error "Image name cannot be empty!"
    exit 1
fi

# Get image tag (optional)
read -p "Enter image tag [default: latest]: " IMAGE_TAG
IMAGE_TAG=${IMAGE_TAG:-latest}

FULL_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"
print_info "Full image name: $FULL_IMAGE_NAME"
echo ""

# Get container name
echo -e "${YELLOW}Step 2: Container Configuration${NC}"
echo "────────────────────────────────"
read -p "Enter container name (e.g., food-app): " CONTAINER_NAME

# Validate container name
if [ -z "$CONTAINER_NAME" ]; then
    print_error "Container name cannot be empty!"
    exit 1
fi

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_warning "Container '$CONTAINER_NAME' already exists!"
    read -p "Do you want to remove it and continue? (y/N): " remove_confirm
    if [[ $remove_confirm == [yY] ]]; then
        docker stop "$CONTAINER_NAME" 2>/dev/null
        docker rm "$CONTAINER_NAME" 2>/dev/null
        print_success "Old container removed"
    else
        print_error "Please choose a different container name"
        exit 1
    fi
fi
echo ""

# Get port mapping
echo -e "${YELLOW}Step 3: Port Configuration${NC}"
echo "───────────────────────────"
while true; do
    read -p "Enter host port to expose (e.g., 8080, 3000, 8081): " HOST_PORT
    
    # Validate port
    if ! validate_port "$HOST_PORT"; then
        print_error "Invalid port number! Must be between 1-65535"
        continue
    fi
    
    # Check if port is available
    if ! check_port "$HOST_PORT"; then
        print_error "Port $HOST_PORT is already in use!"
        read -p "Try another port? (y/N): " retry
        if [[ $retry != [yY] ]]; then
            exit 1
        fi
    else
        print_success "Port $HOST_PORT is available!"
        break
    fi
done

read -p "Enter container port [default: 80]: " CONTAINER_PORT
CONTAINER_PORT=${CONTAINER_PORT:-80}

print_info "Port mapping: $HOST_PORT -> $CONTAINER_PORT"
echo ""

# Summary
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}           Configuration Summary         ${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "Image Name:      ${GREEN}$FULL_IMAGE_NAME${NC}"
echo -e "Container Name:  ${GREEN}$CONTAINER_NAME${NC}"
echo -e "Port Mapping:    ${GREEN}$HOST_PORT:$CONTAINER_PORT${NC}"
echo -e "Browser Launch:  ${GREEN}Enabled (Edge)${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

read -p "Proceed with build and run? (Y/n): " proceed
proceed=${proceed:-Y}

if [[ $proceed != [yY] ]]; then
    print_warning "Operation cancelled"
    exit 0
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}        Starting Build Process          ${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

# Build the image
print_info "Building Docker image..."
if docker build -t "$FULL_IMAGE_NAME" . ; then
    print_success "Image built successfully!"
else
    print_error "Image build failed!"
    exit 1
fi

echo ""
print_info "Image details:"
docker images "$IMAGE_NAME"
echo ""

# Run the container
print_info "Starting container..."
if docker run -d -p "$HOST_PORT:$CONTAINER_PORT" --name "$CONTAINER_NAME" "$FULL_IMAGE_NAME" ; then
    print_success "Container started successfully!"
else
    print_error "Failed to start container!"
    exit 1
fi

# Wait for container to be ready
print_info "Waiting for container to be ready..."
sleep 3

# Check if container is running
if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q "$CONTAINER_NAME"; then
    print_success "Container is running!"
    
    # Show container details
    echo ""
    print_info "Container details:"
    docker ps --filter "name=$CONTAINER_NAME" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
    
    # Show logs
    echo ""
    print_info "Container logs (last 10 lines):"
    docker logs --tail 10 "$CONTAINER_NAME"
    
    # Test the endpoint
    echo ""
    print_info "Testing endpoint..."
    sleep 2
    
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$HOST_PORT" | grep -q "200\|301\|302"; then
        print_success "Endpoint is responding!"
        
        # Open in browser
        echo ""
        open_in_edge "http://localhost:$HOST_PORT" "$HOST_PORT"
        
    else
        print_warning "Endpoint might not be ready yet. Trying to open browser anyway..."
        open_in_edge "http://localhost:$HOST_PORT" "$HOST_PORT"
    fi
    
else
    print_error "Container is not running!"
    print_info "Checking logs for errors..."
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Final summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}           🎉 Success!                  ${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "Container:  ${GREEN}$CONTAINER_NAME${NC} is running"
echo -e "Access at:  ${GREEN}http://localhost:$HOST_PORT${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  View logs:    ${CYAN}docker logs $CONTAINER_NAME${NC}"
echo -e "  Follow logs:  ${CYAN}docker logs -f $CONTAINER_NAME${NC}"
echo -e "  Stop:         ${CYAN}docker stop $CONTAINER_NAME${NC}"
echo -e "  Restart:      ${CYAN}docker restart $CONTAINER_NAME${NC}"
echo -e "  Remove:       ${CYAN}docker rm -f $CONTAINER_NAME${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
