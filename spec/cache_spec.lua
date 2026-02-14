describe("cache", function()
  local Cache
  local socket

  setup(function()
    _G.log = require("loglua")
    _G.cjson = require("cjson.safe")
    socket = require("socket")
    Cache = require("PudimServer.cache")
  end)

  describe("new", function()
    it("creates cache with defaults", function()
      local c = Cache.new()
      assert.are.equal(100, c._maxSize)
      assert.are.equal(60, c._defaultTTL)
      assert.are.equal(0, c._size)
    end)

    it("accepts custom config", function()
      local c = Cache.new{ MaxSize = 50, DefaultTTL = 30 }
      assert.are.equal(50, c._maxSize)
      assert.are.equal(30, c._defaultTTL)
    end)
  end)

  describe("get/set", function()
    it("stores and retrieves a value", function()
      local c = Cache.new()
      c:set("key1", "response1")
      assert.are.equal("response1", c:get("key1"))
    end)

    it("returns nil for missing key", function()
      local c = Cache.new()
      assert.is_nil(c:get("nonexistent"))
    end)

    it("increments size on new entry", function()
      local c = Cache.new()
      c:set("k1", "v1")
      c:set("k2", "v2")
      assert.are.equal(2, c._size)
    end)

    it("does not increment size on update", function()
      local c = Cache.new()
      c:set("k1", "v1")
      c:set("k1", "v2")
      assert.are.equal(1, c._size)
      assert.are.equal("v2", c:get("k1"))
    end)

    it("expires entries after TTL", function()
      local c = Cache.new{ DefaultTTL = 0.1 }
      c:set("key", "value")
      assert.are.equal("value", c:get("key"))

      -- Wait for expiration
      socket.sleep(0.15)
      assert.is_nil(c:get("key"))
    end)

    it("supports custom TTL per entry", function()
      local c = Cache.new{ DefaultTTL = 10 }
      c:set("short", "value", 0.1)
      assert.are.equal("value", c:get("short"))

      socket.sleep(0.15)
      assert.is_nil(c:get("short"))
    end)
  end)

  describe("invalidate", function()
    it("removes a specific entry", function()
      local c = Cache.new()
      c:set("k1", "v1")
      c:set("k2", "v2")
      c:invalidate("k1")
      assert.is_nil(c:get("k1"))
      assert.are.equal("v2", c:get("k2"))
      assert.are.equal(1, c._size)
    end)

    it("does nothing for missing key", function()
      local c = Cache.new()
      c:invalidate("nonexistent")
      assert.are.equal(0, c._size)
    end)
  end)

  describe("clear", function()
    it("removes all entries", function()
      local c = Cache.new()
      c:set("k1", "v1")
      c:set("k2", "v2")
      c:clear()
      assert.is_nil(c:get("k1"))
      assert.is_nil(c:get("k2"))
      assert.are.equal(0, c._size)
    end)
  end)

  describe("eviction", function()
    it("evicts oldest when full", function()
      local c = Cache.new{ MaxSize = 2, DefaultTTL = 100 }
      c:set("k1", "v1")
      socket.sleep(0.01)
      c:set("k2", "v2")
      socket.sleep(0.01)
      c:set("k3", "v3")
      -- k1 should be evicted (oldest expiry)
      assert.is_nil(c:get("k1"))
      assert.are.equal("v2", c:get("k2"))
      assert.are.equal("v3", c:get("k3"))
      assert.are.equal(2, c._size)
    end)
  end)

  describe("createPipelineHandler", function()
    it("creates a valid pipeline entry", function()
      local c = Cache.new()
      local handler = Cache.createPipelineHandler(c)
      assert.are.equal("cache", handler.name)
      assert.is_function(handler.Handler)
    end)

    it("caches GET responses", function()
      local c = Cache.new()
      local handler = Cache.createPipelineHandler(c)
      local callCount = 0

      local req = { method = "GET", path = "/test" }
      local function next()
        callCount = callCount + 1
        return "response-" .. callCount
      end

      -- First call: miss
      local r1 = handler.Handler(req, {}, next)
      assert.are.equal("response-1", r1)
      assert.are.equal(1, callCount)

      -- Second call: hit
      local r2 = handler.Handler(req, {}, next)
      assert.are.equal("response-1", r2)
      assert.are.equal(1, callCount)
    end)

    it("does not cache non-GET requests", function()
      local c = Cache.new()
      local handler = Cache.createPipelineHandler(c)
      local callCount = 0

      local req = { method = "POST", path = "/test" }
      local function next()
        callCount = callCount + 1
        return "response-" .. callCount
      end

      handler.Handler(req, {}, next)
      handler.Handler(req, {}, next)
      assert.are.equal(2, callCount)
    end)
  end)
end)
