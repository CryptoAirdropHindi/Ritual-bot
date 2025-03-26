#!/usr/bin/env bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if script is running as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script requires root privileges.${NC}"
    echo -e "Please run with: ${CYAN}sudo -i bash $0${NC}"
    exit 1
fi

# Script save path
SCRIPT_PATH="$HOME/Ritual.sh"

# Function to check Docker installation
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}Installing Docker...${NC}"
        sudo apt install -y docker.io
        sudo systemctl enable docker
        sudo systemctl start docker
    fi
}

# Function to check Docker Compose installation
check_docker_compose() {
    if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
        echo -e "${YELLOW}Installing Docker Compose...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" \
             -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
}

# Function to check Foundry installation
check_foundry() {
    if ! command -v forge &>/dev/null; then
        echo -e "${YELLOW}Installing Foundry...${NC}"
        curl -L https://foundry.paradigm.xyz | bash
        source $HOME/.bashrc
        foundryup
    fi
}

# Function to validate Ethereum address
validate_eth_address() {
    local address=$1
    if [[ $address =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate private key
validate_private_key() {
    local key=$1
    if [[ $key =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Enhanced main menu with ASCII art and social links
function main_menu() {
    while true; do
        clear
        echo -e "${CYAN}"
        echo -e "   ${RED}██████╗ ██╗████████╗██╗   ██╗ █████╗ ██╗     ${NC}"
        echo -e "   ${GREEN}██╔══██╗██║╚══██╔══╝██║   ██║██╔══██╗██║     ${NC}"
        echo -e "   ${YELLOW}██████╔╝██║   ██║   ██║   ██║███████║██║     ${NC}"
        echo -e "   ${MAGENTA}██╔══██╗██║   ██║   ██║   ██║██╔══██║██║     ${NC}"
        echo -e "   ${CYAN}██║  ██║██║   ██║   ╚██████╔╝██║  ██║███████╗${NC}"
        echo -e "   ${RED}╚═╝  ╚═╝╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝${NC}"
        echo -e "${BLUE}=======================================================${NC}"
        echo -e "${GREEN}       ✨ Ritual Node Installation Script ✨${NC}"
        echo -e "${BLUE}=======================================================${NC}"
        echo -e "${YELLOW}📌 Official Channels:${NC}"
        echo -e "${CYAN}📢 Telegram: https://t.me/CryptoAirdropHindi6${NC}"
        echo -e "${CYAN}🎥 YouTube: https://youtube.com/@CryptoAirdropHindi6${NC}"
        echo -e "${CYAN}💾 GitHub: https://github.com/CryptoAirdropHindi${NC}"
        echo -e "${BLUE}================================================${NC}"
        echo -e "1) ${GREEN}Install Ritual Node${NC}"
        echo -e "2) ${BLUE}View Node Logs${NC}"
        echo -e "3) ${RED}Remove Node${NC}"
        echo -e "4) ${YELLOW}Check Node Status${NC}"
        echo -e "5) ${MAGENTA}Update Script${NC}"
        echo -e "6) ${CYAN}Exit${NC}"
        
        read -p "$(echo -e "${CYAN}Enter your choice [1-6]: ${NC}")" choice

        case $choice in
            1) install_ritual_node ;;
            2) view_logs ;;
            3) remove_ritual_node ;;
            4) check_node_status ;;
            5) update_script ;;
            6) 
                echo -e "${GREEN}Exiting script. Thank you!${NC}"
                exit 0 
                ;;
            *)
                echo -e "${RED}Invalid option, please try again.${NC}"
                sleep 1
                ;;
        esac

        echo -e "\n${CYAN}Press any key to return to main menu...${NC}"
        read -n 1 -s -r
    done
}

