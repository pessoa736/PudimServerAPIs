---@diagnostic disable: duplicate-doc-field

--- PudimServer Help System
--- Provides interactive documentation for humans and AI models.
--- Usage: require("PudimServer").help() or require("PudimServer").help("topic")

if not _G.log then _G.log = require("loglua") end

local help = {}

--- ANSI colors for terminal output
local colors = {
  reset = "\27[0m",
  bold = "\27[1m",
  dim = "\27[2m",
  green = "\27[32m",
  cyan = "\27[36m",
  yellow = "\27[33m",
  magenta = "\27[35m",
  white = "\27[37m",
}

local function c(color, text)
  return colors[color] .. text .. colors.reset
end

local function bold(text)
  return colors.bold .. text .. colors.reset
end


---@type string
local VERSION = "0.2.0"


--- Topic documentation registry
---@type table<string, fun()>
local topics = {}


local function printHeader()
  print(c("cyan", "╭──────────────────────────────────────────────────╮"))
  print(c("cyan", "│") .. c("yellow", "  🍮 PudimServer v" .. VERSION) .. string.rep(" ", 31 - #VERSION) .. c("cyan", "│"))
  print(c("cyan", "│") .. c("white",  "  Lua HTTP Server Library") ..                "                        " .. c("cyan", "│"))
  print(c("cyan", "╰──────────────────────────────────────────────────╯"))
end


local function printQuickstart()
  print()
  print(bold("  Quick Start:"))
  print()
  print(c("dim", "    local PudimServer = require(\"PudimServer\")"))
  print()
  print(c("dim", "    local server = PudimServer:Create{"))
  print(c("dim", "      ServiceName = \"My API\","))
  print(c("dim", "      Port = 8080"))
  print(c("dim", "    }"))
  print()
  print(c("dim", "    server:Routes(\"/hello\", function(req, res)"))
  print(c("dim", "      return res:response(200, \"Hello World!\")"))
  print(c("dim", "    end)"))
  print()
  print(c("dim", "    server:Run()"))
  print()
end


local function printTopicList()
  print(bold("  Available Topics:"))
  print()
  print(c("green", "    create") ..     "       Create a server instance")
  print(c("green", "    routes") ..     "       Register HTTP routes")
  print(c("green", "    run") ..        "          Start the server")
  print(c("green", "    response") ..   "      Build HTTP responses")
  print(c("green", "    cors") ..       "         Enable CORS support")
  print(c("green", "    pipeline") ..   "      Request/response middleware pipeline")
  print(c("green", "    cache") ..      "        In-memory response caching")
  print(c("green", "    middlewares") .. "   Socket-level middlewares")
  print(c("green", "    types") ..      "        Runtime type-checking system")
  print(c("green", "    modules") ..    "      Module list and architecture")
  print()
  print("  Usage: " .. c("cyan", "require(\"PudimServer\").help(\"topic\")"))
  print()
end


--- Topic: create
topics["create"] = function()
  printHeader()
  print()
  print(bold("  PudimServer:Create(config)"))
  print()
  print("  Creates and returns a new server instance.")
  print()
  print(bold("  Parameters:"))
  print(c("green", "    config") .. c("dim", " (ConfigServer, optional)"))
  print("      " .. c("yellow", "ServiceName") .. c("dim", " string?  ") .. "Name of the service (default: \"Pudim Server\")")
  print("      " .. c("yellow", "Address") ..     c("dim", "     string?  ") .. "Bind address (default: \"localhost\")")
  print("      " .. c("yellow", "Port") ..        c("dim", "        number?  ") .. "Port number (default: 8080)")
  print("      " .. c("yellow", "Middlewares") .. c("dim", " table?   ") .. "Initial socket middlewares")
  print()
  print(bold("  Returns:"))
  print("    " .. c("cyan", "Server") .. " — the server instance with all methods")
  print()
  print(bold("  Example:"))
  print(c("dim", "    local server = PudimServer:Create{"))
  print(c("dim", "      ServiceName = \"My API\","))
  print(c("dim", "      Address = \"0.0.0.0\","))
  print(c("dim", "      Port = 3000"))
  print(c("dim", "    }"))
  print()
  print(bold("  Notes:"))
  print("    • Address can be \"localhost\", \"127.0.0.1\", or \"0.0.0.0\"")
  print("    • Throws error if port is already in use")
  print("    • A Pipeline is auto-created for each server instance")
  print()
end


--- Topic: routes
topics["routes"] = function()
  printHeader()
  print()
  print(bold("  Server:Routes(path, handler)"))
  print()
  print("  Registers an HTTP route handler for a given path.")
  print()
  print(bold("  Parameters:"))
  print("    " .. c("green", "path") ..    c("dim", "    string    ") .. "URL path (e.g. \"/api/users\")")
  print("    " .. c("green", "handler") .. c("dim", " function  ") .. "Handler function(req, res) → string")
  print()
  print(bold("  Handler Signature:"))
  print(c("dim", "    ---@param req Request   {method, path, version, headers, body}"))
  print(c("dim", "    ---@param res HttpModuler  (use res:response())"))
  print(c("dim", "    ---@return string  HTTP response string"))
  print()
  print(bold("  Example:"))
  print(c("dim", "    server:Routes(\"/api/users\", function(req, res)"))
  print(c("dim", "      if req.method == \"GET\" then"))
  print(c("dim", "        return res:response(200, {users = {\"Alice\", \"Bob\"}})"))
  print(c("dim", "      end"))
  print(c("dim", "      return res:response(405, \"Method Not Allowed\")"))
  print(c("dim", "    end)"))
  print()
  print(bold("  Request Object Fields:"))
  print("    " .. c("yellow", "method") ..  c("dim", "   string  ") .. "HTTP method (GET, POST, PUT, DELETE, etc)")
  print("    " .. c("yellow", "path") ..    c("dim", "     string  ") .. "Request path")
  print("    " .. c("yellow", "version") .. c("dim", "  string  ") .. "HTTP version (e.g. HTTP/1.1)")
  print("    " .. c("yellow", "headers") .. c("dim", "  table   ") .. "Request headers (lowercase keys)")
  print("    " .. c("yellow", "body") ..    c("dim", "     string  ") .. "Request body")
  print()
end


--- Topic: run
topics["run"] = function()
  printHeader()
  print()
  print(bold("  Server:Run()"))
  print()
  print("  Starts the server and enters an infinite accept loop.")
  print("  Blocks the current thread — place all setup before calling Run().")
  print()
  print(bold("  Request Flow:"))
  print("    1. Accept TCP connection")
  print("    2. Apply socket middlewares (SetMiddlewares)")
  print("    3. Parse HTTP request")
  print("    4. Handle CORS preflight (if enabled)")
  print("    5. Execute pipeline handlers (UseHandler)")
  print("    6. Match route and call handler")
  print("    7. Inject CORS headers (if enabled)")
  print("    8. Send response and close connection")
  print()
  print(bold("  Example:"))
  print(c("dim", "    -- Setup first"))
  print(c("dim", "    server:Routes(\"/\", function(req, res)"))
  print(c("dim", "      return res:response(200, \"OK\")"))
  print(c("dim", "    end)"))
  print(c("dim", ""))
  print(c("dim", "    -- Then run (blocks)"))
  print(c("dim", "    server:Run()"))
  print()
end


--- Topic: response
topics["response"] = function()
  printHeader()
  print()
  print(bold("  res:response(status, body, headers)"))
  print()
  print("  Builds an HTTP response string. Called inside route handlers.")
  print()
  print(bold("  Parameters:"))
  print("    " .. c("green", "status") ..  c("dim", "  number  ") .. "HTTP status code (200, 404, 500, etc)")
  print("    " .. c("green", "body") ..    c("dim", "    string|table  ") .. "Response body (tables auto-encode to JSON)")
  print("    " .. c("green", "headers") .. c("dim", " table?   ") .. "Custom response headers")
  print()
  print(bold("  Returns:"))
  print("    " .. c("cyan", "string") .. " — raw HTTP response ready to send")
  print()
  print(bold("  Auto-JSON Encoding:"))
  print("    When body is a Lua table, it is automatically encoded to JSON")
  print("    and Content-Type is set to \"application/json\".")
  print()
  print(bold("  Examples:"))
  print(c("dim", "    -- Plain text"))
  print(c("dim", "    return res:response(200, \"Hello!\")"))
  print()
  print(c("dim", "    -- JSON (auto-encoded)"))
  print(c("dim", "    return res:response(200, {name = \"Pudim\", version = 2})"))
  print()
  print(c("dim", "    -- Custom headers"))
  print(c("dim", "    return res:response(200, \"data\", {"))
  print(c("dim", "      [\"Content-Type\"] = \"text/html\","))
  print(c("dim", "      [\"X-Custom\"] = \"value\""))
  print(c("dim", "    })"))
  print()
end


--- Topic: cors
topics["cors"] = function()
  printHeader()
  print()
  print(bold("  Server:EnableCors(config)"))
  print()
  print("  Enables CORS (Cross-Origin Resource Sharing) support.")
  print("  Automatically handles OPTIONS preflight and injects CORS headers.")
  print()
  print(bold("  Parameters:"))
  print(c("green", "    config") .. c("dim", " (CorsConfig, optional)"))
  print("      " .. c("yellow", "AllowOrigins") ..     c("dim", "     string|table  ") .. "Allowed origins (default: \"*\")")
  print("      " .. c("yellow", "AllowMethods") ..     c("dim", "     string|table  ") .. "Allowed methods (default: GET,POST,PUT,DELETE,PATCH,OPTIONS)")
  print("      " .. c("yellow", "AllowHeaders") ..     c("dim", "     string|table  ") .. "Allowed headers (default: Content-Type, Authorization)")
  print("      " .. c("yellow", "ExposeHeaders") ..    c("dim", "    string|table  ") .. "Headers exposed to browser")
  print("      " .. c("yellow", "AllowCredentials") .. c("dim", " boolean       ") .. "Allow credentials (default: false)")
  print("      " .. c("yellow", "MaxAge") ..           c("dim", "           number        ") .. "Preflight cache in seconds (default: 86400)")
  print()
  print(bold("  Examples:"))
  print(c("dim", "    -- Allow all origins"))
  print(c("dim", "    server:EnableCors()"))
  print()
  print(c("dim", "    -- Restricted origins"))
  print(c("dim", "    server:EnableCors{"))
  print(c("dim", "      AllowOrigins = {\"https://mysite.com\", \"https://api.mysite.com\"},"))
  print(c("dim", "      AllowCredentials = true"))
  print(c("dim", "    }"))
  print()
  print(bold("  Submodule Functions:"))
  print("    " .. c("cyan", "cors.createConfig(config)") .. " — resolve config with defaults")
  print("    " .. c("cyan", "cors.buildHeaders(config, origin)") .. " — build CORS response headers")
  print("    " .. c("cyan", "cors.preflightResponse(config)") .. " — return 204 preflight response")
  print()
end


--- Topic: pipeline
topics["pipeline"] = function()
  printHeader()
  print()
  print(bold("  Request/Response Pipeline"))
  print()
  print("  Middleware chain at the HTTP level. Handlers can inspect/modify")
  print("  requests, short-circuit responses, or wrap the final handler.")
  print()
  print(bold("  Server Methods:"))
  print("    " .. c("cyan", "Server:UseHandler(entry)") ..     " — add handler to pipeline")
  print("    " .. c("cyan", "Server:RemoveHandler(name)") ..   " — remove handler by name")
  print()
  print(bold("  Handler Signature:"))
  print(c("dim", "    ---@param req Request"))
  print(c("dim", "    ---@param res HttpModuler"))
  print(c("dim", "    ---@param next fun(): string?  -- call to continue pipeline"))
  print(c("dim", "    ---@return string?  -- HTTP response or nil"))
  print()
  print(bold("  PipelineEntry:"))
  print("    " .. c("yellow", "name") ..    c("dim", "    string    ") .. "Unique name for the handler")
  print("    " .. c("yellow", "Handler") .. c("dim", " function  ") .. "The handler function(req, res, next)")
  print()
  print(bold("  Example:"))
  print(c("dim", "    -- Auth middleware"))
  print(c("dim", "    server:UseHandler{"))
  print(c("dim", "      name = \"auth\","))
  print(c("dim", "      Handler = function(req, res, next)"))
  print(c("dim", "        if not req.headers[\"authorization\"] then"))
  print(c("dim", "          return res:response(401, \"Unauthorized\")"))
  print(c("dim", "        end"))
  print(c("dim", "        return next()  -- continue to next handler"))
  print(c("dim", "      end"))
  print(c("dim", "    }"))
  print()
  print(bold("  Pipeline Class (direct use):"))
  print("    " .. c("cyan", "Pipeline.new()") .. " — create new pipeline")
  print("    " .. c("cyan", "Pipeline:use(entry)") .. " — add handler")
  print("    " .. c("cyan", "Pipeline:remove(name)") .. " — remove handler")
  print("    " .. c("cyan", "Pipeline:execute(req, res, finalHandler)") .. " — execute chain")
  print()
end


--- Topic: cache
topics["cache"] = function()
  printHeader()
  print()
  print(bold("  In-Memory Response Cache"))
  print()
  print("  Caches HTTP responses with TTL and automatic eviction.")
  print("  Integrates with Pipeline via createPipelineHandler.")
  print()
  print(bold("  Cache.new(config):"))
  print(c("green", "    config") .. c("dim", " (CacheConfig, optional)"))
  print("      " .. c("yellow", "MaxSize") ..    c("dim", "    number  ") .. "Max cached entries (default: 100)")
  print("      " .. c("yellow", "DefaultTTL") .. c("dim", " number  ") .. "Default TTL in seconds (default: 60)")
  print()
  print(bold("  Cache Methods:"))
  print("    " .. c("cyan", "cache:get(key)") .. " — get cached response (nil if expired/missing)")
  print("    " .. c("cyan", "cache:set(key, response, ttl?)") .. " — cache a response")
  print("    " .. c("cyan", "cache:invalidate(key)") .. " — remove single entry")
  print("    " .. c("cyan", "cache:clear()") .. " — remove all entries")
  print()
  print(bold("  Pipeline Integration:"))
  print(c("dim", "    local Cache = require(\"PudimServer.cache\")"))
  print(c("dim", "    local cache = Cache.new{ MaxSize = 50, DefaultTTL = 30 }"))
  print(c("dim", ""))
  print(c("dim", "    server:UseHandler(Cache.createPipelineHandler(cache))"))
  print()
  print(bold("  Notes:"))
  print("    • Only GET requests are cached by the pipeline handler")
  print("    • Cache key format: \"method:path\" (e.g. \"GET:/api/data\")")
  print("    • Oldest entry is evicted when MaxSize is reached")
  print()
end


--- Topic: middlewares
topics["middlewares"] = function()
  printHeader()
  print()
  print(bold("  Socket-Level Middlewares"))
  print()
  print("  Middlewares operate on the raw TCP socket connection,")
  print("  before HTTP parsing. Used for SSL, connection transforms, etc.")
  print()
  print(bold("  Server Methods:"))
  print("    " .. c("cyan", "Server:SetMiddlewares(middleware)") .. " — add middleware")
  print("    " .. c("cyan", "Server:RemoveMiddlewares(name)") .. " — remove by name")
  print()
  print(bold("  Middleware Structure:"))
  print("    " .. c("yellow", "name") ..    c("dim", "    string|number  ") .. "Middleware identifier")
  print("    " .. c("yellow", "Handler") .. c("dim", " function       ") .. "function(client) → client")
  print()
  print(bold("  Example (SSL):"))
  print(c("dim", "    local ssl = require(\"ssl\")"))
  print(c("dim", "    server:SetMiddlewares{"))
  print(c("dim", "      name = \"ssl\","))
  print(c("dim", "      Handler = function(client)"))
  print(c("dim", "        return ssl.wrap(client, {"))
  print(c("dim", "          mode = \"server\","))
  print(c("dim", "          protocol = \"any\","))
  print(c("dim", "          key = \"server.key\","))
  print(c("dim", "          certificate = \"server.crt\""))
  print(c("dim", "        })"))
  print(c("dim", "      end"))
  print(c("dim", "    }"))
  print()
  print(bold("  Note:"))
  print("    Middlewares vs Pipeline handlers:")
  print("    • " .. c("yellow", "Middlewares") .. " → socket level (raw TCP, before HTTP parsing)")
  print("    • " .. c("yellow", "Pipeline") .. "    → HTTP level (after parsing, with req/res)")
  print()
end


--- Topic: types
topics["types"] = function()
  printHeader()
  print()
  print(bold("  Runtime Type-Checking System"))
  print()
  print("  PudimServer uses a custom interface/contract system for")
  print("  runtime validation of function parameters and return values.")
  print()
  print(bold("  Creating an Interface:"))
  print(c("dim", "    local utils = require(\"PudimServer.utils\")"))
  print(c("dim", ""))
  print(c("dim", "    local UserInter = utils:createInterface{"))
  print(c("dim", "      name = \"string\","))
  print(c("dim", "      age = \"number\","))
  print(c("dim", "      email = {\"string\", \"nil\"},  -- optional"))
  print(c("dim", "    }"))
  print()
  print(bold("  Validating:"))
  print(c("dim", "    utils:verifyTypes("))
  print(c("dim", "      {name = \"Davi\", age = 25},"))
  print(c("dim", "      UserInter,"))
  print(c("dim", "      log.error,  -- print function on error"))
  print(c("dim", "      true        -- exit on failure"))
  print(c("dim", "    )"))
  print()
  print(bold("  Interface Inheritance:"))
  print(c("dim", "    local AdminInter = utils:createInterface({"))
  print(c("dim", "      role = \"string\""))
  print(c("dim", "    }, UserInter)  -- extends UserInter"))
  print()
  print(bold("  Supported Types:"))
  print("    \"string\", \"number\", \"boolean\", \"table\", \"function\", \"nil\",")
  print("    \"userdata\", or another Interface for nested validation")
  print()
end


--- Topic: modules
topics["modules"] = function()
  printHeader()
  print()
  print(bold("  Module Architecture"))
  print()
  print("  " .. c("cyan", "PudimServer") .. " (init.lua)")
  print("    Main server: Create, Routes, Run, EnableCors, UseHandler")
  print()
  print("  " .. c("cyan", "PudimServer.http") .. " (http.lua)")
  print("    HTTP parsing (ParseRequest) and response building (response)")
  print()
  print("  " .. c("cyan", "PudimServer.cors") .. " (cors.lua)")
  print("    CORS config, header building, preflight responses")
  print()
  print("  " .. c("cyan", "PudimServer.pipeline") .. " (pipeline.lua)")
  print("    Request/response middleware chain with next() pattern")
  print()
  print("  " .. c("cyan", "PudimServer.cache") .. " (cache.lua)")
  print("    In-memory response cache with TTL and eviction")
  print()
  print("  " .. c("cyan", "PudimServer.utils") .. " (utils.lua)")
  print("    File I/O, runtime type system, deduplicated logging")
  print()
  print("  " .. c("cyan", "PudimServer.ServerChecks") .. " (ServerChecks.lua)")
  print("    Network utilities (port-open check via TCP)")
  print()
  print("  " .. c("cyan", "PudimServer.help") .. " (help.lua)")
  print("    This help system")
  print()
  print(bold("  Globals:"))
  print("    " .. c("yellow", "_G.log") .. "   — loglua logger (auto-initialized)")
  print("    " .. c("yellow", "_G.cjson") .. " — cjson.safe (auto-initialized)")
  print()
end


---@param topic? string Topic name to show help for
function help.show(topic)
  if topic then
    local t = topics[topic:lower()]
    if t then
      t()
    else
      print(c("yellow", "  Unknown topic: ") .. c("cyan", topic))
      print()
      printTopicList()
    end
    return
  end

  printHeader()
  printQuickstart()
  printTopicList()
end


--- First-run welcome message
function help.welcome()
  local flagFile = ".pudimserver_initialized"

  local f = io.open(flagFile, "r")
  if f then
    f:close()
    return false
  end

  printHeader()
  print()
  print(c("green", "  Welcome to PudimServer! 🎉"))
  print()
  print("  This is your first time using PudimServer in this project.")
  print()
  printQuickstart()
  print("  Run " .. c("cyan", "require(\"PudimServer\").help()") .. " anytime for documentation.")
  print("  Run " .. c("cyan", "require(\"PudimServer\").help(\"topic\")") .. " for specific topics.")
  print()
  printTopicList()

  local wf = io.open(flagFile, "w")
  if wf then
    wf:write("initialized\n")
    wf:close()
  end

  return true
end


---@return string version
function help.version()
  return VERSION
end


---@return string[] topics Available help topics
function help.topics()
  local list = {}
  for k, _ in pairs(topics) do
    table.insert(list, k)
  end
  table.sort(list)
  return list
end


return help
