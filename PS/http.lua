
if not _G.log then _G.log = require("loglua") end
if not _G.cjson then _G.cjson = require("cjson.safe") end

local http = {}
http.__index = http


function http:Parse(raw)
    local RP = log.inSection("Response Parse")
    local lines = {}

    RP.debug("separating lines...")
    for line in raw:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    RP.debug("lines separated")

    local method, path, version = lines[1]:match("(%S+)%s+(%S+)%s+(%S+)")
    RP.debug(("get the method: %s; path: %s and version: %s. on the line 1."):format(method, path, version))

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
    RP("response: "..tostring(cjson.encode(resp)))
    return resp
end

function http:request(status, body, headers)
    local AR = log.inSection("API Request")
    local headers = headers or {}
    
    if type(body)=="table" then 
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
        buffer = buffer .. ("%s: %s \r\n"):format(k, v)
    end

    buffer = buffer .. body
    
    AR.debug("Request: "..buffer)
    return buffer
end

return http