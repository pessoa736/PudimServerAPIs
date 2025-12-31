local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"

if not _G.log then _G.log = require("loglua") end


--- imports
local socket = require("socket")  
local ssl = require("ssl")            
local openssl = require("openssl")  
local json = require("cjson.safe")
local http = require("PS.http")
local utils = require("PS.utils")



--- interfaces

---@class ConfigServer
---@field ServiceName string
---@field Address string
---@field Port number
---@field SSLConfig table
---@field useSSL boolean?

---@class Server:ConfigServer, table, function
---@field create fun(self: Server, config: ConfigServer):Server
---@field Run fun(self: Server)
---@field ServerSocket userdata|lightuserdata|table


---@type Server
local PudimServer = {}
PudimServer.__index = PudimServer

function PudimServer:create(config)

  local ServiceName = config.ServiceName or "Pudim Server"
  local Address = config.Address or "localhost"
  local Port = config.Port or 8080
  
  local useSSL = config.useSSL
  if useSSL==nil then useSSL = true end

  local SSLConfig = config.SSLConfig
  local ServerSocket = socket.bind(Address, Port)

  if useSSL and (not SSLConfig or not SSLConfig.certificate or not SSLConfig.key) then 
    if utils:checkFilesExist(scriptDir .. "./Cert/server.key")  then 
      SSLConfig.key =  ---- 
    end
  end
  
  local Server = {
    ServiceName = ServiceName,
    Port = Port,
    Address = Address,
    ServerSocket = ServerSocket,
    SSLConfig = SSLConfig,
    useSSL = useSSL,
  }

  log.debug("Server created")
  return setmetatable(Server, PudimServer)
end



local function GetClientSSL(Server, params)
  local client = Server:accept()
  if not client then return {}, false, "not found client" end
  
  local params = {
    mode        = params.mode or "server",
    protocol    = params.protocol or"tlsv1_2",
    key         = params.Key,
    certificate = params.Cert,
    verify      = params.verify or "peer",      
    options     = params.options or "all"
  }
  
  local tsl = ssl.wrap(client, params)
  if not tsl then return {}, false, "it was not possible use wrap ssl" end
  
  return tsl, true, "success to get the client"
end

local function GetClient(Server)
  local client = Server:accept()
  if not client then return {}, false, "not found client" end
  
  return client, true, "success to get the client without SSL"
end



---@param server Server
local function HeaderLog(server)
  utils:loadMessageOnChange(0, ("the server is open in: https://%s:%s"):format(server.Address, server.Port), log)
end


function PudimServer:run()
  local server = self.ServerSocket 
  server:settimeout(0)
  HeaderLog(self)
  
  while server do

    local client, ok, msg = (self.useSSL and GetClientSSL or GetClient)(server)
    utils:loadMessageOnChange(1, msg, log)
    
    if ok then
      if self.useSSL then
        client:dohandshake()
        
        local cert = client:getpeercertificate()
        if cert then
          local der = cert:export("DER")
          local digest = openssl.digest.get("sha256")
          local hash = digest:digest(der)
        end
      end

      client:send(http:request(200, {msg="client get request"}))
      client:close()
    end
  end
end

return PudimServer