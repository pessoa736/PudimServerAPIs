if not _G.log then _G.log = require("loglua") end

local helpModule = require("PudimServer.help")

describe("PudimServer.help", function()

  describe("version", function()
    it("returns a version string", function()
      local v = helpModule.version()
      assert.is_string(v)
      assert.truthy(v:match("%d+%.%d+%.%d+"))
    end)
  end)

  describe("topics", function()
    it("returns a table of topic names", function()
      local t = helpModule.topics()
      assert.is_table(t)
      assert.is_true(#t > 0)
    end)

    it("includes core topics", function()
      local t = helpModule.topics()
      local set = {}
      for _, name in ipairs(t) do set[name] = true end

      assert.is_true(set["create"])
      assert.is_true(set["routes"])
      assert.is_true(set["run"])
      assert.is_true(set["response"])
      assert.is_true(set["cors"])
      assert.is_true(set["pipeline"])
      assert.is_true(set["cache"])
      assert.is_true(set["middlewares"])
      assert.is_true(set["types"])
      assert.is_true(set["modules"])
    end)
  end)

  describe("show", function()
    it("runs without error when called with no topic", function()
      assert.has_no.errors(function()
        helpModule.show()
      end)
    end)

    it("runs without error for each topic", function()
      local topics = helpModule.topics()
      for _, topic in ipairs(topics) do
        assert.has_no.errors(function()
          helpModule.show(topic)
        end)
      end
    end)

    it("handles unknown topic without error", function()
      assert.has_no.errors(function()
        helpModule.show("nonexistent_topic")
      end)
    end)
  end)

  describe("welcome", function()
    it("returns false when flag file exists", function()
      -- The flag file was already created by previous test runs
      local f = io.open(".pudimserver_initialized", "w")
      if f then f:write("test") f:close() end

      local result = helpModule.welcome()
      assert.is_false(result)
    end)

    it("returns true on first run (no flag file)", function()
      os.remove(".pudimserver_initialized")
      local result = helpModule.welcome()
      assert.is_true(result)
      -- Clean up
      assert.is_true(require("PudimServer.utils"):checkFilesExist(".pudimserver_initialized"))
    end)
  end)

end)
