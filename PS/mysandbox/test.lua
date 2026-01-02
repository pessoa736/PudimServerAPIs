--- Important: this file must be executed in Root Project. "lua ./PS/mysandbox/test.lua"

local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"

package.path = 
  scriptDir .. "../../?.lua;" ..
  scriptDir .. "../../init.lua;" ..
  scriptDir .. "../../?/init.lua;" ..
  package.path

local PS = require("PS")
local http = require("PS.http")

log.activateDebugMode()
log.live()
if not PS then log("not find PudimServer") end


local serverTest = PS:create({})

serverTest:Routes("/", 
  function (req, res)
    if req.method == "GET" then
      return res:request(
        200, [[
        <html>
          <body>
            <h1>PudimServer is Running</h1>
          </body>
        </html>
      ]], 
      {["Content-Type"] = "text/html"}
      )
    end
  end
)


serverTest:run()

log.save("./PS/mysandbox/", "log.txt")