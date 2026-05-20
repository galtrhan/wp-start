FROM php:8.3-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    bash \
    shadow \
    mysql-client \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    icu-dev \
    oniguruma-dev \
    linux-headers

# Match www-data to host user ID
RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data

# GD with JPEG, WebP, FreeType
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

# Install PHP extensions
RUN docker-php-ext-install \
    mysqli \
    pdo_mysql \
    gd \
    zip \
    bcmath \
    intl \
    opcache

# Xdebug (dev debugging from host IDE on port 9003)
COPY docker/php/xdebug.ini /usr/local/etc/php/conf.d/zzz-xdebug.ini
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del $PHPIZE_DEPS

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configure Git safe directory
RUN git config --global --add safe.directory /var/www/html

WORKDIR /var/www/html

# Use the default production configuration and increase limits
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" && \
    sed -i 's/memory_limit = 128M/memory_limit = 512M/g' "$PHP_INI_DIR/php.ini" && \
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 1024M/g' "$PHP_INI_DIR/php.ini" && \
    sed -i 's/post_max_size = 8M/post_max_size = 1024M/g' "$PHP_INI_DIR/php.ini"

CMD ["php-fpm"]
