FROM php:7.4.1-fpm-buster

RUN apt-get update && apt-get install -y curl gnupg2 ca-certificates lsb-release git unzip libcurl4-openssl-dev zlib1g-dev libpng-dev libonig-dev libpq-dev libssl-dev libedit-dev libxml2-dev libxslt1-dev libzip-dev && \
    echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - && \
    apt-get update && apt-get install -y nginx && \
    mkdir -p /app && chown www-data:www-data /app && mkdir -p /opt/composer && chown www-data:www-data /opt/composer && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === 'c5b9b6d368201a9db6f74e2611495f369991b72d9c8cbd3ffbc63edff210eb73d46ffbfce88669ad33695ef77dc76976') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/opt/composer --version=1.9.2 && \
    php -r "unlink('composer-setup.php');" && \
    pecl install -f redis-5.1.1 && \
    docker-php-ext-install -j$(nproc) bcmath curl gd gettext iconv json mbstring opcache pcntl pdo pdo_mysql pdo_pgsql phar readline session xml xsl zip && \
    docker-php-ext-enable redis && \
    rm /etc/nginx/conf.d/default.conf

USER www-data
WORKDIR /app
ENV COMPOSER_HOME /opt/composer

ADD --chown=www-data:www-data composer.json /app
ADD --chown=www-data:www-data composer.lock /app
RUN mkdir -p storage/app/public && mkdir -p storage/framework/cache && mkdir -p storage/logs && \
    mkdir -p storage/framework/sessions && mkdir -p storage/framework/testing && mkdir -p storage/framework/views && \
    php /opt/composer/composer.phar install --prefer-dist --no-scripts --no-autoloader
ADD docker/php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf
ADD docker/nginx/nginx.conf /etc/nginx/nginx.conf
ADD docker/nginx/default.conf /etc/nginx/sites-enabled/default
ADD docker/php/php.ini /usr/local/etc/php
ADD --chown=www-data:www-data . /app
RUN php /opt/composer/composer.phar install --prefer-dist

USER root

