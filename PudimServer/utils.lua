---@diagnostic disable: duplicate-doc-field


--- interfaces

---@class Interface
---@field __IsInterface boolean Indica que é uma interface
---@field __fields table<string, string|string[]|Interface> Campos da interface

---@class message
---@field old string|nil

---@class Utils: table
---@field mensagens message[] Cache de mensagens para loadMessageOnChange
---@field __savedTypes Interface[] Interfaces salvas
---@field loadMessageOnChange fun(self: Utils, channel: any, msg: any, printerFunction?: function|table) Imprime mensagem se mudou
---@field checkFilesExist fun(self: Utils, file: string): boolean Verifica se arquivo existe
---@field getContentFile fun(self: Utils, file: string): string Lê conteúdo do arquivo
---@field writeFile fun(self: Utils, file: string, content: string) Escreve conteúdo no arquivo
---@field _matches fun(self: Utils, value: any, contract: string|string[]|Interface): boolean Verifica se valor corresponde ao contrato
---@field verifyTypes fun(self: Utils, value: any, contract: any, printerFunction?: function, _break?: boolean): boolean, string? Verifica tipos
---@field createInterface fun(self: Utils, fields: table, extends?: Interface): Interface Cria uma interface
---@field mkdir fun(self: Utils, path: string) Cria diretório


---------
--- main

---@diagnostic disable: missing-fields
---@type Utils
local utils = {} 


---------
--- functions

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

function utils:writeFile(file, content)
    local f<close> = assert(io.open(file, "w+"))
    assert(f:write(content))
end


function utils:_matches(value, contract)
    local ctype = type(contract)
    if ctype == "table" and not contract.__IsInterface then
        for _, option in ipairs(contract) do
            if self:_matches(value, option) then
                return true
            end
        end
        return false
    end
    if ctype == "string" then
        return type(value) == contract
    end

    if ctype == "table" and contract.__IsInterface then
        return self:verifyTypes(value, contract)
    end

    return false
end


---@type fun(self: table, value: any, contract: any, printFunction?: function, _break?: boolean): boolean, string?
function utils:verifyTypes(value, contract, printerFunction, _break)
    if type(contract) ~= "table" or not contract.__IsInterface then
        if self:_matches(value, contract) then
            return true
        end

        local msg = "Value not satisface the contract"
        if not printerFunction then
            return false, msg
        else
            printerFunction(msg)
            if _break then os.exit(false, true) end
            return false
        end
    end

    if type(value) ~= "table" then
         local msg = "expected object, get "..type(value)
        if not printerFunction then
            return false, msg
        else
            printerFunction(msg)
            if _break then os.exit(false, true) end
            return false
        end
    end

    for field, expected in pairs(contract.__fields) do
        local val = value[field]
        if val == nil then
            return false, "'"..field.."' absent"
        end
        if not self:_matches(val, expected) then
            local msg = 
                "'"..field.."' invalid. expected:"..tostring(expected)..
                ", get "..type(val)

            if not printerFunction then
                return false, msg
            else
                printerFunction(msg)
                if _break then os.exit(false, true) end
                return false
            end
        end
    end

    return true
end


function utils:createInterface(fields, extends)
    local int = {
        __IsInterface = true,
        __fields = {}
    }

    if extends and extends.__IsInterface then
        for k, v in pairs(extends.__fields) do
            int.__fields[k] = v
        end
    end

    for k, v in pairs(fields) do
        int.__fields[k] = v
    end

    if not self.__savedTypes or type(self.__savedTypes)~="table" then
        self.__savedTypes = {}
    end

    table.insert(self.__savedTypes, int)
    return int
end


function utils:mkdir(path)
  os.execute("mkdir -p " .. path)
end

return utils