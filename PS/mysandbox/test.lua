--- Important: this file must be executed in Root Project. "lua ./PS/mysandbox/test.lua"

local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"

package.path = 
  scriptDir .. "../../?.lua;" ..
  scriptDir .. "../../init.lua;" ..
  scriptDir .. "../../?/init.lua;" ..
  package.path

local PS = require("PS.init")

log.activateDebugMode()
log.live()
if not PS then log("not find PudimServer") end


local serverTest = PS:create({Port = 3000})


serverTest:run()

log.save("./PS/mysandbox/", "log.txt")