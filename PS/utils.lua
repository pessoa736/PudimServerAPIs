
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
    if f then return true end
    return false
end


function utils:getContentFile(file)
    local f<close> = assert(io.open(file, "r"), "file not exist")
    local content = f:read("*a")
    return content
end

function utils:mkdir(path)
  os.execute("mkdir -p " .. path)
end

return utils