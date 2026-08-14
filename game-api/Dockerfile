# syntax=docker/dockerfile:1

FROM zzwsec/openresty:1.31.1.1-luarocks

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY --exclude=config app/src/ /app/src/
COPY config/ /app/

RUN find /app -name '*.lua' -print0 | xargs -0 -I {} luajit -b {} /dev/null \
    && chmod +x /docker-entrypoint.sh

ENV LUA_PATH="/app/?.lua;/app/src/?.lua;/app/src/?/init.lua;;${LUA_PATH}"
ENV MARIADB_TLS_DISABLE_PEER_VERIFICATION=1

WORKDIR /app

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO /dev/null http://127.0.0.1:${PORT:-80}/health || exit 1

STOPSIGNAL SIGQUIT

ENTRYPOINT ["/docker-entrypoint.sh"]
