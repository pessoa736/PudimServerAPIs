local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"

if not _G.log then _G.log = require("loglua") end

--- imports
local socket = require("socket")  
local ssl = require("ssl")            
local openssl = require("openssl")  
local json = require("cjson.safe")
local http = require("PS.http")
local utils = require("PS.utils")
local TSL = require("PS.TSL")


--- interfaces

---@class ConfigServer
---@field ServiceName string? Nome do serviço (default: "Pudim Server")
---@field Address string? Endereço do servidor (default: "localhost")
---@field Port number? Porta do servidor (default: 8080)

local ConfigServerInter = utils:createInterface(
  {
    ServiceName = {"string", "nil"},
    Address = {"string", "nil"},
    Port = {"number", "nil"}
  }
)

---@alias RouteHandler fun(req: Request, res: Response): string?

---@class Server : ConfigServer
---@field ServiceName string Nome do serviço
---@field Address string Endereço do servidor
---@field Port number Porta do servidor
---@field ServerSocket table Socket do servidor
---@field SSLConfig table Configurações SSL
---@field _routes table<string, RouteHandler> Tabela de rotas registradas
---@field create fun(self: Server, config: ConfigServer): Server Cria uma nova instância
---@field Routes fun(self: Server, path: string, handler: RouteHandler) Registra uma rota
---@field run fun(self: Server) Inicia o servidor

local ServerInter = utils:createInterface({
      create = "function",
      run = "function",
      Routes = "function",
      ServerSocket = {"table", "userdata"},
      _routes = "table",
  },
  ConfigServerInter
)

---@class GetClientConfig
---@field mode string?
---@field verify string?

local GetClientConfigInter = utils:createInterface({
  mode = {"string", "nil"},
  verify = {"string", "nil"}
})

---@class RoutesParams
---@field path string Caminho da rota
---@field handler function Handler da rota

local RoutesParamsInter = utils:createInterface({
  path = "string",
  handler = "function"
})

local LogChecksTypes = log.inSection("checkTypes").debug

---------
--- main

---@type Server
local PudimServer = {}
PudimServer.__index = PudimServer

-- Método para registrar rotas na instância
function PudimServer:Routes(path, handler)
  utils:verifyTypes(
    {path = path, handler = handler},
    RoutesParamsInter,
    LogChecksTypes,
    true
  )
  if not self._routes then self._routes = {} end
  self._routes[path] = handler
end


function PudimServer:create(config)
  utils:verifyTypes(
    config or {},
    ConfigServerInter,
    LogChecksTypes,
    true
  )

  local ServiceName = config.ServiceName or "Pudim Server"
  local Address = config.Address or "localhost"
  local Port = config.Port or 8080
  
  local ServerSocket = socket.bind(Address, Port)
  
  local Server = {
    ServiceName = ServiceName,
    Port = Port,
    Address = Address,
    ServerSocket = ServerSocket,
    SSLConfig = {},
    _routes = {}  -- tabela de rotas própria da instância
  }

  log.debug("Server created")

  ---@cast PudimServer metatable
  ---@cast Server table
  return setmetatable(Server, PudimServer)
end



local function GetClient(Server, conf)
  local client = Server:accept()
  if not client then return {}, false, "not found client" end
  
  utils:verifyTypes(
    conf or {},
    GetClientConfigInter,
    LogChecksTypes,
    false  -- não fatal, conf é opcional
  )
  
  if type(conf)~="table" then
    if not conf then conf = {} else
      return {}, false, "invalid config" 
    end
    
  end

  local pathkey, pathcrt = TSL:ensure(scriptDir)
  
  local params = {
    mode        = conf["mode"] or "server",
    protocol    = "tlsv1_2",
    key         = pathkey,
    certificate = pathcrt,
    verify      = conf["verify"] or "none",
    options     = {
      "all",
      "no_sslv2",
      "no_sslv3",
      "no_tlsv1",
      "no_tlsv1_1",
      "cipher_server_preference",
      "single_dh_use",
      "single_ecdh_use"
    }
  }
  
  ---utils:loadMessageOnChange(2, json.encode(params), (log.inSection("params config")).debug)

  client:settimeout(10)
  local tsl = assert(ssl.wrap(client, params))
  if tsl then tsl:dohandshake() end
  if not tsl then return {}, false, "it was not possible use wrap ssl" end
  
  return tsl, true, "success to get the client"
end



---@param server Server
local function HeaderLog(server)
  utils:loadMessageOnChange(0, ("the server is open in: https://%s:%s"):format(server.Address, server.Port), log)
end

local function handlerRequest(client, routes)
  local RL = log.inSection("Server request")
  
  -- Verificar parâmetros
  if not client or type(client.receive) ~= "function" then
    RL.error("handlerRequest: client inválido")
    return nil
  end
  if type(routes) ~= "table" then
    RL.error("handlerRequest: routes deve ser uma tabela")
    return http:request(500, "Internal Server Error", {["Content-Type"] = "text/plain"})
  end
  
  local msid = 0 
  local function _msg(msg, mode)
      utils:loadMessageOnChange("Server-Request" .. msid, msg, RL[mode] or RL.debug)
      msid = msid + 1
  end

  local data, err = client:receive("*l")
  if not data then 
    _msg("receive data error "..tostring(err), "error")
    return nil
  end

  local raw = data .. "\r\n"
  repeat
    local line = client:receive("*l")
    if line then raw = raw .. line .. "\r\n" end
  until not line or line == ""

  local req = http:Parse(raw)
  if not req or not req.path or not req.method then
    return http:request(400, "Bad Request", {["Content-Type"] = "text/plain"})
  end

  _msg(("request: %s %s"):format(req.method, req.path))

  -- Debug: mostrar rotas registradas
  _msg("rotas registradas: " .. tostring(next(routes) and "tem rotas" or "vazio"))

  local handler = routes[req.path]
  if handler then
    local res = http
    local response = handler(req, res)
    return response
  end

  return http:request(404, "Not Found", {["Content-Type"] = "text/plain"})
end

function PudimServer:run()
  utils:verifyTypes(self, ServerInter, (log.inSection("checktypes")).debug, true)

  local server = self.ServerSocket 
  server:settimeout(nil)
  HeaderLog(self)
  
  while server do
    local client, ok, msg = GetClient(server)
    utils:loadMessageOnChange(1, msg, log)
    
    if ok then      
      local response = handlerRequest(client, self._routes)
      
      if response then
        client:send(response)
      end

      client:close()
    end
  end
end

return PudimServer