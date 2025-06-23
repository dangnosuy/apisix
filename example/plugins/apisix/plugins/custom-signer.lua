local core = require("apisix.core")
local jwt = require("resty.jwt")
local ngx = ngx

local plugin_name = "jwt-gateway-signer"

local schema = {
    type = "object",
    properties = {
        key = { type = "string" },
        alg = { type = "string", enum = { "HS256", "HS384", "HS512" }, default = "HS256" },
        header_name = { type = "string", default = "X-Gateway-JWT" },
        payload = {
            type = "object",
            default = {}
        }
    },
    required = { "key" }
}

local _M = {
    version = 0.1,
    priority = 5050, -- chạy sau các plugins rewrite, route...
    name = plugin_name,
    schema = schema,
}

function _M.check_schema(conf)
    return core.schema.check(schema, conf)
end

function _M.access(conf, ctx)
    local payload = conf.payload or {}
    payload.iat = ngx.time()
    payload.exp = ngx.time() + 300 -- hết hạn sau 5 phút

    local token = jwt:sign(
        conf.key,
        {
            header = { typ = "JWT", alg = conf.alg },
            payload = payload
        }
    )

    ngx.req.set_header(conf.header_name, token)

    return
end

return _M
