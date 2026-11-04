# php

PHP 8 + ferron 2.8 image, built in two layers.

| File | Image | Content |
|------|-------|---------|
| `deb.Dockerfile` | `iteainger/base_image:deb` | Debian sid + the package set from `~/data/docker.io/xy/images/core/deb.nu:21` + dropbear from `ghcr.io/orbsh/assets:dropbear` |
| `Dockerfile` | `iteainger/base_image:php` | PHP 8.4 (fpm, cli, opcache, redis, xdebug, …) + composer + ferron 2.8, bash entrypoint |

ferron is not pinned: the build asks the GitHub releases API for the newest stable release on the
2.8.x line (today that resolves to `2.8.1`). The 2.8 musl build ships as a zip (no `ferron-fmt` in
2.x), and the CLI is `ferron --config` (no `run` subcommand, `ferron --version` instead of
`ferron version`). The lookup is a normal
`RUN`, so layer caching pins it again — build with `--no-cache` when you actually want a new release.

```bash
podman build -f deb.Dockerfile -t iteainger/base_image:deb .
podman build -f Dockerfile     -t iteainger/base_image:php .

podman run --rm -p 8080:8080 -p 2222:22 iteainger/base_image:php
```

CI builds the same pair from the generated `php.yaml`: `deb.Dockerfile` is tagged `:deb`, and the php
layer gets `BASEIMAGE=ghcr.io/iteainger/base_image:deb` (see `x.yaml` → `generate.repo.php`), since the
`ARG BASEIMAGE` default stays the local-friendly short name.

`http://localhost:8080/` renders `phpinfo()` from `/srv/index.php`.

## Files

- `ferron.conf` — ferron 2.8 config (adapted from the ferron 3 copy of `xy/images/service/ferron/php.conf`; `file`/`directory` in `rewrite` must be quoted strings in 2.x): serves `/srv` on `:8080`, rewrites everything to `/index.php/…`, and passes PHP requests to `unix:///var/run/php/php-fpm.sock`. Validated against the ferron 2.8 KDL parser.
- `setup-php` — runtime overrides applied on boot (`UPLOAD_MAX_FILESIZE`, `PHP_FPM_SERVERS`, `PHP_DEBUG`, `PHP_PROFILE`, `PHP_TRACE`, `CONF_PHP_*`, `CONF_FPM_*`, `CONF_POOL_*`). Runs once, then `/setup-php.<timestamp>` marks it done.
- `entrypoint/` — bash startup framework, parameter-compatible with `xy/entrypoint/*.nu`:

| Env | Meaning |
|-----|---------|
| `s3_<id>=mount,user,endpoint,region,bucket,accesskey,secretkey,opts…` | one s3fs mount per variable (same as `s3fs.nu`) |
| `ed25519_<user>=<pubkey>` | enables dropbear; `<user>` is `name:uid:gid[:comment]` |
| `SSH_HOSTKEY_ED25519` / `SSH_TIMEOUT` / `SSH_SUDO_GROUP` | dropbear host key (base64), idle timeout, extra sudo group |
| `CRONFILE` | crontab file, loaded and run with `cron -f` |
| `PREBOOT` / `POSTBOOT` / `DEBUG` | sourced around boot, `DEBUG=true` sets `-x` |
| `CONFIGFILE` | ferron config, default `/etc/ferron.conf` |

Boot order is not preset by `init.sh`: it sources every `*.sh` in name order. Both daemons of the web
stack live in `php.sh` — php-fpm master first, then (after the socket appears) the ferron front, because
ferron proxies to the socket php-fpm creates. Every background process writes its PID into
`/var/run/services`; any exit stops the container so the runtime restarts it.

`CMD ["srv"]` (from the Dockerfile) = run services; no argument = interactive shell; anything else = batch mode.