# WordPress Local Development Environment

A Docker-based local development environment for WordPress with Nginx, PHP-FPM, and MySQL. Suited for **theme and plugin** development.

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
- `./site standard-ports`: One-time sudo sysctl so rootless Docker can bind ports 80/443.
- `./site refresh-placeholder`: Re-download the offline placeholder JPG (`placeholder` mode).
- `./site reset`: **Danger!** Removes all WordPress files, databases, and local configurations to reset the project.

Containers use `restart: "no"` — they stay stopped after a host reboot until you run `./site start`.

## Project Structure

```text
.
├── certs/                 # Generated SSL certificates (not in git)
├── docker/
│   ├── nginx/
│   │   └── uploads-fallback.conf    # Generated Nginx uploads rules (from .env)
│   └── php/
│       └── xdebug.ini     # Xdebug 3 configuration
├── scripts/
│   ├── docker-env.sh      # Rootless Docker socket detection
│   ├── php-docker.sh      # Run PHP in the container (IDE validation)
│   ├── xdebug-status.sh   # Print Xdebug settings from the php container
│   ├── dev-php.sh         # Run commands in a theme or plugin directory
│   ├── theme-php.sh       # Theme-only wrapper around dev-php.sh
│   ├── wp.sh              # WP-CLI inside the php container
│   ├── install-git-hooks.sh
│   └── git-hooks/pre-commit  # PHPCS + ESLint on staged theme/plugin files
├── placeholder-image.php  # Per-path JPG redirects (random_placeholder mode only)
├── placeholder.jpg        # Downloaded offline placeholder (placeholder mode; gitignored)
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
3. Configure your IDE to listen for Xdebug connections on port 9003 (`.vscode/launch.json` is included).
4. Load the site — breakpoints will be hit.

Check Xdebug inside the running container:

```bash
./scripts/xdebug-status.sh
```

For IDE PHP syntax validation against the container PHP version:

```json
"php.validate.executablePath": "/absolute/path/to/wp-start/scripts/php-docker.sh"
```

Changes to `docker/php/xdebug.ini` only need a PHP container restart (no rebuild):

```bash
docker compose restart php
```

To disable Xdebug, comment out `xdebug.mode` in `docker/php/xdebug.ini` and restart PHP.

## Rootless Docker

If you use rootless Docker and ports 80/443 are unavailable, `./site start` automatically falls back to **8080** (HTTP) and **8443** (HTTPS).

To use standard URLs without a port number, run once:

```bash
./site standard-ports   # needs sudo; persists via sysctl
./site restart
```

Or set `NGINX_HTTP_PORT` / `NGINX_HTTPS_PORT` in `.env` to keep custom ports.

`scripts/docker-env.sh` auto-detects the rootless Docker socket when the default `docker` CLI cannot connect.

## Git hooks (PHPCS / ESLint)

After adding a custom **theme or plugin** with PHPCS (`vendor/bin/phpcs`) and ESLint (`node_modules/eslint`):

```bash
./scripts/install-git-hooks.sh
```

The pre-commit hook lints staged `.php` and `.js` files (excluding `node_modules/` and `vendor/`) under each dev target. Set `THEME_NAME` and/or `PLUGIN_NAME` in `.env` to pin targets, or leave empty to auto-detect custom themes (`style.css`) and plugins (`{slug}/{slug}.php`) plus any project with `composer.json` / `phpcs.xml`.

Run PHPCS/Composer inside a specific project:

```bash
./scripts/dev-php.sh -w wp-content/plugins/my-plugin composer install
./scripts/dev-php.sh -w wp-content/plugins/my-plugin ./vendor/bin/phpcs includes/class-foo.php
./scripts/theme-php.sh ./vendor/bin/phpcs partials/example.php   # theme shortcut
```

Requires Docker and `./site start` for PHPCS (runs inside the php container via `dev-php.sh`).

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
./db import -y backup.sql    # Import, then search-replace URLs without prompting
```

After import, the script **auto-detects the WordPress table prefix** from the database and updates `wp-config.php` (so WP-CLI works with non-`wp_` dumps). You'll then be prompted for the **import source host** (pre-filled from `IMPORT_SOURCE_HOST` in `.env` if set). Enter `https://example.com` or `example.com` — it's normalized to a host and saved to `.env`. Search-replace then updates `https://`, `http://`, `//`, and bare host variants to your local domain.

The script automatically starts the site if needed and uses credentials from your `.env` file.

## Missing uploads (large production sites)

You do not need to sync all of `wp-content/uploads/` for local development. Import the database and theme/plugins, then choose how Nginx handles missing media files under `/wp-content/uploads/`.

Set these in `.env` (see `.env.template`):

| Variable | Description |
|----------|-------------|
| `UPLOADS_FALLBACK` | `off` (default), `proxy`, `placeholder`, or `random_placeholder` |
| `REMOTE_UPLOADS_URL` | Production/staging origin when using `proxy` (e.g. `https://example.com`, no trailing slash) |
| `PLACEHOLDER_DOWNLOAD_URL` | JPG URL fetched once for `placeholder` mode (default: Lorem Picsum 1200×800) |
| `PLACEHOLDER_PHOTO_PROVIDER` | Photo API for `random_placeholder` mode (default: `picsum`) |

### Modes

**`off`** — Serve only files that exist locally. Missing uploads return 404.

**`proxy`** — If a file is not on disk, Nginx fetches it from `REMOTE_UPLOADS_URL`. Best for layout work without downloading tens of GB.

**`placeholder`** — Downloads one JPG to `placeholder.jpg` on first `./site start` (from Lorem Picsum by default). All missing uploads serve that file. **Fully offline** after the initial download.

**`random_placeholder`** — Each missing upload redirects to a unique JPG from Lorem Picsum (stable per path). Requires network in the browser on each new missing file.

After changing these values, restart so Nginx picks up the new config:

```bash
./site restart
```

`./site start` regenerates `docker/nginx/uploads-fallback.conf` from `.env` automatically.

To replace the offline placeholder image:

```bash
./site refresh-placeholder
```

### Typical workflow

1. Import production DB: `./db import dump.sql` (or `./db import -y dump.sql` to auto-run search-replace)
2. Enter the live site host when prompted (e.g. `https://example.com` — saved to `IMPORT_SOURCE_HOST` in `.env`)
3. Set `UPLOADS_FALLBACK=proxy` and `REMOTE_UPLOADS_URL` to staging or production
4. `./site restart`
