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
---@field _size number Tamanho atual do cache
local Cache = {}
Cache.__index = Cache


--- Creates a new Cache instance with optional configuration.
---@param config? CacheConfig Cache configuration (MaxSize, DefaultTTL)
---@return Cache cache New cache instance
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


--- Retrieves a cached response by key. Returns nil if expired or not found.
---@param key string Cache key (typically "METHOD:path")
---@return string? response Cached HTTP response or nil
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


--- Stores a response in the cache. Evicts oldest entry if cache is full.
---@param key string Cache key (typically "METHOD:path")
---@param response string HTTP response string to cache
---@param ttl? number TTL in seconds (uses DefaultTTL if nil)
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


--- Removes a single entry from the cache.
---@param key string Cache key to invalidate
function Cache:invalidate(key)
  if self._entries[key] then
    self._entries[key] = nil
    self._size = self._size - 1
  end
end


--- Removes all entries from the cache.
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


--- Creates a PipelineEntry that caches GET responses.
--- Only caches GET requests. Cache key format: "method:path".
---@param cacheInstance Cache The cache instance to use
---@param ttl? number Custom TTL in seconds (uses cache's DefaultTTL if nil)
---@return PipelineEntry entry Pipeline handler ready for Server:UseHandler()
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
