# run setup-php with env intact, then register php-fpm
if [ -f /setup-php ]; then
    bash /setup-php
    touch "/setup-php.$(date -Is)"
fi

job php-fpm /usr/sbin/php-fpm --nodaemonize
