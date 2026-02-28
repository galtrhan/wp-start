FROM php:8.3-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    mysql-client \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    icu-dev \
    oniguruma-dev \
    linux-headers

# Install PHP extensions
RUN docker-php-ext-install \
    mysqli \
    pdo_mysql \
    gd \
    zip \
    bcmath \
    intl \
    opcache

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configure Git safe directory
RUN git config --global --add safe.directory /var/www/html

WORKDIR /var/www/html

# Use the default production configuration and increase memory limit
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" && \
    sed -i 's/memory_limit = 128M/memory_limit = 512M/g' "$PHP_INI_DIR/php.ini"

CMD ["php-fpm"]
