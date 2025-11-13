#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Docker Cleanup Tool${NC}"
echo "======================="
echo ""

# Menu function
show_menu() {
    echo "Select cleanup option:"
    echo "1) Stop all containers"
    echo "2) Remove all stopped containers"
    echo "3) Remove specific container"
    echo "4) Remove all images"
    echo "5) Remove specific image"
    echo "6) Remove unused/dangling images"
    echo "7) Complete cleanup (containers + images)"
    echo "8) System prune (remove everything unused)"
    echo "9) Exit"
    echo ""
}

# Stop all containers
stop_all_containers() {
    echo -e "${YELLOW}Stopping all containers...${NC}"
    docker stop $(docker ps -aq) 2>/dev/null && echo -e "${GREEN}✅ Done${NC}" || echo -e "${RED}No containers running${NC}"
}

# Remove all containers
remove_all_containers() {
    echo -e "${YELLOW}Removing all containers...${NC}"
    docker rm $(docker ps -aq) 2>/dev/null && echo -e "${GREEN}✅ Done${NC}" || echo -e "${RED}No containers to remove${NC}"
}

# Remove specific container
remove_specific_container() {
    docker ps -a
    echo ""
    read -p "Enter container ID or name: " container
    docker rm -f "$container" 2>/dev/null && echo -e "${GREEN}✅ Container removed${NC}" || echo -e "${RED}❌ Failed to remove${NC}"
}

# Remove all images
remove_all_images() {
    echo -e "${YELLOW}Removing all images...${NC}"
    docker rmi $(docker images -q) -f 2>/dev/null && echo -e "${GREEN}✅ Done${NC}" || echo -e "${RED}No images to remove${NC}"
}

# Remove specific image
remove_specific_image() {
    docker images
    echo ""
    read -p "Enter image ID or name: " image
    docker rmi -f "$image" 2>/dev/null && echo -e "${GREEN}✅ Image removed${NC}" || echo -e "${RED}❌ Failed to remove${NC}"
}

# Remove dangling images
remove_dangling_images() {
    echo -e "${YELLOW}Removing dangling images...${NC}"
    docker image prune -f && echo -e "${GREEN}✅ Done${NC}"
}

# Complete cleanup
complete_cleanup() {
    echo -e "${RED}⚠️  This will remove ALL containers and images!${NC}"
    read -p "Are you sure? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        stop_all_containers
        remove_all_containers
        remove_all_images
        echo -e "${GREEN}✅ Complete cleanup done!${NC}"
    else
        echo "Cancelled"
    fi
}

# System prune
system_prune() {
    echo -e "${YELLOW}Running docker system prune...${NC}"
    docker system prune -a -f --volumes
    echo -e "${GREEN}✅ System prune complete!${NC}"
}

# Main loop
while true; do
    show_menu
    read -p "Enter choice [1-9]: " choice
    echo ""
    
    case $choice in
        1) stop_all_containers ;;
        2) remove_all_containers ;;
        3) remove_specific_container ;;
        4) remove_all_images ;;
        5) remove_specific_image ;;
        6) remove_dangling_images ;;
        7) complete_cleanup ;;
        8) system_prune ;;
        9) echo "Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
done
