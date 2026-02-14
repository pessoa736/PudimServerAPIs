---@diagnostic disable: duplicate-doc-field

if not _G.log then _G.log = require("loglua") end
local utils = require("PudimServer.utils")
local socket = require("socket")


--- interfaces

---@class CacheConfig
---@field MaxSize number? Máximo de entradas no cache (default: 100)
---@field DefaultTTL number? TTL padrão em segundos (default: 60)

local CacheConfigInter = utils:createInterface{
  MaxSize = {"number", "nil"},
  DefaultTTL = {"number", "nil"},
}


---@class CacheEntry
---@field response string Resposta HTTP cacheada
---@field expiresAt number Timestamp de expiração


---------
--- main

---@class Cache
---@field _entries table<string, CacheEntry>
---@field _maxSize number
---@field _defaultTTL number
local Cache = {}
Cache.__index = Cache


---@param config? CacheConfig
---@return Cache
function Cache.new(config)
  local CL = log.inSection("Cache")

  config = config or {}
  utils:verifyTypes(config, CacheConfigInter, CL.error, true)

  local self = setmetatable({}, Cache)
  self._entries = {}
  self._maxSize = config.MaxSize or 100
  self._defaultTTL = config.DefaultTTL or 60
  self._size = 0
  return self
end


---@param key string
---@return string? response
function Cache:get(key)
  local entry = self._entries[key]
  if not entry then return nil end

  if socket.gettime() > entry.expiresAt then
    self._entries[key] = nil
    self._size = self._size - 1
    return nil
  end

  return entry.response
end


---@param key string
---@param response string
---@param ttl? number TTL em segundos (usa default se nil)
function Cache:set(key, response, ttl)
  if not self._entries[key] then
    -- Evict oldest if full
    if self._size >= self._maxSize then
      self:_evict()
    end
    self._size = self._size + 1
  end

  self._entries[key] = {
    response = response,
    expiresAt = socket.gettime() + (ttl or self._defaultTTL)
  }
end


---@param key string
function Cache:invalidate(key)
  if self._entries[key] then
    self._entries[key] = nil
    self._size = self._size - 1
  end
end


function Cache:clear()
  self._entries = {}
  self._size = 0
end


function Cache:_evict()
  local oldestKey = nil
  local oldestTime = math.huge

  for key, entry in pairs(self._entries) do
    if entry.expiresAt < oldestTime then
      oldestTime = entry.expiresAt
      oldestKey = key
    end
  end

  if oldestKey then
    self._entries[oldestKey] = nil
    self._size = self._size - 1
  end
end


---@param cacheInstance Cache
---@param ttl? number TTL customizado
---@return PipelineEntry
function Cache.createPipelineHandler(cacheInstance, ttl)
  return {
    name = "cache",
    Handler = function(req, res, next)
      -- Só cacheia GET requests
      if req.method ~= "GET" then
        return next()
      end

      local key = req.method .. ":" .. req.path
      local cached = cacheInstance:get(key)

      if cached then
        log.inSection("Cache").debug("cache hit: " .. key)
        return cached
      end

      local response = next()

      if response then
        cacheInstance:set(key, response, ttl)
        log.inSection("Cache").debug("cache set: " .. key)
      end

      return response
    end
  }
end


return Cache
