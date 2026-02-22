local utils         = require "PudimServer.utils"
local debugPrint    = require "PudimServer.lib.debugPrint"


local HotReloadConfigInter = utils:createInterface{
  Enabled = {"boolean", "nil"},
  Modules = {"table", "nil"},
  Prefixes = {"table", "nil"}
}


---@param value any
---@param fieldName string
local function ValidateStringArray(value, fieldName)
  if value == nil then return end
  if type(value) ~= "table" then
    error(("%s must be a table of strings"):format(fieldName), 3)
  end

  for i, item in ipairs(value) do
    if type(item) ~= "string" then
      error(("%s[%d] must be a string"):format(fieldName, i), 3)
    end
  end
end



---@param config HotReloadConfig?
---@return HotReloadConfig
return function (config)
  config = config or {}
  utils:verifyTypes(config, HotReloadConfigInter, debugPrint, true)

  ValidateStringArray(config.Modules, "HotReload.Modules")
  ValidateStringArray(config.Prefixes, "HotReload.Prefixes")

  return {
    Enabled = config.Enabled or false,
    Modules = config.Modules or {},
    Prefixes = config.Prefixes or {}
  }
end