---@diagnostic disable: duplicate-doc-field, duplicate-doc-alias




-----------
--- imports
if not _G.log then _G.log = require("loglua") end
local socket = require("socket")  
local http = require("PudimServer.http")
local utils = require("PudimServer.utils")
local cors = require("PudimServer.cors")
local Pipeline = require("PudimServer.pipeline")



--------------
--- interfaces


---@alias RouteHandler fun(req: Request, res: HttpModule): string?


---@class Middlewares: table
---@field name string
---@field Handler fun(Client: any): any



---@class ConfigServer
---@field ServiceName string? Nome do serviço (default: "Pudim Server")
---@field Address string? Endereço do servidor (default: "localhost")
---@field Port number? Porta do servidor (default: 8080)
---@field Middlewares Middlewares[]? Middlewares de socket
---@field Https HttpsConfig? Configuração HTTPS nativa (luasec)
---@field Concurrency ConcurrencyConfig? Configuração de concorrência cooperativa
---@field HotReload HotReloadConfig? Hot reload em desenvolvimento sem watcher (limpa package.loaded)

---@class HttpsConfig
---@field Enabled boolean? Habilitar HTTPS nativo (default: false)
---@field Mode string? Modo SSL (default: "server")
---@field Protocol string? Protocolo SSL (default: "any")
---@field Key string? Caminho da chave privada
---@field Certificate string? Caminho do certificado
---@field Verify string? Política de verificação (default: "none")
---@field Options string? Opções SSL (ex: "all")

---@class ConcurrencyConfig
---@field Enabled boolean? Habilitar concorrência cooperativa com corrotinas (default: false)
---@field Sleep number? Intervalo de espera do loop quando ocioso (default: 0.001)

---@class HotReloadConfig
---@field Enabled boolean? Habilitar hot reload sem watcher (default: false)
---@field Modules string[]? Módulos exatos para invalidar em package.loaded
---@field Prefixes string[]? Prefixos de módulos para invalidar em package.loaded


---@class Server : ConfigServer
---@field ServerSocket table|userdata Socket do servidor
---@field _routes RouteEntry[] Tabela de rotas registradas
---@field _corsConfig table? Config CORS resolvida
---@field _pipeline Pipeline Pipeline de handlers HTTP
---@field _httpsConfig table? Config HTTPS interna
---@field _concurrencyConfig ConcurrencyConfig Config de concorrência interna
---@field _hotReloadConfig HotReloadConfig Config de hot reload interna
---@field __index Server

---@class RouteEntry
---@field path string Caminho original da rota
---@field handler RouteHandler Handler da rota
---@field dynamic boolean Se a rota tem parâmetros dinâmicos
---@field pattern string? Pattern compilado para matching dinâmico
---@field paramNames string[]? Nomes dos parâmetros dinâmicos

---@class RoutesParams
---@field path string Caminho da rota
---@field handler RouteHandler Handler da rota


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
      SetMiddlewares = "function",
      RemoveMiddlewares = "function",
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

local LogChecksTypes = log.inSection("checkTypes").debug





---------
--- MAIN




---@class PudimServer : Server
---@field __index PudimServer
---@field Create fun(self: PudimServer, config?: ConfigServer): Server
---@field Routes fun(self: PudimServer, path: string, handler: RouteHandler)
---@field Run fun(self: PudimServer)
---@field SetMiddlewares fun(self: PudimServer, Mid: Middlewares)
---@field RemoveMiddlewares fun(self: PudimServer, name: string): boolean
---@field UseHandler fun(self: PudimServer, entry: PipelineEntry)
---@field RemoveHandler fun(self: PudimServer, name: string): boolean
---@field EnableCors fun(self: PudimServer, config?: CorsConfig)
---@field EnableHotReload fun(self: PudimServer, config?: HotReloadConfig)
---@diagnostic disable: missing-fields
---@type PudimServer
local PudimServer = {}
PudimServer.__index = PudimServer

---@param value any
---@param fieldName string
local function ValidateStringArray(value, fieldName)
  if value == nil then return end
  if type(value) ~= "table" then
    error(("%s must be a table of strings"):format(fieldName), 3)
  end

  for i, item in ipairs(value) do
    if type(item) ~= "string" then
      error(("%s[%d] must be a string"):format(fieldName, i), 3)
    end
  end