# Enhanced installation function with validation
function install_ritual_node() {
    echo -e "${YELLOW}=== Ritual Node Installation ===${NC}"
    
    # Private key validation
    while true; do
        read -p "$(echo -e "${CYAN}Enter your Private Key (0x...): ${NC}")" PRIVATE_KEY
        if validate_private_key "$PRIVATE_KEY"; then
            break
        else
            echo -e "${RED}Invalid private key format! Must be 64 hex chars starting with 0x${NC}"
        fi
    done

    # Wallet address validation
    while true; do
        read -p "$(echo -e "${CYAN}Enter Wallet Address (0x...): ${NC}")" WALLET_ADDRESS
        if validate_eth_address "$WALLET_ADDRESS"; then
            break
        else
            echo -e "${RED}Invalid wallet address format! Must be 40 hex chars starting with 0x${NC}"
        fi
    done

    # RPC configuration
    RPC_URL="https://base.drpc.org"
    read -p "$(echo -e "${CYAN}Use default Base RPC? [Y/n]: ${NC}")" use_default
    if [[ $use_default =~ ^[Nn]$ ]]; then
        read -p "$(echo -e "${CYAN}Enter custom RPC URL: ${NC}")" RPC_URL
    fi

    echo -e "\n${GREEN}>>> Installing dependencies...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl git docker.io python3 python3-pip jq lz4 build-essential screen

    # Check and install required components
    check_docker
    check_docker_compose
    check_foundry

    # Clone repository
    echo -e "\n${GREEN}>>> Setting up Infernet Node...${NC}"
    if [ -d "infernet-container-starter" ]; then
        echo -e "${YELLOW}Repository already exists, pulling updates...${NC}"
        cd infernet-container-starter
        git pull
    else
        git clone https://github.com/ritual-net/infernet-container-starter
        cd infernet-container-starter || { echo -e "${RED}Failed to enter directory${NC}"; exit 1; }
    fi

    # Configuration
    echo -e "${YELLOW}Configuring node...${NC}"
    REGISTRY="0x3B1554f346DFe5c482Bb4BA31b880c1C18412170"
    
    # Update config files
    sed -i "s|\"private_key\": \".*\"|\"private_key\": \"$PRIVATE_KEY\"|" deploy/config.json
    sed -i "s|\"rpc_url\": \".*\"|\"rpc_url\": \"$RPC_URL\"|" deploy/config.json
    sed -i "s|\"payment_address\": \".*\"|\"payment_address\": \"$WALLET_ADDRESS\"|" deploy/config.json
    
    # Update Makefile
    sed -i "s|^sender := .*|sender := $WALLET_ADDRESS|" projects/hello-world/contracts/Makefile
    sed -i "s|^RPC_URL := .*|RPC_URL := $RPC_URL|" projects/hello-world/contracts/Makefile

    # Start containers
    echo -e "\n${GREEN}>>> Starting containers...${NC}"
    docker compose -f deploy/docker-compose.yaml up -d

    # Deploy contracts
    echo -e "\n${GREEN}>>> Deploying contracts...${NC}"
    export PRIVATE_KEY=$PRIVATE_KEY
    DEPLOY_OUTPUT=$(project=hello-world make deploy-contracts 2>&1)
    
    if [[ $DEPLOY_OUTPUT =~ "Deployed SaysHello:" ]]; then
        NEW_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed SaysHello:\s+\K0x[0-9a-fA-F]{40}')
        echo -e "${GREEN}Contract deployed at: ${YELLOW}$NEW_ADDR${NC}"
        
        # Update contract address
        sed -i "s|SaysGM saysGm = SaysGM(0x[0-9a-fA-F]\+);|SaysGM saysGm = SaysGM($NEW_ADDR);|" \
            projects/hello-world/contracts/script/CallContract.s.sol
            
        # Call contract
        echo -e "\n${GREEN}>>> Initializing contract...${NC}"
        project=hello-world make call-contract
    else
        echo -e "${RED}Deployment failed!${NC}"
        echo -e "${YELLOW}Error output:${NC}"
        echo "$DEPLOY_OUTPUT"
        echo -e "\n${RED}Please check:"
        echo "1. Private key and wallet address match"
        echo "2. Wallet has sufficient funds"
        echo "3. RPC endpoint is working${NC}"
        cd ~
        return 1
    fi

    echo -e "\n${GREEN}=============================================="
    echo -e "=== Ritual Node Setup Complete! ==="
    echo -e "==============================================${NC}"
    echo -e "Use command to view logs: ${CYAN}docker logs -f infernet-node${NC}"
    echo -e "Join our community for support: ${YELLOW}https://t.me/CryptoAirdropHindi6${NC}"
    cd ~
}

