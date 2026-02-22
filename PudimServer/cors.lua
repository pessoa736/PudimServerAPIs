---@diagnostic disable: duplicate-doc-field

if not _G.log then _G.log = require("loglua") end
local utils = require("PudimServer.utils")


--- interfaces

---@class CorsConfig
---@field AllowOrigins string|string[]? Origins permitidas (default: "*")
---@field AllowMethods string|string[]? Métodos permitidos (default: "GET, POST, PUT, DELETE, PATCH, OPTIONS")
---@field AllowHeaders string|string[]? Headers permitidos (default: "Content-Type, Authorization")
---@field ExposeHeaders string|string[]? Headers expostos ao browser
---@field AllowCredentials boolean? Permitir credentials (default: false)
---@field MaxAge number? Tempo em segundos do cache preflight (default: 86400)

local CorsConfigInter = utils:createInterface{
  AllowOrigins = {"string", "table", "nil"},
  AllowMethods = {"string", "table", "nil"},
  AllowHeaders = {"string", "table", "nil"},
  ExposeHeaders = {"string", "table", "nil"},
  AllowCredentials = {"boolean", "nil"},
  MaxAge = {"number", "nil"},
}


---------
--- main

---@type table
local cors = {}


---@param value string|string[]|nil
---@param default string
---@return string
local function toHeaderValue(value, default)
  if not value then return default end
  if type(value) == "table" then
    return table.concat(value, ", ")
  end
  return value
end


--- Creates a resolved CORS configuration with defaults applied.
---@param config? CorsConfig Raw CORS configuration
---@return table resolvedConfig Config with all defaults filled in
function cors.createConfig(config)
  local CL = log.inSection("CORS")

  config = config or {}
  utils:verifyTypes(config, CorsConfigInter, CL.error, true)

  local resolved = {
    AllowOrigins = toHeaderValue(config.AllowOrigins, "*"),
    AllowMethods = toHeaderValue(config.AllowMethods, "GET, POST, PUT, DELETE, PATCH, OPTIONS"),
    AllowHeaders = toHeaderValue(config.AllowHeaders, "Content-Type, Authorization"),
    ExposeHeaders = toHeaderValue(config.ExposeHeaders, ""),
    AllowCredentials = config.AllowCredentials or false,
    MaxAge = config.MaxAge or 86400,
  }

  return resolved
end


--- Builds CORS response headers from a resolved config.
---@param config table Resolved CORS config (from createConfig)
---@param requestOrigin? string Origin header from the request
---@return table<string, string> headers CORS headers to add to the response
function cors.buildHeaders(config, requestOrigin)
  local headers = {}

  headers["Access-Control-Allow-Origin"] = config.AllowOrigins
  headers["Access-Control-Allow-Methods"] = config.AllowMethods
  headers["Access-Control-Allow-Headers"] = config.AllowHeaders

  if config.ExposeHeaders ~= "" then
    headers["Access-Control-Expose-Headers"] = config.ExposeHeaders
  end

  if config.AllowCredentials then
    headers["Access-Control-Allow-Credentials"] = "true"
  end

  headers["Access-Control-Max-Age"] = tostring(config.MaxAge)

  return headers
end


--- Returns a 204 No Content HTTP response for CORS preflight (OPTIONS) requests.
---@param config table Resolved CORS config (from createConfig)
---@return string response HTTP response string for preflight
function cors.preflightResponse(config)
  local http = require("PudimServer.http")
  local headers = cors.buildHeaders(config)
  headers["Content-Length"] = "0"
  return http:Response(204, "", headers)
end


return cors