end

---@param config HotReloadConfig?
---@return HotReloadConfig
local function ResolveHotReloadConfig(config)
  config = config or {}
  utils:verifyTypes(config, HotReloadConfigInter, LogChecksTypes, true)

  ValidateStringArray(config.Modules, "HotReload.Modules")
  ValidateStringArray(config.Prefixes, "HotReload.Prefixes")

  return {
    Enabled = config.Enabled or false,
    Modules = config.Modules or {},
    Prefixes = config.Prefixes or {}
  }
end

---@param config HotReloadConfig?
local function ApplyHotReload(config)
  if not config or not config.Enabled then return end

  for _, moduleName in ipairs(config.Modules or {}) do
    package.loaded[moduleName] = nil
  end

  local prefixes = config.Prefixes or {}
  if #prefixes == 0 then return end

  for loadedName, _ in pairs(package.loaded) do
    if type(loadedName) == "string" then
      for _, prefix in ipairs(prefixes) do
        if loadedName:sub(1, #prefix) == prefix then
          package.loaded[loadedName] = nil
          break
        end
      end
    end
  end
end






--- Registers an HTTP route handler for a given path.
--- Route handlers receive (req, res) and must return res:response(status, body, headers).
---@param path string URL path (e.g. "/api/users")
---@param handler RouteHandler Handler function: fun(req: Request, res: HttpModuler): string
function PudimServer:Routes(path, handler)
  utils:verifyTypes(
    {path = path, handler = handler},
    RoutesParamsInter,
    LogChecksTypes,
    true
  )
  if not self._routes then self._routes = {} end

  local function escapeSegment(s)
    return s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")
  end

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
    LogChecksTypes,
    true
  )

  if config.Https then
    utils:verifyTypes(config.Https, HttpsConfigInter, LogChecksTypes, true)
  end

  if config.Concurrency then
    utils:verifyTypes(config.Concurrency, ConcurrencyConfigInter, LogChecksTypes, true)
  end

  if config.HotReload then
    utils:verifyTypes(config.HotReload, HotReloadConfigInter, LogChecksTypes, true)
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




---@param ServerRun table|userdata Socket do servidor
---@param Middlewares Middlewares[] Middlewares de socket
---@param httpsConfig? table Config HTTPS interna
---@return table client Conexão do cliente
---@return boolean ok Se o cliente foi obtido com sucesso
---@return string message Mensagem de status
local function GetClient(ServerRun, Middlewares, httpsConfig)
  local client, acceptErr = ServerRun:accept()

  if not client then
    if acceptErr == "timeout" then
      return {}, false, "waiting client"
    end
    return {}, false, "accept error: " .. tostring(acceptErr)
  end
  
  for idx, mw in ipairs(Middlewares) do
    client = mw.Handler(client)
  end
  
  if not client then return {}, false, "not found client" end

  if httpsConfig then
    local secureClient, wrapErr = httpsConfig.ssl.wrap(client, httpsConfig.params)
    if not secureClient then
      client:close()
      return {}, false, "https wrap error: " .. tostring(wrapErr)
    end

    secureClient:settimeout(0)
    local start = socket.gettime()
    while true do
      local okHandshake, handshakeErr = secureClient:dohandshake()
      if okHandshake then
        break
      end

      if handshakeErr == "wantread" or handshakeErr == "wantwrite" or handshakeErr == "timeout" then
        if socket.gettime() - start > 10 then
          secureClient:close()
          return {}, false, "https handshake timeout"
        end
        socket.sleep(0.001)
      else
        secureClient:close()
        return {}, false, "https handshake error: " .. tostring(handshakeErr)
      end
    end

    client = secureClient
  end
  

  client:settimeout(10)
  return client, true, "Get Client"
end



---@param server Server
local function HeaderLog(server)
  utils:loadMessageOnChange(0, ("the server is open in: http://%s:%s"):format(server.Address, server.Port), log)
end