# Enhanced log viewer
function view_logs() {
    echo -e "${YELLOW}=== Ritual Node Logs ===${NC}"
    if docker ps | grep -q "infernet-node"; then
        echo -e "${GREEN}Node is running. Showing logs (Ctrl+C to stop)...${NC}"
        docker logs -f infernet-node
    else
        echo -e "${RED}Node container is not running!${NC}"
        echo -e "Try: ${CYAN}docker ps -a${NC} to check container status"
    fi
}

# Enhanced removal function
function remove_ritual_node() {
    echo -e "${RED}=== Ritual Node Removal ===${NC}"
    read -p "$(echo -e "${YELLOW}Are you sure you want to remove the node? [y/N]: ${NC}")" confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Stopping and removing containers...${NC}"
        if [ -d "infernet-container-starter" ]; then
            cd infernet-container-starter/deploy && docker compose down
            cd ~ && rm -rf infernet-container-starter
            echo -e "${GREEN}Node files removed successfully!${NC}"
        else
            echo -e "${YELLOW}Node directory not found, checking for containers...${NC}"
            docker-compose -f ~/infernet-container-starter/deploy/docker-compose.yaml down 2>/dev/null || \
            echo -e "${YELLOW}No containers found to remove${NC}"
        fi
        
        # Clean up Docker images
        echo -e "${YELLOW}Cleaning up Docker images...${NC}"
        docker rmi ritualnetwork/hello-world-infernet:latest 2>/dev/null || \
        echo -e "${YELLOW}No images found to remove${NC}"
        
        echo -e "\n${GREEN}Ritual Node has been completely removed.${NC}"
    else
        echo -e "${GREEN}Node removal cancelled.${NC}"
    fi
}

# Function to check node status
function check_node_status() {
    echo -e "${YELLOW}=== Node Status Check ===${NC}"
    
    # Check if Docker is running
    if ! systemctl is-active --quiet docker; then
        echo -e "${RED}Docker service is not running!${NC}"
        echo -e "Try starting it with: ${CYAN}sudo systemctl start docker${NC}"
        return 1
    fi
    
    # Check if containers are running
    if docker ps | grep -q "infernet-node"; then
        echo -e "${GREEN}✓ Node container is running${NC}"
        
        # Check for recent logs
        echo -e "\n${CYAN}=== Recent Logs ===${NC}"
        docker logs --tail=20 infernet-node
    else
        echo -e "${RED}✗ Node container is not running${NC}"
        echo -e "Check all containers with: ${CYAN}docker ps -a${NC}"
    fi
    
    # Check disk space
    echo -e "\n${CYAN}=== Disk Space ===${NC}"
    df -h
    
    # Check memory usage
    echo -e "\n${CYAN}=== Memory Usage ===${NC}"
    free -h
}

# Function to update the script
function update_script() {
    echo -e "${YELLOW}=== Updating Script ===${NC}"
    echo -e "${CYAN}Downloading latest version...${NC}"
    
    if curl -sSf https://raw.githubusercontent.com/CryptoAirdropHindi/Ritual-bot/main/Ritual.sh > /tmp/Ritual_new.sh; then
        if ! diff /tmp/Ritual_new.sh "$SCRIPT_PATH" >/dev/null; then
            mv /tmp/Ritual_new.sh "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            echo -e "${GREEN}Script updated successfully!${NC}"
            echo -e "${YELLOW}Please restart the script to use the new version.${NC}"
            exit 0
        else
            echo -e "${GREEN}You already have the latest version.${NC}"
            rm /tmp/Ritual_new.sh
        fi
    else
        echo -e "${RED}Failed to download update. Check your internet connection.${NC}"
        return 1
    fi
}

# Start the script
main_menu
