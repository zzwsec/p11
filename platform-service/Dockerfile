FROM alpine AS code

WORKDIR /var/www/html
COPY src/ ./src/
COPY public/ ./public/
COPY vendor/ ./vendor/

WORKDIR /usr/local/bin
COPY <<'EOF' ./docker-php-entrypoint
#!/bin/sh
set -e

mkdir -p /var/www/html/logs
chown -R 82:82 /var/www/html/logs

if [ "${1#-}" != "$1" ]; then
	set -- php "$@"
fi

exec "$@"
EOF
RUN chmod +x ./docker-php-entrypoint


FROM zzwsec/php:8.1.34

COPY --chown=82:82 --from=code /var/www/html /var/www/html
COPY --from=code /usr/local/bin/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint