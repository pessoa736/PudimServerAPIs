--[[

    @module "PudimServer"
    @author Davi Passos 
    @version 5.4
    @license MIT

]]--

----------
---imports

if not _G.log then _G.log = require("loglua") end
local http = require("socket.http")
local socket = require("socket")
local ssl = require("ssl")
local checks = require("PS.ServerChecks")
local PSHttp = require("PS.http")

-------------------------
---interfaces definitions


---@class SSLConfig
---@field mode string?
---@field protocol string?
---@field key string?
---@field certificate string?
---@field verify string?
---@field options string[]?

---@class ServerConfig
---@field Address string
---@field Port number|string
---@field UseHttps boolean?
---@field SSLConfig SSLConfig?

---@class req
---@field method string
---@field path string

---@class Server:ServerConfig
---@field __index table|function
---@field handler fun(self: Server, client: table)
---@field CreateServer fun(self: Server, Config: ServerConfig):Server
---@field run fun(self: Server)
---@field Routes table<string, table>
---@field post fun(self: Server, path: string, handler:function)
---@field get fun(self: Server, path: string, handler:function)
---@field dispatch fun(self: Server, req: req):nil|string

---------
--- utils 

---@type table<number, boolean>
    local oneLoadLog={}
    local function OneloadMsg(id, msg)
        local RS = log.inSection("Runtime Server")
        if not oneLoadLog[id] then 
            RS.debug(msg)
            oneLoadLog[id]=true
        end
    end

---------
---module


---@type Server
local PudimServer = {}
PudimServer.__index = PudimServer


function PudimServer:CreateServer(Config)
    local CS = log.inSection("Creating Server")
    CS("start to creating server...")

    local Address = Config.Address or "localhost"
    local Port = tonumber(Config.Port) or 8080
    local Usehttps = Config.UseHttps or false
    local SSLConfig = Config.SSLConfig or {}
    
    local used = checks.is_Port_Open(Address, Port)
    if used then CS(("port %s is busy."):format(Port)) end
    
    while used do
        Port = Port + 1

        CS.debug(("checking if new Port (%s) is Busy..."):format(Port))
        used = checks.is_Port_Open(Address, Port)
        
        if used then
            CS.debug(("port %s is busy. %s"):format(Port))
        end
    end

    local Server = setmetatable({
            Port = Port,
            Address= Address,
            Routes = {},
            UseHttps = Usehttps,
            SSLConfig = SSLConfig
        }, 
    self)
    
    CS("server Create!")

    ---@cast Server -function
    return Server
end

function PudimServer:handler(client)
    local RS = log.inSection("Runtime Server")
    client:settimeout(1)
    local raw = client:receive("*a")
    if not raw then return end

    local req = PSHttp:Parse(raw)
    local route = self:dispatch(req)

    if not route then
        client:send(PSHttp:request(404, "Rota não encontrada", {
            ["Content-Type"] = "text/html"
        }))
        RS.error(("request status[404] %s"):format(req.path))

        return
    end

    local resBody = route(req) or ""
    client:send(PSHttp:request(200, resBody,{
        ["Content-Type"] = "text/html"
    }))

    RS(("request status[200] %s"):format(resBody))
end


local function transformInHttps(client, configSSL)
    local opts = configSSL.options or configSSL.opitions or {"all","no_sslv2","no_sslv3"}
    
    return ssl.wrap(client, {
        mode = configSSL.mode or "server",
        protocol = configSSL.protocol or "tlsv1_2",
        key = configSSL.key or "cert/server.key",
        certificate = configSSL.certificate or "cert/server.crt",
        verify = configSSL.verify or "none",
        options = opts
    })
end



function PudimServer:run()
    local Address = self.Address or "*"
    local Port = self.Port or "8080"
    local UseHttps = self.UseHttps or false

    local RS = log.inSection("Runtime Server")
    RS.debug("initializing Server.")

    if not self.Address then RS.error("Address not defined. try open in localhost") end
    if not self.Port then RS.error("Port not defined. try open in port 8080") end
    
    RS.debug("Creating a Server Bind with luasocket.")
    local srv = socket.bind(Address, Port)
    RS(("server open in https://%s:%s"):format(Address, Port))

    while srv do
        srv:settimeout(0)
        local client= srv:accept()
        if client then 
            client:settimeout(1)

            if UseHttps then
                OneloadMsg(1, "transforming in https with luaSec")
                
                client = transformInHttps(client, self.SSLConfig)
                if client then
                    client:dohandshake()
                end
            end
            
            if client then
                self:handler(client)
                client:close()
            end
        end
    end
end

function PudimServer:get(path, handler)
    self.Routes["GET"] = self.Routes["GET"] or {}
    self.Routes["GET"][path] = handler
end

function PudimServer:post(path, handler)
    self.Routes["POST"] = self.Routes["POST"] or {}
    self.Routes["POST"][path] = handler
end

function  PudimServer:dispatch(req)
    local tableMethod = self.Routes[req.method]
    if not tableMethod then return nil end
    return tableMethod[req.path]
end



return PudimServer