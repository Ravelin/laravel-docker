FROM composer:latest AS build
COPY src/ /app/

RUN composer install --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader

FROM php:8.1-fpm-alpine3.16

WORKDIR /var/www/html

# Composer - https://getcomposer.org/download/
ARG COMPOSER_VERSION="2.4.4"
ARG COMPOSER_SUM="c252c2a2219956f88089ffc242b42c8cb9300a368fd3890d63940e4fc9652345"

# Install system dependencies
ENV RUN_DEPS \
  git \
  gnupg \
  unzip \
  curl \
  fcgi \
  wget \
  icu-dev \
  gettext-dev

ENV BUILD_DEPS \
  zlib-dev \
  libzip-dev \
  gmp-dev \
  icu-dev \
  libpng-dev \
  libjpeg-turbo-dev\
  wget \
  openssl-dev \
  gettext-dev

ENV PHP_EXTENSIONS \
  pdo_mysql \
  gettext \
  bcmath \
  zip \
  gmp \
  gd \
  intl \
  sockets

ENV PECL_EXTENSIONS redis mailparse mongodb-1.12.1
ENV PECL_EXTENSIONS_NAMES redis mailparse mongodb

# Install Dependencies
RUN \
  apk update && \
  apk add --no-cache $RUN_DEPS $BUILD_DEPS && \
  apk add --no-cache $PHPIZE_DEPS && \
  rm -rf /var/cache/apk/*

# Install PHP Extensions
RUN \
  # ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
  docker-php-ext-configure gmp && \
  docker-php-ext-configure intl && \
  docker-php-ext-configure gd --with-jpeg && \
  docker-php-ext-install $PHP_EXTENSIONS && \
  pecl install $PECL_EXTENSIONS && \
  docker-php-ext-enable $PECL_EXTENSIONS_NAMES && \
  docker-php-source delete && \
  rm -r /tmp/pear/*

# Setup Storage
RUN mkdir -p bootstrap/cache storage/framework storage/framework/cache storage/framework/sessions storage/framework/views storage/logs && \
  chown -R www-data:www-data bootstrap/cache && \
  chown -R www-data:www-data storage/ && \
  chmod -R 775 bootstrap/cache
  chmod -R 775 storage/

# Copy PHP Config
COPY /confs/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY /confs/fpm-pool.conf /usr/local/etc/php-fpm.d/www.conf

COPY /src/artisan /var/www/html/
COPY /src/composer.* /var/www/html/
COPY --chown=www-data:www-data --from=build /app /var/www/html/src
COPY --chown=www-data:www-data /src/resources /var/www/html/resources
COPY --chown=www-data:www-data --from=build /app/vendor /var/www/html/vendor
COPY --chown=www-data:www-data --from=build /app/public/index.php /var/www/html/public/

# Remove Unneeded files
RUN rm /var/www/html/src/artisan
RUN rm -rf /var/www/html/src/vendor

RUN cp src/.env.example src/.env
RUN /bin/sh -c "/var/www/html/artisan key:generate --ansi"
# CMD [ "/bin/sh -c /var/www/html/artisan", "key:generate --ansi" ]
# RUN /var/www/html/artisan key:generate --ansi

RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www
