--- Pipeline Example
--- Run: lua ./examples/pipeline_example.lua
--- Test: curl http://localhost:8084/api/public
--- Test: curl http://localhost:8084/api/protected
--- Test: curl -H "Authorization: Bearer token123" http://localhost:8084/api/protected

local PudimServer = require("PudimServer")

local server = PudimServer:Create{
  Port = 8084,
  Address = "localhost",
  ServiceName = "Pipeline Example",
  Middlewares = {}
}


-- Pipeline handler 1: Request logger
server:UseHandler{
  name = "logger",
  Handler = function(req, res, next)
    print(("[%s] %s %s"):format(os.date("%H:%M:%S"), req.method, req.path))
    local response = next()
    print(("[%s] %s %s -> done"):format(os.date("%H:%M:%S"), req.method, req.path))
    return response
  end
}


-- Pipeline handler 2: Auth check (short-circuits if no token on /api/protected)
server:UseHandler{
  name = "auth",
  Handler = function(req, res, next)
    if req.path == "/api/protected" and not req.headers["authorization"] then
      return res:response(401, { error = "Unauthorized: missing Authorization header" })
    end
    return next()
  end
}


-- Pipeline handler 3: Add custom header to all responses
server:UseHandler{
  name = "custom-header",
  Handler = function(req, res, next)
    local response = next()
    if response then
      -- Inject a custom header before the body
      response = response:gsub(
        "(\r\n\r\n)",
        "\r\nX-Powered-By: PudimServer%1",
        1
      )
    end
    return response
  end
}


-- Routes
server:Routes("/api/public", function(req, res)
  if req.method == "GET" then
    return res:response(200, { msg = "This is public!" })
  end
  return res:response(405, { error = "Method not allowed" })
end)

server:Routes("/api/protected", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      msg = "Welcome! You are authenticated.",
      token = req.headers["authorization"]
    })
  end
  return res:response(405, { error = "Method not allowed" })
end)


print("=== Pipeline Example running at http://localhost:8084 ===")
print("Try: curl http://localhost:8084/api/public")
print("Try: curl http://localhost:8084/api/protected            (401 - blocked by auth)")
print('Try: curl -H "Authorization: Bearer token123" http://localhost:8084/api/protected')
server:Run()
