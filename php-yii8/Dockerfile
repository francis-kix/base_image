# build:2 vendor layer for shop-mro (yii 2.0.55 / php 8.4)
FROM ghcr.io/francis-kix/base_image:php8-shop

WORKDIR /srv

COPY composer.json composer.lock ./

RUN composer install --no-cache --optimize-autoloader --no-interaction --ignore-platform-reqs \
    && mv vendor /opt
