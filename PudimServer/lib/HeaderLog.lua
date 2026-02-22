local utils<const> = require "PudimServer.utils"

---@param server Server
return function (server)
  utils:loadMessageOnChange(0, ("the server is open in: http://%s:%s"):format(server.Address, server.Port), log)
end