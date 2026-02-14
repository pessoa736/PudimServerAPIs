--- CORS Example
--- Run: lua ./examples/cors_example.lua
--- Test: curl -i -X OPTIONS http://localhost:8082/api/data
--- Test: curl -i http://localhost:8082/api/data

local PudimServer = require("PudimServer")

local server = PudimServer:Create{
  Port = 8082,
  Address = "localhost",
  ServiceName = "CORS Example",
  Middlewares = {}
}


-- Enable CORS with defaults (allows all origins)
server:EnableCors()

server:Routes("/api/data", function(req, res)
  if req.method == "GET" then
    return res:response(200, { msg = "open CORS", origin = "*" })
  end
  return res:response(405, { error = "Method not allowed" })
end)


print("=== CORS Example (open) running at http://localhost:8082 ===")
print("Try: curl -i -X OPTIONS http://localhost:8082/api/data")
print("Try: curl -i http://localhost:8082/api/data")
server:Run()
