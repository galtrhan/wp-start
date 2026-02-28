#!/bin/bash

# Configuration
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

PROJECT_NAME=${PROJECT_NAME:-"wordpress"}
DOMAIN="${PROJECT_NAME}.local"
CERTS_DIR="./certs"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 0. Check permissions
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Please do not run this script as root/sudo.${NC}"
    echo "mkcert should be run as your regular user."
    exit 1
fi

# Ensure current directory is owned by the current user
CURRENT_OWNER=$(stat -c '%U' .)
if [ "$CURRENT_OWNER" == "root" ]; then
    echo -e "${GREEN}Fixing directory ownership...${NC}"
    sudo chown -R $(whoami):$(id -gn) .
fi

function check_ports() {
    for port in 80 443; do
        if sudo lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
            echo -e "${RED}Error: Port $port is already in use.${NC}"
            echo "Please stop any other web servers or containers using this port."
            sudo lsof -i :$port
            exit 1
        fi
    done
}

function setup_hosts() {
    if ! grep -q "$DOMAIN" /etc/hosts; then
        echo -e "${GREEN}Adding $DOMAIN to /etc/hosts...${NC}"
        echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    else
        echo -e "${GREEN}$DOMAIN already in /etc/hosts.${NC}"
    fi
}

function setup_certs() {
    if [ ! -f "$CERTS_DIR/wildcard.pem" ]; then
        echo -e "${GREEN}Generating wildcard certificates for $DOMAIN and *.local...${NC}"
        mkdir -p "$CERTS_DIR"
        # Ensure mkcert is installed in the local trust store
        mkcert -install
        mkcert -cert-file "$CERTS_DIR/wildcard.pem" -key-file "$CERTS_DIR/wildcard-key.pem" "$DOMAIN" "*.local"
    else
         echo -e "${GREEN}Wildcard certificates already exist.${NC}"
    fi
}

case "$1" in
    start)
        # Check for index.php
        if [ ! -f "index.php" ]; then
            echo -e "${RED}Error: index.php not found.${NC}"
            echo "Please run ./setup.sh first to initialize the WordPress project."
            exit 1
        fi

        # If already running, restart
        if [ "$(docker compose ps --format json | grep -c "running")" -gt 0 ]; then
            echo -e "${GREEN}Site is already running. Restarting...${NC}"
            docker compose down
        fi

        check_ports
        setup_hosts
        setup_certs

        # Final verification of certs
        if [ ! -f "$CERTS_DIR/wildcard.pem" ]; then
            echo -e "${RED}Error: Certificates were not generated successfully.${NC}"
            exit 1
        fi

        echo -e "${GREEN}Starting site...${NC}"
        docker compose up -d
        echo -e "${GREEN}Site is available at https://$DOMAIN${NC}"
        ;;
    stop)
        echo -e "${GREEN}Stopping site...${NC}"
        docker compose down
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
