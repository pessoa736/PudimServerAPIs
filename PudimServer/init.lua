
if not _G.log then _G.log = require("loglua") end
local debugPrint          = require("PudimServer.lib.debugPrint")


local ApplyHotReload          = require "PudimServer.lib.ApplyHotReload"
local ResolveHotReloadConfig  = require "PudimServer.lib.ResolveHotReloadConfig"
local GetClient               = require "PudimServer.lib.GetClient"
local HeaderLog               = require "PudimServer.lib.HeaderLog"
local escapeSegment           = require "PudimServer.lib.escapeSegment"
local handlerRequest          = require "PudimServer.lib.handlerRequest"
local SendResponse            = require "PudimServer.lib.sendResponse"

local socket      = require("socket")  
local httpParser  = require("PudimServer.http")
local utils       = require("PudimServer.utils")
local cors        = require("PudimServer.cors")
local Pipeline    = require("PudimServer.pipeline")







local MiddlewaresInter = utils:createInterface{
  name = "string",
  Handler = "function"
}


local ConfigServerInter = utils:createInterface{
  ServiceName = {"string", "nil"},
  Address = {"string", "nil"},
  Port = {"number", "nil"},
  Middlewares = {"table", "nil"},
  Https = {"table", "nil"},
  Concurrency = {"table", "nil"},
  HotReload = {"table", "nil"}
}

local ServerInter = utils:createInterface({
      Create = "function",
      Run = "function",
      Routes = "function",
      ServerSocket = {"table", "userdata"},
      _routes = "table",
      SetMiddleware = "function",
      RemoveMiddleware = "function",
      UseHandler = "function",
      RemoveHandler = "function",
      EnableCors = "function",
      EnableHotReload = "function",
  },
  ConfigServerInter
)

local RoutesParamsInter = utils:createInterface{
  path = "string",
  handler = "function"
}

local HttpsConfigInter = utils:createInterface{
  Enabled = {"boolean", "nil"},
  Mode = {"string", "nil"},
  Protocol = {"string", "nil"},
  Key = {"string", "nil"},
  Certificate = {"string", "nil"},
  Verify = {"string", "nil"},
  Options = {"string", "nil"}
}

local ConcurrencyConfigInter = utils:createInterface{
  Enabled = {"boolean", "nil"},
  Sleep = {"number", "nil"}
}

local HotReloadConfigInter = utils:createInterface{
  Enabled = {"boolean", "nil"},
  Modules = {"table", "nil"},
  Prefixes = {"table", "nil"}
}





---@type PudimServer
local PudimServer = {}
PudimServer.__index = PudimServer





