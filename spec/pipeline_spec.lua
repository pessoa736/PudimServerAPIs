describe("pipeline", function()
  local Pipeline

  setup(function()
    _G.log = require("loglua")
    Pipeline = require("PudimServer.pipeline")
  end)

  describe("new", function()
    it("creates an empty pipeline", function()
      local p = Pipeline.new()
      assert.is_table(p._handlers)
      assert.are.equal(0, #p._handlers)
    end)
  end)

  describe("use", function()
    it("adds a handler to the pipeline", function()
      local p = Pipeline.new()
      p:use{ name = "test", Handler = function() end }
      assert.are.equal(1, #p._handlers)
      assert.are.equal("test", p._handlers[1].name)
    end)

    it("adds multiple handlers in order", function()
      local p = Pipeline.new()
      p:use{ name = "first", Handler = function() end }
      p:use{ name = "second", Handler = function() end }
      assert.are.equal(2, #p._handlers)
      assert.are.equal("first", p._handlers[1].name)
      assert.are.equal("second", p._handlers[2].name)
    end)
  end)

  describe("remove", function()
    it("removes a handler by name", function()
      local p = Pipeline.new()
      p:use{ name = "keep", Handler = function() end }
      p:use{ name = "remove-me", Handler = function() end }
      local ok = p:remove("remove-me")
      assert.is_true(ok)
      assert.are.equal(1, #p._handlers)
      assert.are.equal("keep", p._handlers[1].name)
    end)

    it("returns false when handler not found", function()
      local p = Pipeline.new()
      local ok = p:remove("nonexistent")
      assert.is_false(ok)
    end)
  end)

  describe("execute", function()
    it("runs final handler when pipeline is empty", function()
      local p = Pipeline.new()
      local req = { method = "GET", path = "/" }
      local res = {}
      local result = p:execute(req, res, function()
        return "final"
      end)
      assert.are.equal("final", result)
    end)

    it("runs handlers in order before final", function()
      local p = Pipeline.new()
      local order = {}

      p:use{
        name = "first",
        Handler = function(req, res, next)
          table.insert(order, "first")
          return next()
        end
      }

      p:use{
        name = "second",
        Handler = function(req, res, next)
          table.insert(order, "second")
          return next()
        end
      }

      local req = { method = "GET", path = "/" }
      local result = p:execute(req, {}, function()
        table.insert(order, "final")
        return "done"
      end)

      assert.are.equal("done", result)
      assert.are.same({"first", "second", "final"}, order)
    end)

    it("allows handler to short-circuit the pipeline", function()
      local p = Pipeline.new()
      local finalCalled = false

      p:use{
        name = "blocker",
        Handler = function(req, res, next)
          return "blocked"
        end
      }

      local result = p:execute({}, {}, function()
        finalCalled = true
        return "should not reach"
      end)

      assert.are.equal("blocked", result)
      assert.is_false(finalCalled)
    end)

    it("passes req and res to handlers", function()
      local p = Pipeline.new()
      local capturedReq, capturedRes

      p:use{
        name = "capture",
        Handler = function(req, res, next)
          capturedReq = req
          capturedRes = res
          return next()
        end
      }

      local req = { method = "POST", path = "/api" }
      local res = { test = true }
      p:execute(req, res, function() return "ok" end)

      assert.are.equal("POST", capturedReq.method)
      assert.is_true(capturedRes.test)
    end)

    it("allows handler to modify request", function()
      local p = Pipeline.new()

      p:use{
        name = "modifier",
        Handler = function(req, res, next)
          req.customField = "added"
          return next()
        end
      }

      local req = { method = "GET", path = "/" }
      local capturedReq

      p:execute(req, {}, function(r)
        capturedReq = r
        return "ok"
      end)

      assert.are.equal("added", capturedReq.customField)
    end)

    it("allows handler to wrap response", function()
      local p = Pipeline.new()

      p:use{
        name = "wrapper",
        Handler = function(req, res, next)
          local response = next()
          return "wrapped:" .. response
        end
      }

      local result = p:execute({}, {}, function()
        return "original"
      end)

      assert.are.equal("wrapped:original", result)
    end)
  end)
end)
