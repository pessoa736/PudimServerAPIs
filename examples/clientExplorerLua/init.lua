local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"

local ps = require "PudimServer";


local EL = ps:Create{
    Port = 8090,
    Address = "localhost",
    ServiceName = "explorerLua",
}

EL:RoutesAFile(
    "/lua.wasm", 
    scriptDir .. "lua.wasm", 
    {["Content-Type"] = "application/wasm"}
)
EL:RoutesAFile(
    "/lua.js",
    scriptDir .. "lua.js",
    {["Content-Type"] = "text/javascript"}
)
EL:RoutesAFile(
    "/",
    scriptDir .. "index.html",
    {["Content-Type"] = "text/html"}
)

EL:Run()