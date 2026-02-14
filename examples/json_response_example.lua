--- JSON Response Example
--- Run: lua ./examples/json_response_example.lua
--- Test: curl http://localhost:8081/api/users

local PudimServer = require("PudimServer")

local server = PudimServer:Create{
  Port = 8081,
  Address = "localhost",
  ServiceName = "JSON Example",
  Middlewares = {}
}


-- Tables are auto-encoded to JSON with Content-Type: application/json
server:Routes("/api/users", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      users = {
        { id = 1, name = "Davi" },
        { id = 2, name = "Maria" },
      },
      total = 2
    })
  end

  if req.method == "POST" then
    return res:response(201, { msg = "User created!", data = req.body })
  end

  return res:response(405, { error = "Method not allowed" })
end)


-- You can also pass explicit Content-Type with a table body
server:Routes("/api/status", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      status = "ok",
      timestamp = os.time(),
      service = "JSON Example"
    }, {
      ["Content-Type"] = "application/json",
      ["X-Custom-Header"] = "PudimServer"
    })
  end

  return res:response(405, { error = "Method not allowed" })
end)


print("JSON Example running at http://localhost:8081")
print("Try: curl http://localhost:8081/api/users")
print("Try: curl http://localhost:8081/api/status")
server:Run()