---@param yieldFn? fun() Função para cooperar em modo concorrente
local function handlerRequest(client, routes, corsConfig, pipeline, yieldFn)
  local RL = log.inSection("Server response")
  
  if not client or type(client.receive) ~= "function" then
    RL.error("handlerRequest: client inválido")
    return nil
  end
  if type(routes) ~= "table" then
    RL.error("handlerRequest: routes deve ser uma tabela")
    return http:response(500, "Internal Server Error", {["Content-Type"] = "text/plain", ["Connection"] = "close"})
  end
  

  local msid = 0 
  local function _msg(msg, mode)
      utils:loadMessageOnChange("Server-Request" .. msid, msg, RL[mode] or RL.debug)
      msid = msid + 1
  end

  local function receiveLine()
    while true do
      local line, lineErr = client:receive("*l")
      if line then
        return line, nil
      end

      if (lineErr == "timeout" or lineErr == "wantread" or lineErr == "wantwrite") and yieldFn then
        yieldFn()
      else
        return nil, lineErr
      end
    end
  end

  local data, err = receiveLine()
  if not data then 
    _msg("receive data error "..tostring(err), "error")
    return nil
  end

  local raw = data .. "\r\n"
  while true do
    local line, lineErr = receiveLine()
    if not line then
      if lineErr and lineErr ~= "closed" then
        _msg("receive header error " .. tostring(lineErr), "error")
      end
      break
    end

    raw = raw .. line .. "\r\n"
    if line == "" then
      break
    end
  end

  local req = http:ParseRequest(raw)
  if not req or not req.path or not req.method then
    return http:response(400, "Bad Request", {["Content-Type"] = "text/plain", ["Connection"] = "close"})
  end

  _msg(("response: %s %s"):format(req.method, req.path))

  -- CORS preflight
  if corsConfig and req.method == "OPTIONS" then
    return cors.preflightResponse(corsConfig)
  end

  -- Debug: mostrar rotas registradas
  _msg("rotas registradas: " .. tostring(next(routes) and "tem rotas" or "vazio"))

  local function routeHandler(req, res)
    -- try exact/static match first
    for _, entry in ipairs(routes) do
      if not entry.dynamic and entry.path == req.path then
        return entry.handler(req, res)
      end
    end

    -- try dynamic routes
    for _, entry in ipairs(routes) do
      if entry.dynamic and entry.pattern then
        local captures = { string.match(req.path, entry.pattern) }
        if captures[1] then
          -- populate req.params
          req.params = req.params or {}
          for i, name in ipairs(entry.paramNames or {}) do
            req.params[name] = captures[i]
          end
          return entry.handler(req, res)
        end
      end
    end

    return http:response(404, "Not Found", {["Content-Type"] = "text/plain", ["Connection"] = "close"})
  end

  local response = pipeline:execute(req, http, routeHandler)

  -- Injeta headers CORS na resposta
  if corsConfig and response then
    local corsHeaders = cors.buildHeaders(corsConfig, req.headers["origin"])
    for k, v in pairs(corsHeaders) do
      response = response:gsub("(\r\n\r\n)", "\r\n" .. k .. ": " .. v .. "%1", 1)
    end
  end

  return response
end


---@param client table
---@param response string
---@param yieldFn? fun()
---@return boolean ok
---@return string? err
local function SendResponse(client, response, yieldFn)
  local index = 1

  while index <= #response do
    local sent, err, last = client:send(response, index)
    if sent then
      index = sent + 1
    elseif err == "timeout" or err == "wantread" or err == "wantwrite" then
      if last and last >= index then
        index = last + 1
      end
      if yieldFn then
        yieldFn()
      else
        return false, err
      end
    else
      return false, err
    end
  end

  return true
end



--- Adds a socket-level middleware that transforms the client connection.
--- Middlewares run on the raw TCP socket before HTTP parsing.
---@param Mid Middlewares Middleware with name and Handler function(client) → client
function PudimServer:SetMiddlewares(Mid)
  local  SML = log.inSection("set Middleware log")

  utils:verifyTypes(Mid, MiddlewaresInter, SML.error, true)
  
  table.insert(self.Middlewares, Mid)
end


--- Removes a socket-level middleware by name.
---@diagnostic disable: redundant-return-value
---@param name string Name of the middleware to remove
---@return boolean removed True if middleware was found and removed
function PudimServer:RemoveMiddlewares(name)
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
  utils:verifyTypes(self, ServerInter, (log.inSection("checktypes")).error, true)

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


-- Help module removed: `PudimServer.help` is no longer available.
-- `PudimServer.version()` functionality was removed along with the help module.



return PudimServer