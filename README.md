# WordPress Local Development Environment

A Docker-based local development environment for WordPress with Nginx, PHP-FPM, and MySQL.

## Features

- **Nginx**: Pre-configured with SSL support (via mkcert).
- **PHP 8.3**: Optimized for WordPress.
- **MySQL 8.0**: Persistent storage for your data.
- **Local HTTPS**: Seamless local development with trusted certificates.
- **Easy Setup**: Scripts to automate environment initialization and management.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [mkcert](https://github.com/FiloSottile/mkcert) (for local SSL certificates)
- `lsof` (usually pre-installed on Linux/macOS)

## Getting Started

### 1. Initialization

Clone the repository and run the setup script:

```bash
./setup.sh
```

The script will:
- Check for required tools.
- Interactively create a `.env` file from `.env.template`.
- Build the Docker images.
- Download WordPress core files into the current directory.
- Create a `wp-config.php` configured to use the environment variables.

### 2. Starting the Environment

To start the containers and set up the local domain and certificates:

```bash
./site.sh start
```

This will:
- Add the local domain (default: `wordpress.local`) to your `/etc/hosts`.
- Generate and install local SSL certificates.
- Start Nginx, PHP-FPM, and MySQL containers.

Your site will then be available at: `https://wordpress.local`

### 3. Management Scripts

- `./site.sh start`: Start the environment.
- `./site.sh stop`: Stop all containers.
- `./site.sh restart`: Restart the environment.
- `./reset.sh`: **Danger!** Removes all WordPress files, databases, and local configurations to reset the project to its initial state.

## Project Structure

```text
.
├── certs/                 # Generated SSL certificates (not in git)
├── docker-compose.yml     # Docker service definitions
├── Dockerfile             # PHP-FPM image definition
├── nginx.conf.template    # Nginx configuration template
├── reset.sh               # Cleanup script
├── setup.sh               # Initialization script
├── site.sh                # Environment management script
├── wp-config.php          # WordPress configuration
└── ... (WordPress core files)
```

## Troubleshooting

- **Port Conflicts**: If ports 80 or 443 are already in use, the `site.sh` script will notify you.
- **Permissions**: The setup scripts attempt to handle ownership issues, but ensure you run them as your regular user (not with `sudo`).

## Common Tasks

### Shell Access
To enter the PHP container and run commands directly:
```bash
docker exec -it ${PROJECT_NAME}_php bash
```
*(Alternatively, you can use `docker compose exec php bash`)*

### Using Drush
Drush is installed as a Composer dependency. You can run it easily using the helper script:
```bash
./drush.sh [command]
```
Example: Clear all caches:
```bash
./drush.sh cr
```

### Using Composer
Install new modules or dependencies:
```bash
docker compose exec php composer require drupal/[module_name]
```

### Database Management
To enter the PostgreSQL shell:
```bash
docker compose exec postgres psql -U drupal_user -d drupal_db
```

## Project Structure
- `web/`: Drupal root (index.php, themes, modules).
- `vendor/`: Composer-managed dependencies and Drush.
- `nginx.conf.template`: Template for Nginx server configuration.
- `Dockerfile`: Custom PHP image definition.
- `docker-compose.yml`: Service orchestration.
