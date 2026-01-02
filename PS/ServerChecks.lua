if not _G.log then _G.log = require("loglua") end
local socket = require("socket")
local utils = require("PS.utils")


--- interfaces

---@class PortCheckParams
---@field Address string Endereço a verificar
---@field Port number|string Porta a verificar

local PortCheckParamsInter = utils:createInterface({
    Address = "string",
    Port = {"number", "string"}
})


---------
--- main

local ServerChecks = {}
ServerChecks.__index = ServerChecks

---@param Address string
---@param Port number|string
---@return boolean is_open
---@return string erro
function ServerChecks.is_Port_Open(Address, Port)
    local CIPO = log.inSection("Check: is Port Open")
    
    utils:verifyTypes(
        {Address = Address, Port = Port},
        PortCheckParamsInter,
        CIPO.error,
        true
    )

    local res = {isOpen = false, msg = ""}

    CIPO.debug("creating client...")
    local client, erroClient = socket.tcp()
    local clientOk, erroOk

    if client then
        CIPO.debug("client created!")

        client:settimeout(1)

        CIPO.debug("checking if the door is open...")
        clientOk, erroOk = client:connect(Address, Port)

        if clientOk then
            res.isOpen = true
            res.msg = ("the port %s is open."):format(Port)

            CIPO.debug(res.msg)
            goto continue
            
        else
            res.isOpen = false
            res.msg = ("the port %s is not open: %s."):format(Port, erroOk)

            CIPO.debug(res.msg)
            goto continue
        end
    else
        --- if the client fails to load
        res.isOpen = false 
        res.msg = ("Error Creating Client (ECC): %s."):format(erroClient)

        CIPO.debug(res.msg)

        goto continue
    end

    ::continue::
    return res.isOpen, res.msg
end


return ServerChecks