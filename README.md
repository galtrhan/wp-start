# WordPress Local Development Environment

This project runs a local WordPress stack with Docker, Nginx, PHP-FPM, and MySQL. Use it for theme and plugin development.

## Features

- **Nginx**: Config includes SSL support through mkcert.
- **PHP 8.3**: WordPress-ready image with Xdebug, GD (JPEG/WebP), and common extensions.
- **MySQL 8.0**: Data stays on a persistent volume.
- **Local HTTPS**: Trusted certificates for local domains.
- **Xdebug 3**: Step debugging from your IDE on port 9003.
- **Scripts**: `./site` and `./db` manage setup, start, stop, certs, and database work.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [mkcert](https://github.com/FiloSottile/mkcert) (for local SSL certificates)
- `lsof` (usually installed on Linux and macOS)

## Getting Started

### 1. Initialization

Clone the repository. Then run the setup script:

```bash
./site setup
```

The script does the following:

- Checks for required tools.
- Creates a `.env` file from `.env.template` (interactive).
- Builds the Docker images.
- Downloads WordPress core files into the current directory.
- Creates a `wp-config.php` that reads the environment variables.

### 2. Starting the Environment

Start the containers and configure the local domain and certificates:

```bash
./site start
```

This command does the following:

- Adds the local domain (default: `wordpress.local`) to `/etc/hosts`.
- Generates and installs local SSL certificates.
- Starts the Nginx, PHP-FPM, and MySQL containers.

Open the site at `https://wordpress.local`.

### 3. Management Scripts

- `./site setup`: Initialize the environment.
- `./site start`: Start the environment.
- `./site stop`: Stop all containers.
- `./site restart`: Restart the environment.
- `./site rebuild`: Rebuild Docker images from scratch (no cache).
- `./site certs`: Regenerate SSL certificates (for example after `mkcert -install` or a CA change).
- `./site standard-ports`: One-time sudo sysctl so rootless Docker can bind ports 80/443.
- `./site refresh-placeholder`: Download the offline placeholder JPG again (`placeholder` mode).
- `./site reset`: **Danger!** Removes all WordPress files, databases, and local configuration.

Containers use `restart: "no"`. After a host reboot they stay stopped until you run `./site start`.

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

PHP includes Xdebug 3 for step debugging. Configuration lives in `docker/php/xdebug.ini`:

| Setting | Value |
|---------|-------|
| Mode | `debug` |
| Client host | `host.docker.internal` |
| Client port | `9003` |
| Start with request | `yes` |

### Setup

1. Build the image (already done by `./site setup` / `./site rebuild`): `docker compose build php`
2. Start the environment: `./site start`
3. Configure your IDE to listen for Xdebug on port 9003 (`.vscode/launch.json` is included).
4. Load the site. The debugger stops at breakpoints.

Check Xdebug inside the running container:

```bash
./scripts/xdebug-status.sh
```

For IDE PHP syntax validation against the container PHP version:

```json
"php.validate.executablePath": "/absolute/path/to/wp-start/scripts/php-docker.sh"
```

After you edit `docker/php/xdebug.ini`, restart PHP only (no rebuild):

```bash
docker compose restart php
```

To disable Xdebug, comment out `xdebug.mode` in `docker/php/xdebug.ini` and restart PHP.

## Rootless Docker

If you use rootless Docker and ports 80/443 are unavailable, `./site start` uses **8080** (HTTP) and **8443** (HTTPS).

To use standard URLs without a port number, run once:

```bash
./site standard-ports   # needs sudo; persists via sysctl
./site restart
```

Or set `NGINX_HTTP_PORT` / `NGINX_HTTPS_PORT` in `.env` for custom ports.

`scripts/docker-env.sh` detects the rootless Docker socket when the default `docker` CLI cannot connect.

## Git hooks (PHPCS / ESLint)

After you add a custom **theme or plugin** with PHPCS (`vendor/bin/phpcs`) and ESLint (`node_modules/eslint`):

```bash
./scripts/install-git-hooks.sh
```

The pre-commit hook lints staged `.php` and `.js` files under each dev target. It skips `node_modules/` and `vendor/`.

Set `THEME_NAME` and/or `PLUGIN_NAME` in `.env` to pin targets. Leave them empty to auto-detect custom themes (`style.css`) and plugins (`{slug}/{slug}.php`), plus any project with `composer.json` / `phpcs.xml`.

Run PHPCS or Composer inside a specific project:

```bash
./scripts/dev-php.sh -w wp-content/plugins/my-plugin composer install
./scripts/dev-php.sh -w wp-content/plugins/my-plugin ./vendor/bin/phpcs includes/class-foo.php
./scripts/theme-php.sh ./vendor/bin/phpcs partials/example.php   # theme shortcut
```

PHPCS needs Docker and a running site (`./site start`). Commands run inside the php container through `dev-php.sh`.

## Certificates and HTTPS

`./site start` uses mkcert to generate local SSL certificates and stores them in `certs/`. The script also installs them.

Regenerate leaf certificates after `mkcert -install`, on a new machine, or when the browser shows "Not secure":

```bash
./site certs      # Removes old certs/, issues new ones, restarts nginx if running
```

## Troubleshooting

- **Port conflicts**: If ports 80 or 443 are already in use, the `site` script reports the conflict.
- **Permissions**: Run the setup scripts as your normal user, not with `sudo`. The scripts try to fix ownership issues.
- **Xdebug not connecting**: Confirm `xdebug.mode` is set (not empty). Check `docker compose logs php` for errors. Make sure your IDE listens on port 9003.

## Technical Summary

This Docker boilerplate runs local WordPress with Nginx, PHP 8.3-FPM, and MySQL 8.0. Bash scripts generate local SSL certificates with `mkcert`, manage host entries, and initialize WordPress core.

## Common Tasks

### Shell Access

Enter the PHP container and run commands directly:

```bash
docker compose exec php bash
```

### Running WP-CLI

Run WP-CLI inside the PHP container. Example: check the core version:

```bash
docker compose exec php ./wp-cli.phar core version --allow-root
```

### Database Access

Open the MySQL shell:

```bash
docker compose exec mysql mysql -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME}
```

### Database Import/Export

Use `./db` to export or import the database.

**Export database to an SQL file:**

```bash
./db export                  # Export to dump.sql (default)
./db export backup.sql       # Export to backup.sql
```

**Import database from an SQL file:**

```bash
./db import backup.sql       # Import from backup.sql (requires confirmation)
./db import -y backup.sql    # Import, then search-replace URLs without prompts
```

After import, the script detects the WordPress table prefix and updates `wp-config.php`. This lets WP-CLI work with dumps that do not use the `wp_` prefix.

The script then asks for the **import source host**. If `IMPORT_SOURCE_HOST` is set in `.env`, that value is pre-filled. Enter `https://example.com` or `example.com`. The script normalizes the value to a host and saves it to `.env`. Search-replace then updates `https://`, `http://`, `//`, and bare host variants to your local domain.

The script starts the site if needed and reads credentials from `.env`.

## Missing uploads (large production sites)

You do not need a full copy of `wp-content/uploads/` for local work. Import the database and theme or plugins. Then choose how Nginx handles missing media under `/wp-content/uploads/`.

Set these in `.env` (see `.env.template`):

| Variable | Description |
|----------|-------------|
| `UPLOADS_FALLBACK` | `off` (default), `proxy`, `placeholder`, or `random_placeholder` |
| `REMOTE_UPLOADS_URL` | Production or staging origin for `proxy` (for example `https://example.com`, no trailing slash) |
| `PLACEHOLDER_DOWNLOAD_URL` | JPG URL fetched once for `placeholder` mode (default: Lorem Picsum 1200×800) |
| `PLACEHOLDER_PHOTO_PROVIDER` | Photo API for `random_placeholder` mode (default: `picsum`) |

### Modes

**`off`** — Serve only files that exist locally. Missing uploads return 404.

**`proxy`** — If a file is not on disk, Nginx fetches it from `REMOTE_UPLOADS_URL`. Use this for layout work without downloading tens of GB.

**`placeholder`** — On first `./site start`, downloads one JPG to `placeholder.jpg` (Lorem Picsum by default). All missing uploads serve that file. After the first download, this mode works offline.

**`random_placeholder`** — Each missing upload redirects to a unique JPG from Lorem Picsum (stable per path). The browser needs network access for each new missing file.

After you change these values, restart so Nginx loads the new config:

```bash
./site restart
```

`./site start` regenerates `docker/nginx/uploads-fallback.conf` from `.env`.

To replace the offline placeholder image:

```bash
./site refresh-placeholder
```

### Typical workflow

1. Import the production database: `./db import dump.sql` (or `./db import -y dump.sql` to run search-replace without prompts)
2. Enter the live site host when prompted (for example `https://example.com` — saved to `IMPORT_SOURCE_HOST` in `.env`)
3. Set `UPLOADS_FALLBACK=proxy` and `REMOTE_UPLOADS_URL` to staging or production
4. Run `./site restart`
