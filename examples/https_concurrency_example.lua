--- HTTPS + Concurrency Example
--- Run:
---   # 1) Generate self-signed certs (development only)
---   mkdir -p ./examples/certs
---   openssl req -x509 -newkey rsa:2048 -nodes \
---     -keyout ./examples/certs/server.key \
---     -out ./examples/certs/server.crt \
---     -days 365 \
---     -subj "/CN=localhost"
---
---   # 2) Start server
---   lua ./examples/https_concurrency_example.lua
---
--- Test:
---   curl -k https://localhost:8443/
---   curl -k https://localhost:8443/work

local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"
package.path =
  scriptDir .. "../?.lua;" ..
  scriptDir .. "../?/init.lua;" ..
  package.path

local PudimServer = require("PudimServer")

---@type Server
local server = PudimServer:Create{
  ServiceName = "HTTPS + Concurrency Example",
  Address = "localhost",
  Port = 8443,

  Https = {
    Enabled = true,
    Key = "./examples/certs/server.key",
    Certificate = "./examples/certs/server.crt",
    Protocol = "any",
    Verify = "none",
  },

  Concurrency = {
    Enabled = true,
    Sleep = 0.001,
  }
}

server:Routes("/", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      ok = true,
      protocol = "https",
      concurrency = "cooperative coroutines",
      now = os.time()
    })
  end
  return res:response(405, { error = "Method not allowed" })
end)

server:Routes("/work", function(req, res)
  if req.method == "GET" then
    -- Simulate some CPU work
    local sum = 0
    for i = 1, 100000 do
      sum = sum + i
    end

    return res:response(200, {
      message = "heavy work done",
      result = sum
    })
  end
  return res:response(405, { error = "Method not allowed" })
end)

print("=== HTTPS + Concurrency Example running at https://localhost:8443 ===")
print("Try: curl -k https://localhost:8443/")
print("Try: curl -k https://localhost:8443/work")
server:Run()