--- Registers an HTTP route handler for a given path.
--- Route handlers receive (req, res) and must return res:response(status, body, headers).
---@param path string URL path (e.g. "/api/users")
---@param handler RouteHandler Handler function: fun(req: Request, res: HttpModuler): string
function PudimServer:Routes(path, handler)
  utils:verifyTypes(
    {path = path, handler = handler},
    RoutesParamsInter,
    debugPrint,
    true
  )
  if not self._routes then self._routes = {} end

  

  -- detect dynamic params like :id
  local paramNames = {}
  for name in path:gmatch(":([A-Za-z0-9_]+)") do
    paramNames[#paramNames+1] = name
  end

  local entry = { path = path, handler = handler }
  if #paramNames > 0 then
    -- compile pattern
    local parts = {}
    for segment in path:gmatch("([^/]+)") do
      if segment:sub(1,1) == ":" then
        parts[#parts+1] = "([^/]+)"
      else
        parts[#parts+1] = escapeSegment(segment)
      end
    end
    local prefix = path:sub(1,1) == "/" and "/" or ""
    entry.pattern = "^" .. prefix .. table.concat(parts, "/") .. "$"
    entry.paramNames = paramNames
    entry.dynamic = true
  else
    entry.dynamic = false
  end

  self._routes[#self._routes+1] = entry
end


function PudimServer:RoutesAFile(RoutePath, filePath, headers) 
    self:Routes(RoutePath, function (req, res)
      if req.method == "GET" then
        local content = utils:getContentFile(filePath)
        return res:Response(200, content, headers)
      end

      return res:Response(405, "method not allowed")
    end)
end


--- Enables CORS (Cross-Origin Resource Sharing) support on the server.
--- Automatically handles OPTIONS preflight requests and injects CORS headers.
---@param config? CorsConfig CORS configuration (defaults to allow all origins)
function PudimServer:EnableCors(config)
  self._corsConfig = cors.createConfig(config)
end


--- Enables development hot reload without a file watcher.
--- On each request, configured modules/prefixes are invalidated from package.loaded.
---@param config? HotReloadConfig Hot reload config (default: Enabled=true)
function PudimServer:EnableHotReload(config)
  config = config or { Enabled = true }
  self._hotReloadConfig = ResolveHotReloadConfig(config)
end


--- Adds a handler to the HTTP-level request/response pipeline.
--- Handlers run in order before the route handler.
---@param entry PipelineEntry Handler entry with name and Handler function
function PudimServer:UseHandler(entry)
  self._pipeline:use(entry)
end


--- Removes a pipeline handler by name.
---@param name string Name of the handler to remove
---@return boolean removed True if handler was found and removed
function PudimServer:RemoveHandler(name)
  return self._pipeline:remove(name) ---@diagnostic disable-line: redundant-return-value
end







--- Creates a new PudimServer instance bound to the specified address and port.
--- The server is ready to register routes and run after creation.
---@param config? ConfigServer Server configuration
---@return Server server The new server instance
function PudimServer:Create(config)
  config = config or {}

  utils:verifyTypes(
    config,
    ConfigServerInter,
    debugPrint,
    true
  )

  if config.Https then
    utils:verifyTypes(config.Https, HttpsConfigInter, debugPrint, true)
  end

  if config.Concurrency then
    utils:verifyTypes(config.Concurrency, ConcurrencyConfigInter, debugPrint, true)
  end

  if config.HotReload then
    utils:verifyTypes(config.HotReload, HotReloadConfigInter, debugPrint, true)
  end

  local ServiceName = config.ServiceName or "Pudim Server"
  local Address = config.Address or "localhost"
  local Port = config.Port or 8080
  local Middlewares = config.Middlewares or {}

  local concurrencyConfig = {
    Enabled = (config.Concurrency and config.Concurrency.Enabled) or false,
    Sleep = (config.Concurrency and config.Concurrency.Sleep) or 0.001
  }

  local hotReloadConfig = ResolveHotReloadConfig(config.HotReload)

  local httpsConfig = nil
  if config.Https and config.Https.Enabled ~= false then
    local okSSL, sslModule = pcall(require, "ssl")
    if not okSSL then
      local msg = "HTTPS requires luasec. Install it with: luarocks install luasec --local"
      log.error(msg)
      error(msg, 2)
    end

    if not config.Https.Key or not config.Https.Certificate then
      local msg = "Https.Key and Https.Certificate are required when HTTPS is enabled"
      log.error(msg)
      error(msg, 2)
    end

    httpsConfig = {
      ssl = sslModule,
      params = {
        mode = config.Https.Mode or "server",
        protocol = config.Https.Protocol or "any",
        key = config.Https.Key,
        certificate = config.Https.Certificate,
        verify = config.Https.Verify or "none",
        options = config.Https.Options
      }
    }
  end

  
  
  local ServerSocket, err = socket.bind(Address, Port)
  
  if not ServerSocket then
    local msg = ("Failed to bind server on %s:%s (%s). " ..
      "Use Address='localhost'/'127.0.0.1'/'0.0.0.0' or add '%s' to /etc/hosts pointing to a local IP.")
      :format(tostring(Address), tostring(Port), tostring(err), tostring(Address))
    log.error(msg)
    error(msg, 2)
  end
  


  local Server = {
    ServiceName = ServiceName,
    Port = Port,
    Address = Address,
    ServerSocket = ServerSocket,
    _routes = {},
    _pipeline = Pipeline.new(),
    Middlewares = Middlewares,
    _httpsConfig = httpsConfig,
    _concurrencyConfig = concurrencyConfig,
    _hotReloadConfig = hotReloadConfig
  }

  log.debug("Server created")

  return setmetatable(Server, PudimServer)
end



function PudimServer:SetMiddleware(Mid)
  local  SML = log.inSection("set Middleware log")

  utils:verifyTypes(Mid, MiddlewaresInter, SML.error, true)
  
  table.insert(self.Middlewares, Mid)
end


function PudimServer:RemoveMiddleware(name)
  for i = #self.Middlewares, 1, -1 do
    if self.Middlewares[i].name == name then
      table.remove(self.Middlewares, i)
      return true
    end
  end
  return false
end




--- Starts the server and enters an infinite accept loop.
--- Blocks the current thread. Place all setup (Routes, EnableCors, UseHandler) before calling.
function PudimServer:Run()
  utils:verifyTypes(self, ServerInter, print, true)

  local server = self.ServerSocket 
  local concurrencyEnabled = self._concurrencyConfig and self._concurrencyConfig.Enabled
  if server then server:settimeout(concurrencyEnabled and 0 or nil) end
  HeaderLog(self)

  if not concurrencyEnabled then
    while server do
      local client, ok, msg = GetClient(server, self.Middlewares, self._httpsConfig)
      utils:loadMessageOnChange(1, msg, log)
      
      if ok then
        client:settimeout(30)
        ApplyHotReload(self._hotReloadConfig)
        local response = handlerRequest(client, self._routes, self._corsConfig, self._pipeline)
        
        if response then
          SendResponse(client, response)
        end

        client:close()
      end
    end

    return
  end

  local workers = {}
  local idleSleep = self._concurrencyConfig.Sleep or 0.001

  while server do
    local client, ok, msg = GetClient(server, self.Middlewares, self._httpsConfig)
    utils:loadMessageOnChange(1, msg, log)

    if ok then
      client:settimeout(0)
      local worker = coroutine.create(function()
        ApplyHotReload(self._hotReloadConfig)
        local response = handlerRequest(client, self._routes, self._corsConfig, self._pipeline, coroutine.yield)
        if response then
          SendResponse(client, response, coroutine.yield)
        end
        client:close()
      end)
      workers[#workers + 1] = worker
    end

    for i = #workers, 1, -1 do
      local worker = workers[i]
      if coroutine.status(worker) == "dead" then
        table.remove(workers, i)
      else
        local resumed, workerErr = coroutine.resume(worker)
        if not resumed then
          log.error("worker coroutine error: " .. tostring(workerErr))
          table.remove(workers, i)
        end
      end
    end

    if #workers == 0 and not ok then
      socket.sleep(idleSleep)
    end
  end
  
end



return PudimServer