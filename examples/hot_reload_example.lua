--- Hot Reload Example (without file watcher)
--- Run:
---   lua ./examples/hot_reload_example.lua
---
--- Test:
---   curl http://localhost:8086/reload
---
--- Then edit: ./examples/hot_reload_message.lua
--- and request /reload again to see changes without restarting.

local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"
package.path =
  scriptDir .. "../?.lua;" ..
  scriptDir .. "../?/init.lua;" ..
  package.path

local PudimServer = require("PudimServer")

---@type Server
local server = PudimServer:Create{
  ServiceName = "Hot Reload Example",
  Address = "localhost",
  Port = 8086,
  HotReload = {
    Enabled = true,
    Modules = {
      "examples.hot_reload_message"
    }
  }
}

---@cast server PudimServer

server:Routes("/reload", function(req, res)
  if req.method == "GET" then
    local messageProvider = require("examples.hot_reload_message")
    return res:response(200, messageProvider.get())
  end
  return res:response(405, { error = "Method not allowed" })
end)

print("=== Hot Reload Example running at http://localhost:8086/reload ===")
print("Edit ./examples/hot_reload_message.lua and refresh /reload")
server:Run()
