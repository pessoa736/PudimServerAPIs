
if not _G.log then _G.log = require("loglua") end
if not _G.cjson then _G.cjson = require("cjson.safe") end
local utils         = require("PudimServer.utils")
local debugPrint    = require "PudimServer.lib.debugPrint"
local parseQuery    = require "PudimServer.lib.parseQuery"


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



---------
--- main
---@type httpParser
local httpParser = {}
httpParser.__index = httpParser


function httpParser:Request(raw)
    utils:verifyTypes(raw,"string", print, true)
    
    local lines = {}

    print("separating lines...")
    for line in raw:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    print("lines separated")

    local method, path, version = lines[1]:match("(%S+)%s+(%S+)%s+(%S+)")
    print(("get the method: %s; path: %s and version: %s."):format(method, path, version))

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

    utils:verifyTypes(req, RequestInter, print, true)

    print("request: "..tostring(cjson.encode(req)))
    return req
end


function httpParser:Response(status, body, headers)
    
    utils:verifyTypes(
        {status = status, body = body or "", headers = headers},
        ResponseParamsInter,
        print,
        true
    )
    
   
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
    
    debugPrint("Request: "..buffer)
    return buffer
end

return httpParser