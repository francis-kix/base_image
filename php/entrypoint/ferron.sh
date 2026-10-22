config="--config ${CONFIGFILE:-/opt/ferron/ferron.kdl}"

[ -x /opt/ferron/ferron ] || return 0

cmd="/opt/ferron/ferron ${config}"

eval "$cmd 2>&1 &"
echo -n "$! " >> /var/run/services
