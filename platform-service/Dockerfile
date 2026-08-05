FROM zzwsec/php:8.1.34 AS vendor

ARG COMPOSER_VERSION=2.10.2
ARG COMPOSER_URL="https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar"

RUN wget -O /usr/local/bin/composer "${COMPOSER_URL}" \
    && chmod +x /usr/local/bin/composer

COPY composer.json composer.lock ./
COPY src/ ./src/
COPY public/ ./public/

RUN composer install --no-dev --prefer-dist --no-progress --optimize-autoloader --no-scripts

COPY <<'EOF' /usr/local/bin/docker-php-entrypoint
#!/bin/sh
set -e

mkdir -p /var/www/html/logs
chown -R 82:82 /var/www/html/logs

if [ "${1#-}" != "$1" ]; then
    set -- php "$@"
fi

exec "$@"
EOF
RUN chmod +x /usr/local/bin/docker-php-entrypoint


FROM zzwsec/php:8.1.34

COPY --chown=82:82 --from=vendor /var/www/html/ /var/www/html/
COPY --from=vendor /usr/local/bin/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint