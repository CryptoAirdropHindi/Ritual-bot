#!/usr/bin/env bash

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script requires root privileges."
    echo "Please try running with 'sudo -i' to switch to root user, then run this script again."
    exit 1
fi

# Script save path
SCRIPT_PATH="$HOME/Ritual.sh"

# Main menu function
function main_menu() {
    while true; do
        clear
            echo -e "    ${RED}██╗  ██╗ █████╗ ███████╗ █████╗ ███╗   ██╗${NC}"
            echo -e "    ${GREEN}██║  ██║██╔══██╗██╔════╝██╔══██╗████╗  ██║${NC}"
            echo -e "    ${BLUE}███████║███████║███████╗███████║██╔██╗ ██║${NC}"
            echo -e "    ${YELLOW}██╔══██║██╔══██║╚════██║██╔══██║██║╚██╗██║${NC}"
            echo -e "    ${MAGENTA}██║  ██║██║  ██║███████║██║  ██║██║ ╚████║${NC}"
            echo -e "    ${CYAN}╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝${NC}"
            echo -e "${CYAN}=== Telegram Channel : (CryptoAirdropHindi) (@CryptoAirdropHindi) ===${NC}"  
            echo -e "${CYAN}=== Follow us on social media for updates and more ===${NC}"
            echo -e "=== 📱 Telegram: https://t.me/CryptoAirdropHindi6 ==="
            echo -e "=== 🎥 YouTube: https://www.youtube.com/@CryptoAirdropHindi6 ==="
            echo -e "=== 💻 GitHub Repo: https://github.com/CryptoAirdropHindi/ ==="
            echo "================================================================"
            echo "To exit the script, press ctrl + C."
            echo "Please choose an operation:"
            echo "1. Install Ritual Node"
            echo "2. View Ritual Node Logs"
            echo "3. Remove Ritual Node"
            echo "4. Exit script"
        
        read -p "Enter your choice: " choice

        case $choice in
            1) 
                install_ritual_node
                ;;
            2)
                view_logs
                ;;
            3)
                remove_ritual_node
                ;;
            4)
                echo "Exiting script!"
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac

        echo "Press any key to continue..."
        read -n 1 -s
    done
}

