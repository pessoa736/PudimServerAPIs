--- Cache Example
--- Run: lua ./examples/cache_example.lua
--- Test: curl http://localhost:8085/api/time    (note the timestamp)
--- Test: curl http://localhost:8085/api/time    (same timestamp = cached!)
--- Test: curl -X POST http://localhost:8085/api/data  (POST not cached)

local PudimServer = require("PudimServer")
local Cache = require("PudimServer.cache")

local server = PudimServer:Create{
  Port = 8085,
  Address = "localhost",
  ServiceName = "Cache Example",
  Middlewares = {}
}


-- Create cache: max 50 entries, 10 second TTL
local cache = Cache.new{
  MaxSize = 50,
  DefaultTTL = 10
}


-- Add cache as pipeline handler (only caches GET requests)
server:UseHandler(Cache.createPipelineHandler(cache))


-- Pipeline handler: logger to show cache hits
server:UseHandler{
  name = "logger",
  Handler = function(req, res, next)
    print(("[%s] %s %s"):format(os.date("%H:%M:%S"), req.method, req.path))
    return next()
  end
}


-- This route returns the current timestamp
-- On first call: handler runs, response is cached for 10s
-- On subsequent calls within 10s: cached response returned (same timestamp)
server:Routes("/api/time", function(req, res)
  if req.method == "GET" then
    print("  -> handler executed (not from cache)")
    return res:Response(200, {
      timestamp = os.time(),
      msg = "If this timestamp stays the same, the response is cached!"
    })
  end
  return res:Response(405, { error = "Method not allowed" })
end)


-- POST requests are never cached
server:Routes("/api/data", function(req, res)
  if req.method == "POST" then
    return res:Response(200, {
      msg = "POST is never cached",
      timestamp = os.time()
    })
  end
  return res:Response(405, { error = "Method not allowed" })
end)


-- You can also use the cache directly for manual control
server:Routes("/api/cached-manual", function(req, res)
  if req.method == "GET" then
    local key = "manual:greeting"
    local cached = cache:get(key)

    if cached then
      return cached
    end

    local response = res:Response(200, {
      msg = "Manually cached for 30 seconds",
      timestamp = os.time()
    })

    cache:set(key, response, 30)
    return response
  end

  -- Invalidate cache on DELETE
  if req.method == "DELETE" then
    cache:invalidate("manual:greeting")
    return res:Response(200, { msg = "Cache invalidated!" })
  end

  return res:Response(405, { error = "Method not allowed" })
end)


print("=== Cache Example running at http://localhost:8085 ===")
print("Try: curl http://localhost:8085/api/time          (note timestamp)")
print("Try: curl http://localhost:8085/api/time          (same timestamp = cached)")
print("     Wait 10s, try again                          (new timestamp = expired)")
print("Try: curl -X POST http://localhost:8085/api/data  (POST never cached)")
print("Try: curl http://localhost:8085/api/cached-manual (manual cache, 30s TTL)")
server:Run()
