local config = require "lapis.config"

-- lua库路径
local lua_path = os.getenv("LUA_PATH") or "../?.lua;../src/?.lua;../src/?/init.lua"
local lua_cpath = os.getenv("LUA_CPATH") or ""

config("development", {
    server      = "nginx",
    code_cache  = os.getenv("CODE_CACHE") or "off",
    num_workers = os.getenv("NUM_WORKERS") or "1",
    port        = tonumber(os.getenv("PORT")) or 80,
    lua_path    = lua_path,
    lua_cpath   = lua_cpath,
    mysql       = {
        host      = os.getenv("MYSQL_HOST") or "127.0.0.1",
        port      = tonumber(os.getenv("MYSQL_PORT")) or 3306,
        user      = os.getenv("MYSQL_USER") or "root",
        password  = os.getenv("MYSQL_PASSWORD"),
        database  = os.getenv("MYSQL_DATABASE") or "api",
        adapter   = "mysql",
        charset   = "utf8mb4",
        timezone  = os.getenv("TZ") or "Asia/Shanghai"
    },
    redis       = {
        host     = os.getenv("REDIS_HOST") or "127.0.0.1",
        port     = tonumber(os.getenv("REDIS_PORT")) or 6379,
        -- 保留 database 字段以兼容现有 Key 生成逻辑，实际表示命名空间
        database = os.getenv("REDIS_NAMESPACE") or "api",
        password = os.getenv("REDIS_PASSWORD"),
    },
    cache       = {
        shm_name = os.getenv("CACHE_SHM_NAME") or "cache_shm",
        ipc_shm  = os.getenv("CACHE_IPC_SHM") or "ipc_shm",
        lru_size = tonumber(os.getenv("CACHE_LRU_SIZE")) or 1024 * 1024 * 10,
        ttl      = tonumber(os.getenv("CACHE_TTL")) or 300,
        neg_ttl  = tonumber(os.getenv("CACHE_NEG_TTL")) or 60,
    }
})

config("production", {
    server      = "nginx",
    code_cache  = "on",
    num_workers = os.getenv("NUM_WORKERS") or "4",
    port        = tonumber(os.getenv("PORT")) or 80,
    lua_path    = lua_path,
    lua_cpath   = lua_cpath,
    mysql       = {
        host      = os.getenv("MYSQL_HOST"),
        port      = tonumber(os.getenv("MYSQL_PORT")) or 3306,
        user      = os.getenv("MYSQL_USER"),
        password  = os.getenv("MYSQL_PASSWORD"),
        database  = os.getenv("MYSQL_DATABASE"),
        adapter   = "mysql",
        charset   = "utf8mb4",
        timezone  = os.getenv("TZ") or "Asia/Shanghai"
    },
    redis       = {
        host     = os.getenv("REDIS_HOST"),
        port     = tonumber(os.getenv("REDIS_PORT")),
        -- 保留 database 字段以兼容现有 Key 生成逻辑，实际表示命名空间
        database = os.getenv("REDIS_NAMESPACE") or "api",
        password = os.getenv("REDIS_PASSWORD"),
    },
    cache       = {
        shm_name = os.getenv("CACHE_SHM_NAME") or "cache_shm",
        ipc_shm  = os.getenv("CACHE_IPC_SHM") or "ipc_shm",
        lru_size = tonumber(os.getenv("CACHE_LRU_SIZE")) or 1024 * 1024 * 10,
        ttl      = tonumber(os.getenv("CACHE_TTL")) or 300,
        neg_ttl  = tonumber(os.getenv("CACHE_NEG_TTL")) or 60,
    }
})