# Install Ritual Node function
function install_ritual_node() {

# System update and essential package installation (including Python and pip)
echo "Updating system and installing required packages..."
sudo apt update && sudo apt upgrade -y
sudo apt -qy install curl git jq lz4 build-essential screen python3 python3-pip

# Install or upgrade Python packages
echo "[Info] Upgrading pip3 and installing infernet-cli / infernet-client"
pip3 install --upgrade pip
pip3 install infernet-cli infernet-client

 
# Check Docker installation
 
echo "Checking Docker installation..."
if command -v docker &> /dev/null; then
  echo " - Docker already installed, skipping."
else
  echo " - Docker not found, installing..."
  sudo apt install -y docker.io
  sudo systemctl enable docker
  sudo systemctl start docker
fi

 
# Check Docker Compose installation
 
echo "Checking Docker Compose installation..."
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
  echo " - Docker Compose not found, installing..."
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" \
       -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p "$DOCKER_CONFIG/cli-plugins"
  curl -SL "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64" \
      -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
  chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
else
  echo " - Docker Compose already installed, skipping."
fi

echo "[Verification] Docker Compose version:"
docker compose version || docker-compose version

 
# Install Foundry and set environment variables
 
echo
echo "Installing Foundry"
# Stop anvil if running
if pgrep anvil &>/dev/null; then
  echo "[Warning] anvil is running, stopping to update Foundry."
  pkill anvil
  sleep 2
fi

cd ~ || exit 1
mkdir -p foundry
cd foundry
curl -L https://foundry.paradigm.xyz | bash

# Install or update
$HOME/.foundry/bin/foundryup

# Add ~/.foundry/bin to PATH
if [[ ":$PATH:" != *":$HOME/.foundry/bin:"* ]]; then
  export PATH="$HOME/.foundry/bin:$PATH"
fi

echo "[Verification] forge version:"
forge --version || {
  echo "[Error] forge command not found, may be due to ~/.foundry/bin not in PATH or installation failed."
  exit 1
}

# Remove /usr/bin/forge to prevent ZOE error
if [ -f /usr/bin/forge ]; then
  echo "[Info] Removing /usr/bin/forge..."
  sudo rm /usr/bin/forge
fi

echo "[Info] Foundry installation and environment setup complete."
cd ~ || exit 1

 
# Clone infernet-container-starter
 
echo
echo "Cloning infernet-container-starter..."
git clone https://github.com/ritual-net/infernet-container-starter
cd infernet-container-starter || { echo "[Error] Failed to enter directory"; exit 1; }
docker pull ritualnetwork/hello-world-infernet:latest

 
# Initial deployment in screen session (make deploy-container)
 
echo "[6] Starting container deployment in screen session (ritual)..."
sleep 1
screen -S ritual -dm bash -c '
project=hello-world make deploy-container;
exec bash
'

echo "[Info] Deployment is running in background screen session (ritual)."

 
# User input (Private Key)
 
echo
echo "Configuring Ritual Node files..."

read -p "Enter your Private Key (0x...): " PRIVATE_KEY

# Default settings
RPC_URL="https://base.drpc.org"
RPC_URL_SUB="https://mainnet.base.org/"
# Registry address
REGISTRY="0x3B1554f346DFe5c482Bb4BA31b880c1C18412170"
SLEEP=3
START_SUB_ID=160000
BATCH_SIZE=50  # Recommended for public RPC
TRAIL_HEAD_BLOCKS=3
INFERNET_VERSION="1.4.0"  # infernet image tag

 
# Modify config.json / Deploy.s.sol / docker-compose.yaml / Makefile
 

# Modify deploy/config.json
sed -i "s|\"registry_address\": \".*\"|\"registry_address\": \"$REGISTRY\"|" deploy/config.json
sed -i "s|\"private_key\": \".*\"|\"private_key\": \"$PRIVATE_KEY\"|" deploy/config.json
sed -i "s|\"sleep\": [0-9]*|\"sleep\": $SLEEP|" deploy/config.json
sed -i "s|\"starting_sub_id\": [0-9]*|\"starting_sub_id\": $START_SUB_ID|" deploy/config.json
sed -i "s|\"batch_size\": [0-9]*|\"batch_size\": $BATCH_SIZE|" deploy/config.json
sed -i "s|\"trail_head_blocks\": [0-9]*|\"trail_head_blocks\": $TRAIL_HEAD_BLOCKS|" deploy/config.json
sed -i 's|"rpc_url": ".*"|"rpc_url": "https://mainnet.base.org"|' deploy/config.json
sed -i 's|"rpc_url": ".*"|"rpc_url": "https://mainnet.base.org"|' projects/hello-world/container/config.json


# Modify projects/hello-world/container/config.json
sed -i "s|\"registry_address\": \".*\"|\"registry_address\": \"$REGISTRY\"|" projects/hello-world/container/config.json
sed -i "s|\"private_key\": \".*\"|\"private_key\": \"$PRIVATE_KEY\"|" projects/hello-world/container/config.json
sed -i "s|\"sleep\": [0-9]*|\"sleep\": $SLEEP|" projects/hello-world/container/config.json
sed -i "s|\"starting_sub_id\": [0-9]*|\"starting_sub_id\": $START_SUB_ID|" projects/hello-world/container/config.json
sed -i "s|\"batch_size\": [0-9]*|\"batch_size\": $BATCH_SIZE|" projects/hello-world/container/config.json
sed -i "s|\"trail_head_blocks\": [0-9]*|\"trail_head_blocks\": $TRAIL_HEAD_BLOCKS|" projects/hello-world/container/config.json

# Modify Deploy.s.sol
sed -i "s|\(registry\s*=\s*\).*|\1$REGISTRY;|" projects/hello-world/contracts/script/Deploy.s.sol
sed -i "s|\(RPC_URL\s*=\s*\).*|\1\"$RPC_URL\";|" projects/hello-world/contracts/script/Deploy.s.sol

# Use latest node image
sed -i 's|ritualnetwork/infernet-node:[^"]*|ritualnetwork/infernet-node:latest|' deploy/docker-compose.yaml

# Modify Makefile (sender, RPC_URL)
MAKEFILE_PATH="projects/hello-world/contracts/Makefile"
sed -i "s|^sender := .*|sender := $PRIVATE_KEY|"  "$MAKEFILE_PATH"
sed -i "s|^RPC_URL := .*|RPC_URL := $RPC_URL|"    "$MAKEFILE_PATH"

 
# Restart containers
 
echo
echo "Running docker compose down & up..."
docker compose -f deploy/docker-compose.yaml down
docker compose -f deploy/docker-compose.yaml up -d

echo
echo "[Info] Containers running in background (-d)."
echo "Check status with: docker ps. View logs: docker logs infernet-node"

 
# Install Forge libraries (resolve conflicts)
 
echo
echo "Installing Forge (project dependencies)"
cd ~/infernet-container-starter/projects/hello-world/contracts || exit 1
rm -rf lib/forge-std
rm -rf lib/infernet-sdk

forge install --no-commit foundry-rs/forge-std
forge install --no-commit ritual-net/infernet-sdk

# Restart containers
echo
echo "Restarting docker compose..."
cd ~/infernet-container-starter || exit 1
docker compose -f deploy/docker-compose.yaml down
docker compose -f deploy/docker-compose.yaml up -d
echo "[Info] View infernet-node logs: docker logs infernet-node"

 
# Deploy project contracts 
 
echo
echo "Deploying project contracts..."
DEPLOY_OUTPUT=$(project=hello-world make deploy-contracts 2>&1)
echo "$DEPLOY_OUTPUT"

# Extract newly deployed contract address (e.g.: Deployed SaysHello:  0x...)
NEW_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed SaysHello:\s+\K0x[0-9a-fA-F]{40}')
if [ -z "$NEW_ADDR" ]; then
  echo "[Warning] No new contract address found. May need manual update to CallContract.s.sol."
else
  echo "[Info] Deployed SaysHello address: $NEW_ADDR"
  # Replace old address with new one in CallContract.s.sol
  # Example: SaysGM saysGm = SaysGM(0x13D69Cf7...) -> SaysGM saysGm = SaysGM(0xA529dB3c9...)
  sed -i "s|SaysGM saysGm = SaysGM(0x[0-9a-fA-F]\+);|SaysGM saysGm = SaysGM($NEW_ADDR);|" \
      projects/hello-world/contracts/script/CallContract.s.sol

  # Execute call-contract
  echo
  echo "Executing call-contract with new address..."
  project=hello-world make call-contract
fi

echo
echo "===== Ritual Node Setup Complete ====="

  # Prompt to return to main menu
  read -n 1 -s -r -p "Press any key to return to main menu..."
  main_menu
}

# View Ritual Node logs
function view_logs() {
    echo "Viewing Ritual Node logs..."
    docker logs -f infernet-node
}

# Remove Ritual Node
function remove_ritual_node() {
    echo "Removing Ritual Node..."

    # Stop and remove Docker containers
    echo "Stopping and removing Docker containers..."
    docker-compose -f ~/infernet-container-starter/deploy/docker-compose.yaml down

    # Remove repository files
    echo "Removing related files..."
    rm -rf ~/infernet-container-starter

    # Remove Docker images
    echo "Removing Docker images..."
    docker rmi ritualnetwork/hello-world-infernet:latest

    echo "Ritual Node successfully removed!"
}

# Call main menu function
main_menu
