#!/bin/bash
# start openresty if installed; config default matches shop projects (/etc/openresty/nginx.conf)
[ -x /usr/local/openresty/bin/openresty ] || exit 0

conf="${NGINX_CONF:-/etc/openresty/nginx.conf}"
[ -f "$conf" ] || conf=/usr/local/openresty/nginx/conf/nginx.conf

mkdir -p /var/log/openresty /var/run/php

/usr/local/openresty/bin/openresty -t -c "$conf" 2>&1 || exit 0

/usr/local/openresty/bin/openresty -c "$conf" -g 'daemon off;' 2>&1 &
echo -n "$! " >> /var/run/services
