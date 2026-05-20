# WordPress Local Development Environment

A Docker-based local development environment for WordPress with Nginx, PHP-FPM, and MySQL.

## Features

- **Nginx**: Pre-configured with SSL support (via mkcert).
- **PHP 8.3**: Optimized for WordPress with Xdebug, GD (JPEG/WebP), and common extensions.
- **MySQL 8.0**: Persistent storage for your data.
- **Local HTTPS**: Seamless local development with trusted certificates.
- **Xdebug 3**: Step debugging from your IDE on port 9003.
- **Easy Setup**: Scripts to automate environment initialization and management.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [mkcert](https://github.com/FiloSottile/mkcert) (for local SSL certificates)
- `lsof` (usually pre-installed on Linux/macOS)

## Getting Started

### 1. Initialization

Clone the repository and run the setup script:

```bash
./site setup
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
./site start
```

This will:
- Add the local domain (default: `wordpress.local`) to your `/etc/hosts`.
- Generate and install local SSL certificates.
- Start Nginx, PHP-FPM, and MySQL containers.

Your site will then be available at: `https://wordpress.local`

### 3. Management Scripts

- `./site setup`: Initialize the environment.
- `./site start`: Start the environment.
- `./site stop`: Stop all containers.
- `./site restart`: Restart the environment.
- `./site rebuild`: Rebuild Docker images from scratch (no cache).
- `./site certs`: Regenerate SSL certificates (e.g. after `mkcert -install` or CA change).
- `./site reset`: **Danger!** Removes all WordPress files, databases, and local configurations to reset the project.

## Project Structure

```text
.
├── certs/                 # Generated SSL certificates (not in git)
├── docker/
│   └── php/
│       └── xdebug.ini     # Xdebug 3 configuration
├── docker-compose.yml     # Docker service definitions
├── Dockerfile             # PHP-FPM image definition
├── nginx.conf.template    # Nginx configuration template
├── site                   # Project management script
├── db                     # Database import/export script
├── wp-config.php          # WordPress configuration
└── ... (WordPress core files)
```

## Xdebug

PHP includes Xdebug 3 for step debugging. Configuration is in `docker/php/xdebug.ini`:

| Setting | Value |
|---------|-------|
| Mode | `debug` |
| Client host | `host.docker.internal` |
| Client port | `9003` |
| Start with request | `yes` |

### Setup

1. Build the image (already done by `./site setup` / `./site rebuild`): `docker compose build php`
2. Start the environment: `./site start`
3. Configure your IDE to listen for Xdebug connections on port 9003.
4. Load the site — breakpoints will be hit.

Changes to `docker/php/xdebug.ini` only need a PHP container restart (no rebuild):

```bash
docker compose restart php
```

To disable Xdebug, comment out `xdebug.mode` in `docker/php/xdebug.ini` and restart PHP.

## Certificates & HTTPS

Local SSL certificates are generated using mkcert and stored in `certs/`. They're automatically installed during `./site start`.

Regenerate leaf certificates (e.g. after `mkcert -install`, a new machine, or browser "Not secure" warnings):

```bash
./site certs      # Removes old certs/, issues new ones, restarts nginx if running
```

## Troubleshooting

- **Port Conflicts**: If ports 80 or 443 are already in use, the `site` script will notify you.
- **Permissions**: The setup scripts attempt to handle ownership issues, but ensure you run them as your regular user (not with `sudo`).
- **Xdebug not connecting**: Verify `xdebug.mode` is set (not empty), check `docker compose logs php` for errors, and ensure your IDE is listening on port 9003.

## Technical Summary

This is a Docker-based boilerplate for local WordPress development using Nginx, PHP 8.3-FPM, and MySQL 8.0. It includes Bash scripts to automate local SSL certificate generation (via `mkcert`), host entry management, and WordPress core initialization.

## Common Tasks

### Shell Access
To enter the PHP container and run commands directly:
```bash
docker compose exec php bash
```

### Running WP-CLI
WP-CLI can be run inside the PHP container. Example to check core version:
```bash
docker compose exec php ./wp-cli.phar core version --allow-root
```

### Database Access
To enter the MySQL shell directly:
```bash
docker compose exec mysql mysql -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME}
```

### Database Import/Export
Use the `./db` script to easily back up or restore your database:

**Export database to SQL file:**
```bash
./db export                  # Export to dump.sql (default)
./db export backup.sql       # Export to backup.sql
```

**Import database from SQL file:**
```bash
./db import backup.sql       # Import from backup.sql (requires confirmation)
```

The script automatically starts the site if needed and uses credentials from your `.env` file.
