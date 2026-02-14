--- CORS Restricted Example
--- Run: lua ./examples/cors_restricted_example.lua
--- Test: curl -i -X OPTIONS http://localhost:8083/api/secret

local PudimServer = require("PudimServer")

local server = PudimServer:Create{
  Port = 8083,
  Address = "localhost",
  ServiceName = "CORS Restricted Example",
  Middlewares = {}
}


-- Enable CORS with restricted config
server:EnableCors{
  AllowOrigins = { "https://myapp.com", "https://admin.myapp.com" },
  AllowMethods = { "GET", "POST" },
  AllowHeaders = "Content-Type, Authorization, X-Request-Id",
  AllowCredentials = true,
  ExposeHeaders = { "X-Total-Count", "X-Page" },
  MaxAge = 3600
}

server:Routes("/api/secret", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      msg = "restricted CORS",
      allowedOrigins = { "https://myapp.com", "https://admin.myapp.com" }
    })
  end
  return res:response(405, { error = "Method not allowed" })
end)


print("=== CORS Restricted Example running at http://localhost:8083 ===")
print("Try: curl -i -X OPTIONS http://localhost:8083/api/secret")
print("Try: curl -i http://localhost:8083/api/secret")
server:Run()
