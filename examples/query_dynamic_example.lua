local PudimServer = require("PudimServer")

-- Example demonstrating query parsing and dynamic route params.
local server = PudimServer:Create{ Port = 3001 }

server:UseHandler{
  name = "logger",
  Handler = function(req, res, next)
    log(('[%s] %s %s'):format(os.date("%H:%M:%S"), req.method, req.path))
    return next()
  end
}

-- Query example: /greet?name=Davi
server:Routes("/greet", function(req, res)
  local name = (req.query and req.query.name) or "guest"
  return res:response(200, "Hello " .. name, { ["Content-Type"] = "text/plain" })
end)

-- Dynamic route example: /users/:id
server:Routes("/users/:id", function(req, res)
  local id = (req.params and req.params.id) or "unknown"
  return res:response(200, { userId = id })
end)

print("Example server listening at http://localhost:3001")
server:Run()
