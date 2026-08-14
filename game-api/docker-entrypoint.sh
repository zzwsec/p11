#!/bin/sh
set -e

APP_DIR="/app"

log_info()  { printf "[entrypoint][INFO]  %s\n" "$*"; }
log_warn()  { printf "[entrypoint][WARN]  %s\n" "$*"; }
log_error() { printf "[entrypoint][ERROR] %s\n" "$*" >&2; exit 1; }

require_env() {
    if [ -z "$2" ]; then
        log_error "$1 is required"
    fi
}

validate_environment() {
    require_env "MYSQL_HOST" "${MYSQL_HOST:-}"
    require_env "MYSQL_PORT" "${MYSQL_PORT:-}"
    require_env "MYSQL_USER" "${MYSQL_USER:-}"
    require_env "MYSQL_PASSWORD" "${MYSQL_PASSWORD:-}"
    require_env "MYSQL_DATABASE" "${MYSQL_DATABASE:-}"

    require_env "REDIS_HOST" "${REDIS_HOST:-}"
    require_env "REDIS_PORT" "${REDIS_PORT:-}"
    require_env "REDIS_NAMESPACE" "${REDIS_NAMESPACE:-}"
    require_env "REDIS_PASSWORD" "${REDIS_PASSWORD:-}"
}

tcp_check() {
    TCP_CHECK_HOST="$1" TCP_CHECK_PORT="$2" luajit -e '
        local s = require("socket")
        local c = s.tcp()
        c:settimeout(2)
        local ok = c:connect(os.getenv("TCP_CHECK_HOST"), tonumber(os.getenv("TCP_CHECK_PORT")))
        c:close()
        if not ok then os.exit(1) end
    ' 2>/dev/null
}

wait_for_service() {
    _name="$1"
    _host="$2"
    _port="$3"
    _timeout="${DEPENDENCY_WAIT_TIMEOUT:-60}"
    _interval="${DEPENDENCY_WAIT_INTERVAL:-2}"
    _elapsed=0

    log_info "Waiting for ${_name} at ${_host}:${_port} (timeout=${_timeout}s) …"
    while ! tcp_check "${_host}" "${_port}"; do
        if [ "${_elapsed}" -ge "${_timeout}" ]; then
            log_error "Timed out waiting for ${_name} at ${_host}:${_port}"
        fi
        log_warn "Waiting for ${_name} at ${_host}:${_port} … (${_elapsed}/${_timeout}s)"
        sleep "${_interval}"
        _elapsed=$(( _elapsed + _interval ))
    done
    log_info "✅ ${_name} at ${_host}:${_port} is reachable"
}

wait_for_dependencies() {
    wait_for_service "MySQL" "${MYSQL_HOST}" "${MYSQL_PORT}"
    wait_for_service "Redis" "${REDIS_HOST}" "${REDIS_PORT}"
}

ensure_database() {
    log_info "Ensuring MySQL database '${MYSQL_DATABASE}' exists …"
    if luajit -e '
        local mysql = require("luasql.mysql")
        local environment = assert(mysql.mysql())
        local connection, connect_error = environment:connect(
            "",
            os.getenv("MYSQL_USER"),
            os.getenv("MYSQL_PASSWORD"),
            os.getenv("MYSQL_HOST"),
            tonumber(os.getenv("MYSQL_PORT"))
        )
        if not connection then
            io.stderr:write(connect_error, "\n")
            os.exit(1)
        end

        local database = assert(os.getenv("MYSQL_DATABASE")):gsub("`", "``")
        local result, create_error = connection:execute(
            "CREATE DATABASE IF NOT EXISTS `" .. database .. "`"
        )
        if not result then
            io.stderr:write(create_error, "\n")
            os.exit(1)
        end

        connection:close()
        environment:close()
    '; then
        log_info "✅ MySQL database '${MYSQL_DATABASE}' is ready"
    else
        log_error "Unable to create or access MySQL database '${MYSQL_DATABASE}'"
    fi
}

run_migrations() {
    log_info "Running database migrations …"
    cd "${APP_DIR}"
    if lapis migrate "${LAPIS_ENVIRONMENT:-production}"; then
        log_info "✅ Migrations completed"
    else
        log_error "Migration failed!"
    fi
}

print_summary() {
    log_info "-------- Runtime Summary --------"
    log_info "LAPIS_ENVIRONMENT = ${LAPIS_ENVIRONMENT:-production}"
    log_info "PORT              = ${PORT:-80}"
    log_info "NUM_WORKERS       = ${NUM_WORKERS:-4}"
    log_info "CODE_CACHE        = ${CODE_CACHE:-on}"
    log_info "MYSQL_ENDPOINT    = ${MYSQL_HOST}:${MYSQL_PORT}"
    log_info "REDIS_ENDPOINT    = ${REDIS_HOST}:${REDIS_PORT}"
    log_info "---------------------------------"
}

main() {
    validate_environment
    print_summary
    wait_for_dependencies
    ensure_database
    run_migrations

    cd "${APP_DIR}"

    # If first arg looks like a flag, prepend "openresty"
    if [ "${1#-}" != "$1" ]; then
        set -- openresty "$@"
    fi

    # Default: generate the Nginx configuration, then make OpenResty PID 1.
    if [ "$#" -eq 0 ]; then
        _environment="${LAPIS_ENVIRONMENT:-production}"
        log_info "Building OpenResty configuration (${_environment}) …"
        if lapis build "${_environment}"; then
            log_info "✅ OpenResty configuration built"
        else
            log_error "Unable to build OpenResty configuration"
        fi

        log_info "Starting OpenResty (${_environment}) …"
        exec openresty -p "${APP_DIR}/" -c nginx.conf.compiled
    fi

    # lapis subcommand
    if [ "$1" = "lapis" ]; then
        shift
        log_info "Executing: lapis $* …"
        exec lapis "$@"
    fi

    # openresty / nginx / anything else — pass through
    log_info "Executing: $* …"
    exec "$@"
}

main "$@"
