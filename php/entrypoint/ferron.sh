# ferron is only present in ferron-based images (v8.Dockerfile); no-op otherwise
[ -x /opt/ferron/ferron ] || return 0

config="--config ${CONFIGFILE:-/opt/ferron/ferron.kdl}"

job ferron /opt/ferron/ferron $config
