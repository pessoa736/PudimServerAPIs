
if not _G.log then _G.log = require("loglua") end
if not _G.cjson then _G.cjson = require("cjson.safe") end
local utils = require("PS.utils")


--- interfaces

---@class Request
---@field method string Método HTTP (GET, POST, etc)
---@field path string Caminho da requisição
---@field version string Versão do HTTP
---@field headers table<string, string> Headers da requisição
---@field body string Corpo da requisição

local RequestInter = utils:createInterface({
  method = "string",
  path = "string",
  version = "string",
  headers = "table",
  body = "string"
})

---@class ResponseParams
---@field status number Código de status HTTP
---@field body string|table Corpo da resposta
---@field headers table<string, string>? Headers da resposta

local ResponseParamsInter = utils:createInterface({
  status = "number",
  body = {"string", "table"},
  headers = {"table", "nil"}
})


---------
--- main

local http = {}
http.__index = http


function http:Parse(raw)
    local RP = log.inSection("Response Parse")
    
    utils:verifyTypes(
        {raw = raw},
        utils:createInterface({raw = "string"}),
        RP.error,
        true
    )
    
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
    _msg(("get the method: %s; path: %s and version: %s. on the line 1."):format(method, path, version))

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
    
    
    local resp =  {
        method = method,
        path = path,
        version = version,
        headers = headers,
        body = body
    }
    _msg("response: "..tostring(cjson.encode(resp)))
    return resp
end

function http:request(status, body, headers)
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

    local headers = headers or {}
    
    if type(body)=="table" and not headers then 
      headers["Content-Type"] = "application/json"
      body = cjson.encode(body)
    end
    
    local body = body or ""
    headers["Content-Length"] = #body

    local statusText = {
        [200] = "OK",
        [404] = "Not Found",
        [500] = "Internal Server Error"
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