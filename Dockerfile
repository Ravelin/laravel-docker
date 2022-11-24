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

# Install Composer
RUN set -eux \
    && curl -LO "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar" \
    && echo "${COMPOSER_SUM}  composer.phar" | sha256sum -c - \
    && chmod +x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && composer --version \
    && true

# Setup Storage
RUN mkdir -p bootstrap/cache storage/framework storage/framework/cache storage/framework/sessions storage/framework/views storage/logs && \
  chown -R www-data:www-data bootstrap/cache && \
  chmod -R 775 bootstrap/cache

COPY /src/composer.* /var/www/html/
COPY /src /var/www/html/src
COPY /src/artisan /var/www/html/
COPY /src/resources /var/www/html/resources
COPY /src/public/index.php /var/www/html/public/

# Install Composer Dependencies
RUN php -d disable_functions='' /usr/local/bin/composer install --no-dev --no-interaction --no-scripts --no-suggest --optimize-autoloader && \
rm -f composer.lock

RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www

RUN chown -R www-data:www-data /var/www/html

#USER www

# COPY --chown=www-data:www-data . /var/www/html
