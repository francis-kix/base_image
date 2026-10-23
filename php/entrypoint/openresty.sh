# start openresty if installed; config default matches shop projects (/etc/openresty/nginx.conf)
# note: sourced by srv, must use return instead of exit
[ -x /usr/local/openresty/bin/openresty ] || return 0

conf="${NGINX_CONF:-/etc/openresty/nginx.conf}"
[ -f "$conf" ] || conf=/usr/local/openresty/nginx/conf/nginx.conf

mkdir -p /var/log/openresty /var/run/php

/usr/local/openresty/bin/openresty -t -c "$conf" 2>&1 || return 0

# append "daemon off" only when the config does not define it
extra=()
grep -Eq '^[[:space:]]*daemon[[:space:]]' "$conf" || extra=(-g 'daemon off;')

job nginx /usr/local/openresty/bin/openresty -c "$conf" ${extra[@]+"${extra[@]}"}
