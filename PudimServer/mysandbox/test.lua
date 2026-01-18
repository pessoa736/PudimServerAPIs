--- Important: this file must be executed in Root Project. "lua ./PS/mysandbox/test.lua"

local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"

package.path = 
  scriptDir .. "../../?.lua;" ..
  scriptDir .. "../../init.lua;" ..
  scriptDir .. "../../?/init.lua;" ..
  package.path

local PS = require("PudimServer")
local utils = require("PudimServer.utils")

log.activateDebugMode()
log.live()
if not PS then log("not find PudimServer") end


local serverTest = PS:Create{
  Port = 8080,
  Address = "localhost",
  ServiceName = "PudimServerTest",
  Middlewares = {}
}



serverTest:Routes("/", 
  function (req, res)
    if req.method == "GET" then
      local HtmlString = utils:getContentFile(scriptDir.."index.html")
      return res:response(200, HtmlString, {["Content-Type"] = "text/html"})
    end

  end
)


serverTest:Routes("/main.css", 
  function (req, res)
    if req.method == "GET" then
      local cssString = utils:getContentFile(scriptDir.."/main.css")
      return res:response(200, cssString, {["Content-Type"] = "text/css"})
    end
  end
)

serverTest:Routes("/otherPage", 
  function (req, res)
    if req.method == "GET" then
      local otherpage = utils:getContentFile(scriptDir .. "otherPage.html")
      return res:response(200, otherpage, {["Content-Type"] = "text/html"})
    end
  end
)


serverTest:Run()

log.save("./PS/mysandbox/", "log.txt")