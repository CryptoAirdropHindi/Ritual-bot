#!/bin/bash

# Check if script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script requires root privileges."
    echo "Please try using 'sudo -i' to switch to root user, then run this script again."
    exit 1
fi

# Script save path
SCRIPT_PATH="$HOME/Ritual.sh"

# Function to set up shortcut alias
function check_and_set_alias() {
    local alias_name="rit"
    local shell_rc="$HOME/.bashrc"

    # For Zsh users, use .zshrc
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    # Check if alias already exists
    if ! grep -q "$alias_name" "$shell_rc"; then
        echo "Setting up shortcut '$alias_name' in $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        # Add reminder to activate the alias
        echo "Shortcut '$alias_name' has been set. Please run 'source $shell_rc' to activate it, or reopen your terminal."
    else
        # If alias already exists, provide info
        echo "Shortcut '$alias_name' is already set in $shell_rc."
        echo "If the shortcut doesn't work, try running 'source $shell_rc' or reopen your terminal."
    fi
}

# Node installation function
function install_node() {

# Prompt user for private key
read -p "Enter EVM wallet private key (must start with 0x, recommended to use a new wallet): " private_key
read -p "Enter corresponding wallet address (must start with 0x, recommended to use a new wallet): " wallet_address
# Prompt user for RPC address
read -p "Enter RPC (must be Base chain): " rpc_address
# Prompt user for port
read -p "Enter port: " port1

# Prompt user for Docker Hub credentials
read -p "Enter Docker hub username: " username
read -p "Enter Docker hub password: " password

# Update system package list
sudo apt update

# Check if Git is installed
if ! command -v git &> /dev/null
then
    # Install Git if not found
    echo "Git not detected, installing..."
    sudo apt install git -y
else
    # Skip if already installed
    echo "Git is already installed."
fi

# Clone ritual-net repository
git clone https://github.com/ritual-net/infernet-node

# Enter infernet-deploy directory
cd infernet-node

# Set tag
tag="v1.0.0"

# Build Docker image
docker build -t ritualnetwork/infernet-node:$tag .

# Enter directory
cd deploy

# Write configuration to config.json
cat > config.json <<EOF
{
  "log_path": "infernet_node.log",
  "manage_containers": true,
  "server": {
    "port": 4000,
    "rate_limit": {
      "num_requests": 100,
      "period": 100
    }
  },
  "chain": {
    "enabled": true,
    "trail_head_blocks": 5,
    "rpc_url": "$rpc_address",
    "registry_address": "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170",
    "wallet": {
      "max_gas_limit": 5000000,
      "private_key": "$private_key",
      "payment_address": "$wallet_address",
      "allowed_sim_errors": ["not enough balance"]
    },
    "snapshot_sync": {
      "sleep": 1.5,
      "batch_size": 200
    }
  },
  "docker": {
    "username": "username",
    "password": "password"
  },
  "redis": {
    "host": "redis",
    "port": 6379
  },
  "forward_stats": true,
  "startup_wait": 1.0,
  "containers": [
    {
      "id": "hello-world",
      "image": "ritualnetwork/hello-world-infernet:latest",
      "external": true,
      "port": "3000",
      "allowed_delegate_addresses": [],
      "allowed_addresses": [],
      "allowed_ips": [],
      "command": "--bind=0.0.0.0:3000 --workers=2",
      "env": {},
      "volumes": [],
      "accepted_payments": {
        "0x0000000000000000000000000000000000000000": 1000000000000000000,
        "0x59F2f1fCfE2474fD5F0b9BA1E73ca90b143Eb8d0": 1000000000000000000
      },
      "generates_proofs": false
    }
  ]
}
EOF

echo "Config file setup complete"

# Install basic components
sudo apt install pkg-config curl build-essential libssl-dev libclang-dev -y

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    # Install Docker if not found
    echo "Docker not detected, installing..."
    sudo apt-get install ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Authorize Docker files
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    sudo apt-get update

    # Install latest Docker version
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y 
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.25.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    docker compose version
    
else
    echo "Docker is already installed."
fi

# Start containers
docker compose up -d

echo "=========================Installation Complete======================================"
echo "Please use 'cd infernet-node/deploy' to enter the directory, then use 'docker compose logs -f' to check logs "

}

# Function to check node logs
function check_service_status() {
    cd infernet-node/deploy
    docker compose logs -f
}

# Main menu
function main_menu() {
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
            echo "Please select an operation:"
            echo "1. Install node"
            echo "2. Check node logs"
            echo "3. Set up shortcut alias"
            read -p "Enter your choice (1-3): " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) check_and_set_alias ;;  
    *) echo "Invalid option." ;;
    esac
}

# Display main menu
main_menu
