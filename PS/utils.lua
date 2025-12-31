
local utils = {}

function utils:loadMessageOnChange(channel, msg, printerFunction)
    if not self.mensagens then self.mensagens = {} end

    if not self.mensagens[channel] then self.mensagens[channel] = { old = nil } end

    if self.mensagens[channel].old ~= msg then
        (printerFunction or print)(msg)
        self.mensagens[channel].old = msg
    end
end

function utils:checkFilesExist(file)
    local f<close> = io.open(file, "r")
    return type(f)=="string" and f~=nil
end

return utils