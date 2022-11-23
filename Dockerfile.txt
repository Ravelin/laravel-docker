FROM php:8.1-fpm

WORKDIR /var/www/html

# Install system dependencies
ENV RUN_DEPS \
  git \
  gnupg2 \
  unzip \
  curl \
  libfcgi-bin \
  wget

ENV BUILD_DEPS \
  zlib1g-dev \
  libzip-dev \
  libgmp-dev \
  libicu-dev \
  libpng-dev \
  libjpeg62-turbo-dev \
  wget \
  libssl-dev

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
  apt-get update && \
  apt-get install -y $RUN_DEPS $BUILD_DEPS --no-install-recommends && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install PHP Extensions
RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
  docker-php-ext-configure gmp && \
  docker-php-ext-configure intl && \
  docker-php-ext-configure gd --with-jpeg && \
  docker-php-ext-install $PHP_EXTENSIONS && \
  pecl install $PECL_EXTENSIONS && \
  docker-php-ext-enable $PECL_EXTENSIONS_NAMES && \
  docker-php-source delete && \
  rm -r /tmp/pear/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Setup user and group
RUN groupadd -g 1000 www && \
  useradd -u 1000 -ms /bin/bash -g www www

# Setup Storage
RUN mkdir -p bootstrap/cache storage/framework storage/framework/cache storage/framework/sessions storage/framework/views storage/logs && \
  chown -R www:www bootstrap/cache && \
  chmod -R 775 bootstrap/cache

COPY /src/composer.* /var/www/html/
COPY /src /var/www/html/src
COPY /src/artisan /var/www/html/
COPY /src/resources /var/www/html/resources
COPY /src/public/index.php ./public

# Install Composer Dependencies
RUN php -d disable_functions='' /usr/local/bin/composer install --no-dev --no-interaction --no-scripts --no-suggest --optimize-autoloader && \
rm -f composer.lock
