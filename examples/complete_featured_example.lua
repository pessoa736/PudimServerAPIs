--- Complete Featured Example
--- Run (HTTP):
---   lua ./examples/complete_featured_example.lua
---
--- Optional HTTPS mode:
---   ENABLE_HTTPS=1 \
---   TLS_KEY=./examples/certs/server.key \
---   TLS_CERT=./examples/certs/server.crt \
---   lua ./examples/complete_featured_example.lua
---
--- Test:
---   curl http://localhost:8087/
---   curl http://localhost:8087/health
---   curl "http://localhost:8087/search?q=pudim&page=1&tag=lua&tag=server"
---   curl http://localhost:8087/users/42
---   curl -H "Authorization: Bearer token123" http://localhost:8087/api/protected
---
--- Hot reload test:
---   1) request /reload
---   2) edit ./examples/hot_reload_message.lua
---   3) request /reload again (no restart)

local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"
package.path =
  scriptDir .. "../?.lua;" ..
  scriptDir .. "../?/init.lua;" ..
  package.path

local PudimServer = require("PudimServer")
local Cache = require("PudimServer.cache")

local enableHttps = os.getenv("ENABLE_HTTPS") == "1"
local address = os.getenv("HOST") or "localhost"
local port = tonumber(os.getenv("PORT")) or (enableHttps and 8443 or 8087)

local createConfig = {
  ServiceName = "Pudim Complete Example",
  Address = address,
  Port = port,

  Concurrency = {
    Enabled = true,
    Sleep = 0.001,
  },

  HotReload = {
    Enabled = true,
    Modules = {"examples.hot_reload_message"}
  }
}

if enableHttps then
  createConfig.Https = {
    Enabled = true,
    Key = os.getenv("TLS_KEY") or "./examples/certs/server.key",
    Certificate = os.getenv("TLS_CERT") or "./examples/certs/server.crt",
    Protocol = "any",
    Verify = "none",
  }
end

---@type Server
local server = PudimServer:Create(createConfig)
---@cast server PudimServer

server:EnableCors{
  AllowOrigins = "*",
  AllowMethods = {"GET", "POST", "OPTIONS"},
  AllowHeaders = {"Content-Type", "Authorization"},
  ExposeHeaders = {"X-Trace-Id"},
  MaxAge = 86400,
}

local cache = Cache.new{ MaxSize = 200, DefaultTTL = 30 }
server:UseHandler(Cache.createPipelineHandler(cache))

server:UseHandler{
  name = "logger",
  Handler = function(req, res, next)
    print(("[%s] %s %s"):format(os.date("%H:%M:%S"), req.method, req.path))
    return next()
  end
}

server:UseHandler{
  name = "auth-protected",
  Handler = function(req, res, next)
    if req.path == "/api/protected" and not req.headers["authorization"] then
      return res:response(401, { error = "Unauthorized" })
    end
    return next()
  end
}

server:UseHandler{
  name = "trace-header",
  Handler = function(req, res, next)
    local response = next()
    if response then
      local traceId = tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
      response = response:gsub("(\r\n\r\n)", "\r\nX-Trace-Id: " .. traceId .. "%1", 1)
    end
    return response
  end
}

server:Routes("/", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      service = "Pudim Complete Example",
      protocol = enableHttps and "https" or "http",
      endpoints = {
        "/",
        "/health",
        "/search?q=...&tag=...",
        "/users/:id",
        "/api/protected",
        "/reload"
      }
    })
  end
  return res:response(405, { error = "Method not allowed" })
end)

server:Routes("/health", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      ok = true,
      now = os.date("%Y-%m-%d %H:%M:%S"),
      cacheTTL = 30
    })
  end
  return res:response(405, { error = "Method not allowed" })
end)

server:Routes("/search", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      query = req.query or {},
      note = "Repeated query keys become arrays"
    })
  end
  return res:response(405, { error = "Method not allowed" })
end)

server:Routes("/users/:id", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      userId = req.params and req.params.id,
      source = "dynamic route"
    })
  end
  return res:response(405, { error = "Method not allowed" })
end)

server:Routes("/api/protected", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      message = "Access granted",
      authorization = req.headers["authorization"]
    })
  end
  return res:response(405, { error = "Method not allowed" })
end)

server:Routes("/reload", function(req, res)
  if req.method == "GET" then
    local messageProvider = require("examples.hot_reload_message")
    return res:response(200, messageProvider.get())
  end
  return res:response(405, { error = "Method not allowed" })
end)

print(("=== Complete Example running at %s://%s:%d ==="):format(enableHttps and "https" or "http", address, port))
print("Try: /, /health, /search, /users/:id, /api/protected, /reload")
server:Run()
