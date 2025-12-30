if not log then log = require("loglua") end

local socket = require("socket")  
local ssl = require("ssl")            
local openssl = require("openssl")  
local json = require("cjson.safe")
local http = require("PS.http")

local PudimServer = {}
PudimServer.__index = PudimServer
PudimServer.__tostring=function(self)
  return json.encode(self)
end

function PudimServer:create(config)
  local ServiceName = config.ServiceName or "Pudim Server"
  
  local Address = config.Address or "localhost"
  local Port = config.Port or "8080"
  
  local useSSL = config.useSSL 
  local SSLConfig = config.SSL
  
  local Server = socket.bind(Address, Port)
  
  return setmetatable({
    ServiceName = ServiceName,
    Port = Port,
    Address = Address,
    Server = Server,
    SSLConfig = SSLConfig,
    useSSL = useSSL,
    
  }, PudimServer)
end

local function GetClientSSL(Server, params)
  local client = Server:accept()
  if not client then return {}, false, "not found client" end
  
  local params = params or {}
  
  local tsl = ssl.wrap(client, params)
  if not tsl then return {}, false, "it was not possible use wrap ssl" end
  
  return tsl, true, "success to get the client"
end

local function GetClient(Server)
  local client = Server:accept()
  if not client then return {}, false, "not found client" end
  
  return client, true, "success to get the client"
end


function PudimServer:run()
  
  
  local server = self.Server
  
  
  while server do
    server:settimeout(0)
    local client, ok, msg = (self.useSSL and GetClientSSL or GetClient)(server)
   -- print(msg)
    if ok and self.useSSL then
      client:dohandshake()
      
      local cert = client:getpeercertificate()
      if cert then
        local der = cert:export("DER")
        local digest = openssl.digest.get("sha256")
        local hash = digest:digest(der)
      end
      client:send(http:request(200, {msg="client get request"}))
      client:close()
    end
  end
end

return PudimServer