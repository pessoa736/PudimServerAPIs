local socket = require("socket")
local utils = require("PudimServer.utils")
local debugPrint = require("PudimServer.lib.debugPrint")


local PortCheckParamsInter = utils:createInterface({
    Address = "string",
    Port = {"number", "string"}
})

---@param Address string
---@param Port number
return function (Address, Port)
    utils:verifyTypes(
        {Address = Address, Port = Port},
        PortCheckParamsInter,
        print,
        true
    )

    local res = {isOpen = false, msg = ""}

    debugPrint("creating client...")
    local client, erroClient = socket.tcp()
    local clientOk, erroOk

    if client then
        debugPrint("client created!")

        client:settimeout(1)

        debugPrint("checking if the door is open...")
        clientOk, erroOk = client:connect(Address, Port)

        if clientOk then
            res.isOpen = true
            res.msg = ("the port %s is open."):format(Port)

            debugPrint(res.msg)
            goto continue
            
        else
            res.isOpen = false
            res.msg = ("the port %s is not open: %s."):format(Port, erroOk)

            debugPrint(res.msg)
            goto continue
        end
    else
        --- if the client fails to load
        res.isOpen = false 
        res.msg = ("Error Creating Client (ECC): %s."):format(erroClient)

        debugPrint(res.msg)

        goto continue
    end

    ::continue::
    return res.isOpen, res.msg
end

