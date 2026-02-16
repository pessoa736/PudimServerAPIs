
if not _G.log then _G.log = require("loglua") end
if not _G.cjson then _G.cjson = require("cjson.safe") end
local utils = require("PudimServer.utils")

---@diagnostic disable: duplicate-doc-field

--- interfaces


local RequestInter = utils:createInterface({
  method = "string",
  path = "string",
  version = "string",
  headers = "table",
  body = "string",
  query = {"table", "nil"},
  params = {"table", "nil"}
})


local ResponseParamsInter = utils:createInterface({
  status = "number",
  body = {"string", "table"},
  headers = {"table", "nil"}
})



---@class Request
---@field method string Método HTTP (GET, POST, etc)
---@field path string Caminho da requisição
---@field version string Versão do HTTP
---@field headers table<string, string> Headers da requisição
---@field body string Corpo da requisição
---@field query table<string, string|string[]>? Query string parsed
---@field params table<string, string>? Parâmetros de rota dinâmica



---@class HttpModule
---@field ParseRequest fun(self: HttpModule, raw: string): Request
---@field response fun(self: HttpModule, status: number, body: string|table, headers?: table<string, string>): string
---@field __index HttpModule


---------
--- main

---@diagnostic disable: missing-fields
---@type HttpModule
local http = {}
http.__index = http


--- Parses a raw HTTP request string into a structured Request object.
---@param raw string Raw HTTP request data
---@return Request req Parsed request with method, path, version, headers, body
function http:ParseRequest(raw)
    local RP = log.inSection("Response Parse")
    
    utils:verifyTypes(raw,"string",RP.error, true)
    
    local msid = 0 
    local function _msg(msg)
        utils:loadMessageOnChange("httpParse" .. msid, msg, RP.debug)
        msid = msid + 1
    end
    
    local lines = {}

    _msg("separating lines...")
    for line in raw:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    _msg("lines separated")

    local method, path, version = lines[1]:match("(%S+)%s+(%S+)%s+(%S+)")
    _msg(("get the method: %s; path: %s and version: %s."):format(method, path, version))

    local headers = {}
    local body = ""
    local i = 2


    while lines[i] and lines[i] ~= "" do
        local k,v = lines[i]:match("([^:]+):%s*(.+)")
        if k then headers[k:lower()] = v end
        i = i + 1
    end

    -- Corpo vem depois da linha vazia
    i = i + 1
    while lines[i] do
        body = body .. lines[i] .. "\n"
        i = i + 1
    end
    
        -- split path and query string
        local pathOnly = path
        local queryString
        if path and path:find("%?") then
            pathOnly, queryString = path:match("^([^?]+)%?(.*)$")
        end

        local function urlDecode(s)
            if not s then return s end
            s = s:gsub('+', ' ')
            s = s:gsub('%%(%x%x)', function(h) return string.char(tonumber(h,16)) end)
            return s
        end

        local function parseQuery(qs)
            if not qs or qs == "" then return {} end
            local out = {}
            for pair in qs:gmatch("([^&]+)") do
                local k,v = pair:match("([^=]+)=?(.*)")
                if k then
                    k = urlDecode(k)
                    v = urlDecode(v)
                    if out[k] == nil then
                        out[k] = v
                    else
                        if type(out[k]) == 'table' then
                            table.insert(out[k], v)
                        else
                            out[k] = { out[k], v }
                        end
                    end
                end
            end
            return out
        end

        ---@type Request
        local req =  {
                method = method,
                path = pathOnly or path,
                version = version,
                headers = headers,
                body = body,
                query = parseQuery(queryString),
                params = {}
        }

    utils:verifyTypes(req, RequestInter, RP.error, true)

    _msg("request: "..tostring(cjson.encode(req)))
    return req
end

--- Builds an HTTP response string.
--- Tables passed as body are automatically encoded to JSON with Content-Type application/json.
---@param status number HTTP status code (200, 404, 500, etc)
---@param body string|table Response body (tables auto-encode to JSON)
---@param headers? table<string, string> Custom response headers
---@return string response Raw HTTP response string ready to send
function http:response(status, body, headers)
    local AR = log.inSection("API Request")
    
    utils:verifyTypes(
        {status = status, body = body or "", headers = headers},
        ResponseParamsInter,
        AR.error,
        true
    )
    
    local msid = 0 
    local function _msg(msg)
        utils:loadMessageOnChange("httpRequest" .. msid, msg, AR.debug)
        msid = msid + 1
    end

    ---@type table<string, any>
    local headers = headers or {}
    
    if type(body) == "table" then
      if not headers["Content-Type"] then
        headers["Content-Type"] = "application/json"
      end
      body = cjson.encode(body)
    end
    
    body = body or ""
    headers["Content-Length"] = #body

    local statusText = {
        [100] = "Continue",
        [101] = "Switching Protocols",
        [102] = "Processing",
        [200] = "OK",
        [201] = "Created",
        [202] = "Accepted",
        [204] = "No Content",
        [301] = "Moved Permanently",
        [302] = "Found",
        [304] = "Not Modified",
        [400] = "Bad Request",
        [401] = "Unauthorized",
        [403] = "Forbidden",
        [404] = "Not Found",
        [405] = "Method Not Allowed",
        [409] = "Conflict",
        [415] = "Unsupported Media Type",
        [422] = "Unprocessable Entity",
        [429] = "Too Many Requests",
        [500] = "Internal Server Error",
        [501] = "Not Implemented",
        [502] = "Bad Gateway",
        [503] = "Service Unavailable",
        [504] = "Gateway Timeout"
    }

    local buffer = ("HTTP/1.1 %s %s \r\n"):format(status, statusText[status] or "")

    for k, v in pairs(headers) do
        buffer = buffer .. ("%s: %s\r\n"):format(k, v)
    end

    buffer = buffer .. "\r\n" .. body
    
    _msg("Request: "..buffer)
    return buffer
end

return http