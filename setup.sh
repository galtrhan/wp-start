#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 0. Check permissions
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Please do not run this script as root/sudo.${NC}"
    echo "Composer and mkcert should be run as your regular user."
    exit 1
fi

# Ensure current directory is owned by the current user
CURRENT_OWNER=$(stat -c '%U' .)
if [ "$CURRENT_OWNER" == "root" ]; then
    echo -e "${GREEN}Fixing directory ownership...${NC}"
    sudo chown -R $(whoami):$(id -gn) .
fi

echo -e "${GREEN}Starting WordPress Local Environment Setup...${NC}"

# 1. Initialize .env if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${GREEN}Creating .env interactively from .env.template...${NC}"
    while IFS= read -u 3 -r line || [[ -n "$line" ]]; do
        # Handle comments and empty lines
        if [[ $line =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
            echo "$line" >> .env
        # Handle KEY=VALUE pairs
        elif [[ $line =~ ^([^=]+)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            default_value="${BASH_REMATCH[2]}"
            
            # Interactively ask for the value
            read -p "$key [$default_value]: " user_input
            
            # Use default if input is empty
            value=${user_input:-$default_value}
            echo "$key=$value" >> .env
        else
            # Copy other lines as-is
            echo "$line" >> .env
        fi
    done 3< .env.template
    echo -e "${GREEN}.env file created successfully.${NC}"
else
    echo -e "${GREEN}.env file already exists.${NC}"
fi

# 2. Build Docker images
echo -e "${GREEN}Building Docker images...${NC}"
docker compose build

# 3. Initialize WordPress project if index.php doesn't exist
if [ ! -f index.php ]; then
    echo -e "${GREEN}Initializing WordPress project...${NC}"
    
    # Download WordPress
    docker compose run --rm php sh -c "curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && ./wp-cli.phar core download --allow-root"
    
    echo -e "${GREEN}Fixing project ownership...${NC}"
    sudo chown -R $(whoami):$(id -gn) .
    
    echo -e "${GREEN}Creating wp-config.php...${NC}"
    # We'll create a basic wp-config.php that uses environment variables
    cat <<EOF > wp-config.php
<?php
define( 'DB_NAME', getenv('DB_NAME') );
define( 'DB_USER', getenv('DB_USER') );
define( 'DB_PASSWORD', getenv('DB_PASSWORD') );
define( 'DB_HOST', getenv('DB_HOST') );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

\$table_prefix = 'wp_';
define( 'WP_DEBUG', true );

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

else
    echo -e "${GREEN}WordPress project already initialized (index.php exists).${NC}"
fi

echo -e ""
echo -e "${GREEN}Setup complete!${NC}"
echo -e "You can now start the environment with: ${GREEN}./site.sh start${NC}"
