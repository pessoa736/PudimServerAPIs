---@diagnostic disable: duplicate-doc-field, duplicate-doc-alias




-----------
--- imports
if not _G.log then _G.log = require("loglua") end
local socket = require("socket")  
local http = require("PudimServer.http")
local utils = require("PudimServer.utils")
local ssl = require("ssl")



--------------
--- interfaces


---@alias RouteHandler fun(req: Request, res: HttpModuler): string?


---@class Middlewares: table
---@field name string
---@field Handler fun(Client: any): any



---@class ConfigServer
---@field ServiceName string? Nome do serviço (default: "Pudim Server")
---@field Address string? Endereço do servidor (default: "localhost")
---@field Port number? Porta do servidor (default: 8080)
---@field Middlewares table<any, Middlewares>?


---@class Server : ConfigServer, table, metatable
---@field ServerSocket table Socket do servidor
---@field _routes table<string, RouteHandler> Tabela de rotas registradas
---@field Create fun(self: Server, config?: ConfigServer): Server Cria uma nova instância
---@field Routes fun(self: Server, path: string, handler: RouteHandler) Registra uma rota
---@field Run fun(self: Server) Inicia o servidor
---@field SetMiddlewares fun(self: Server, Middlewares: Middlewares)
---@field RemoveMiddlewares fun(self: Server, NameMiddlewares: string)

---@class GetClientConfig
---@field mode string?
---@field verify string?

---@class RoutesParams
---@field path string Caminho da rota
---@field handler function Handler da rota


local MiddlewaresInter = utils:createInterface{
  name = {"string", "number"},
  Handler = "function"
}


local ConfigServerInter = utils:createInterface{
    ServiceName = {"string", "nil"},
    Address = {"string", "nil"},
    Port = {"number", "nil"},
    clientMiddlewares = "table"
}

local ServerInter = utils:createInterface({
      create = "function",
      run = "function",
      Routes = "function",
      ServerSocket = {"table", "userdata"},
      _routes = "table",
      SetMiddlewares = "function",
      RemoveMiddlewares = "function",
  },
  ConfigServerInter
)

local GetClientConfigInter = utils:createInterface{
  mode = {"string", "nil"},
  verify = {"string", "nil"}
}

local RoutesParamsInter = utils:createInterface{
  path = "string",
  handler = "function"
}

local LogChecksTypes = log.inSection("checkTypes").debug





---------
--- MAIN




---@diagnostic disable: missing-fields
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







function PudimServer:Create(config)
  utils:verifyTypes(
    config or {},
    ConfigServerInter,
    LogChecksTypes,
    true
  )

  local ServiceName = config.ServiceName or "Pudim Server"
  local Address = config.Address or "localhost"
  local Port = config.Port or 8080
  local Middlewares = config.Middlewares or {}

  
  
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
    Middlewares = Middlewares
  }

  log.debug("Server created")

  ---@cast PudimServer metatable
  ---@cast Server table
  return setmetatable(Server, PudimServer)
end




---@type fun(ServerRun: table|userdata, Middlewares: table<any, Middlewares>):table, boolean, string
local function GetClient(ServerRun, Middlewares)
  local client = ServerRun:accept()
  
  for idx, mw in ipairs(Middlewares) do
    client = mw.Handler(client)
  end
  
  if not client then return {}, false, "not found client" end
  

  client:settimeout(10)
  return client, true, "Get Client"
end



---@param server Server
local function HeaderLog(server)
  utils:loadMessageOnChange(0, ("the server is open in: http://%s:%s"):format(server.Address, server.Port), log)
end





local function handlerRequest(client, routes)
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

  local req = http:ParseRequest(raw)
  if not req or not req.path or not req.method then
    return http:response(400, "Bad Request", {["Content-Type"] = "text/plain", ["Connection"] = "close"})
  end

  _msg(("response: %s %s"):format(req.method, req.path))

  -- Debug: mostrar rotas registradas
  _msg("rotas registradas: " .. tostring(next(routes) and "tem rotas" or "vazio"))

  local handler = routes[req.path]
  if handler then
    local res = http
    local response = handler(req, res)
    return response
  end

  return http:response(404, "Not Found", {["Content-Type"] = "text/plain", ["Connection"] = "close"})
end



function PudimServer:SetMiddlewares(Mid)
  local  SML = log.inSection("set Middleware log")

  utils:verifyTypes(Mid, MiddlewaresInter, SML.error, true)
  
  table.insert(self.Middlewares, Mid)
end




function PudimServer:Run()
  utils:verifyTypes(self, ServerInter, (log.inSection("checktypes")).error, true)

  self:SetMiddlewares{
      name = "SSL", 
      Handler = function (Client)
        local params = {
          mode = "server",
          protocol = "tlsv1_3",
          key = "/etc/certs/serverkey.pem",
          certificate = "/etc/certs/server.pem",
          cafile = "/etc/certs/CA.pem",
          verify = {"peer", "fail_if_no_peer_cert"},
          options = "all"
        }

        local Client_ssl = ssl.wrap(Client, params)
        if Client_ssl then 
          Client_ssl:dohandshake()
          return Client_ssl
        end
          
        return Client
      end
    }

  local server = self.ServerSocket 
  if server then server:settimeout(nil) end
  HeaderLog(self)
  
  while server do
    local client, ok, msg = GetClient(server, self.Middlewares)
    utils:loadMessageOnChange(1, msg, log)
    
    if ok then
      client:settimeout(30)
      local response = handlerRequest(client, self._routes)
      
      if response then
        client:send(response)
      end

      client:close()
    end
  end
end

return PudimServer