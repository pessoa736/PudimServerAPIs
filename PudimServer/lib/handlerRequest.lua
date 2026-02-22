local http          = require "PudimServer.http"
local debugPrint    = require "PudimServer.lib.debugPrint"
local receiveLine   = require "PudimServer.lib.receiveLine"
local cors          = require "PudimServer.cors"

---@param client any
---@param routes any
---@param corsConfig any
---@param pipeline any
---@param yieldFn fun()?
return function(client, routes, corsConfig, pipeline, yieldFn)
    if not client or type(client.receive) ~= "function" then
        error("handlerRequest: client inválido")
        return nil
    end

    if type(routes) ~= "table" then
        error("handlerRequest: routes deve ser uma tabela")
        
        return http:Response(500, "Internal Server Error", {["Content-Type"] = "text/plain", ["Connection"] = "close"})
    end
  
    local data, err = receiveLine(client, yieldFn)
    if not data then 
        error("receive data error "..tostring(err))
        return nil
    end

    local raw = data .. "\r\n"
    while true do
        local line, lineErr = receiveLine(client, yieldFn)
        if not line then
        if lineErr and lineErr ~= "closed" then
            error("receive header error " .. tostring(lineErr))
        end
            break
        end

        raw = raw .. line .. "\r\n"
        if line == "" then
            break
        end
    end

    local req = http:Request(raw)
    if not req or not req.path or not req.method then
        return http:Response(400, "Bad Request", {["Content-Type"] = "text/plain", ["Connection"] = "close"})
    end

    print(("response: %s %s"):format(req.method, req.path))

    -- CORS preflight
    if corsConfig and req.method == "OPTIONS" then
        return cors.preflightResponse(corsConfig)
    end

    -- Debug: mostrar rotas registradas
    debugPrint("rotas registradas: " .. tostring(next(routes) and "tem rotas" or "vazio"))



    ---@param req Request
    ---@param res httpParser
    local routeHandler = function(req, res)
        -- try exact/static match first
        for _, entry in ipairs(routes) do
            if not entry.dynamic and entry.path == req.path then
                return entry.handler(req, res)
            end
        end

        -- try dynamic routes
        for _, entry in ipairs(routes) do
            if entry.dynamic and entry.pattern then
                local captures = { string.match(req.path, entry.pattern) }
                if captures[1] then
                    -- populate req.params
                    req.params = req.params or {}
                    for i, name in ipairs(entry.paramNames or {}) do
                        req.params[name] = captures[i]
                    end
                    return entry.handler(req, res)
                end
            end
        end

        return http:Response(404, "Not Found", {["Content-Type"] = "text/plain", ["Connection"] = "close"})
    end

    local response = pipeline:execute(req, http, routeHandler)

    -- Injeta headers CORS na resposta
    if corsConfig and response then
        local corsHeaders = cors.buildHeaders(corsConfig, req.headers["origin"])
        for k, v in pairs(corsHeaders) do
            response = response:gsub("(\r\n\r\n)", "\r\n" .. k .. ": " .. v .. "%1", 1)
        end
    end

    return response
end