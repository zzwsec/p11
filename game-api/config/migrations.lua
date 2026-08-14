local db = require "lapis.db"
local schema = require "lapis.db.schema"
local types = schema.types

return {
    [100] = function ()
        schema.create_table("leaderboard", {
            {"id",              types.varchar { null = false}},
            {"project_id",      types.varchar { null = false}},
            {"sort_order",      types.varchar { default = "desc"}},
            {"update_type",     types.varchar { default = "best"}},
            {"limit",           types.integer { default = 10}},
            {"created_at",      types.integer},
            {"updated_at",      types.integer},
            -- 主键
            "PRIMARY KEY (project_id, id)"
        })
    end
}