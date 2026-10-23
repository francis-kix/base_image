ARG PHP_VERSION=8.4
ARG DROPBEAR_IMAGE=ghcr.io/orbsh/assets:dropbear
FROM ${DROPBEAR_IMAGE} AS dropbear
FROM debian:bookworm-slim
COPY --from=dropbear /bin/ /out/dropbear/bin/
COPY --from=dropbear /libexec/ /out/dropbear/libexec/
RUN ln -sf /out/dropbear/bin/dropbear /usr/bin/dropbear \
  ; ln -sf /out/dropbear/bin/dropbearkey /usr/bin/dropbearkey \
  ; ln -sf /out/dropbear/bin/dropbearconvert /usr/bin/dropbearconvert \
  ; ln -sf /out/dropbear/bin/dbclient /usr/bin/dbclient \
  ; ln -sf /out/dropbear/bin/scp /usr/bin/scp \
  ; ln -sf /out/dropbear/libexec/sftp-server /usr/lib/sftp-server

EXPOSE 80 8080 22

ENV TIMEZONE=Asia/Shanghai

RUN set -eux \
  ; apt-get update \
  ; apt-get install -y --no-install-recommends \
        ca-certificates curl jq unzip procps tzdata gnupg \
    ; ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
    ; echo $TIMEZONE > /etc/timezone

COPY versions.env /tmp/versions.env

RUN set -eux \
  ; . /tmp/versions.env \
  ; curl -fsSL https://openresty.org/package/pubkey.gpg \
      | gpg --dearmor -o /usr/share/keyrings/openresty.gpg \
  ; echo "deb [signed-by=/usr/share/keyrings/openresty.gpg] http://openresty.org/package/debian ${OPENRESTY_DIST} openresty" \
      > /etc/apt/sources.list.d/openresty.list \
  ; apt-get update \
  ; apt-get install -y --no-install-recommends openresty \
  ; apt-get remove -y gnupg \
  ; apt-get autoremove -y \
  ; apt-get clean -y \
  ; rm -rf /var/lib/apt/lists/*

ARG PHP_VERSION
ENV PHP_VERSION=${PHP_VERSION}
ENV PHP_PKGS \
        php${PHP_VERSION} \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-ast \
        php${PHP_VERSION}-xdebug

RUN set -eux \
  ; . /tmp/versions.env \
  ; curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \
  ; echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ ${SURY_DIST} main" \
    | tee /etc/apt/sources.list.d/php.list \
  ; apt-get update \
  ; apt-get install -y --no-install-recommends $PHP_PKGS \
  ; apt-get autoremove -y \
  ; apt-get clean -y \
  ; rm -rf /var/lib/apt/lists/* \
  ;

RUN set -eux \
  ; ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm \
  ; sed -e 's!^.*\(date.timezone =\).*$!\1 Asia/Shanghai!' \
        -e 's!^.*\(track_errors =\).*$!\1 Off!' \
        -e 's!^\(error_reporting =.*\)$!\1 \& ~E_NOTICE \& ~E_WARNING!' \
        -i /etc/php/${PHP_VERSION}/fpm/php.ini \
  ; sed -e 's!.*\(daemonize =\).*!\1 no!' \
        -e 's!.*\(error_log =\).*!\1 /var/log/php-fpm/fpm.log!' \
        -i /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \
  ; mkdir -p /var/log/php-fpm \
  ; sed -e 's!\(listen =\).*!\1 /var/run/php/php-fpm.sock!' \
        -e 's!.*\(slowlog =\).*$!\1 /var/log/php-fpm/fpm.log.slow!' \
        -e 's!.*\(clear_env =\).*$!\1 no!' \
        -e 's!.*\(pm.start_servers =\).*$!\1 6!' \
        -e 's!.*\(pm.min_spare_servers =\).*$!\1 5!' \
        -e 's!.*\(pm.max_spare_servers =\).*$!\1 10!' \
        -e 's!.*\(pm.max_children =\).*$!\1 10!' \
        -i /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \
  ; mkdir -p /var/run/php /etc/openresty /var/log/openresty \
  ; chown www-data:www-data /var/run/php

RUN set -eux \
  ; . /tmp/versions.env \
  ; mkdir /webgrind \
  ; curl --retry 3 -fsSL https://github.com/jokkedk/webgrind/archive/refs/tags/${WEBGRIND_VERSION}.tar.gz \
      | tar -zxf - -C /webgrind --strip-components=1 \
  ;

COPY setup-php /setup-php
COPY entrypoint /entrypoint/
COPY srv /usr/local/bin/srv
COPY index.php /srv/
RUN sed -i 's/\r$//' /entrypoint/*.sh /usr/local/bin/srv /setup-php \
  ; chmod +x /usr/local/bin/srv /entrypoint/*.sh
CMD ["srv"]
WORKDIR /srv

RUN set -ex \
  ; curl --retry 3 -fsSL https://getcomposer.org/installer \
    | php -- --install-dir=/usr/local/bin --filename=composer

ENV PHP_DEBUG=
ENV PHP_PROFILE=
ENV PHP_FPM_SERVERS=
ENV UPLOAD_MAX_FILESIZE=
