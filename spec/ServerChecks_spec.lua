describe("ServerChecks", function()
  local ServerChecks
  local socket

  setup(function()
    _G.log = require("loglua")
    socket = require("socket")
    ServerChecks = require("PudimServer.ServerChecks")
  end)

  describe("is_Port_Open", function()
    it("detects a closed port", function()
      -- Port 19999 should not be in use
      local isOpen, msg = ServerChecks.is_Port_Open("localhost", 19999)
      assert.is_false(isOpen)
      assert.is_string(msg)
    end)

    it("detects an open port", function()
      -- Bind a temporary server to test
      local server = socket.bind("localhost", 18888)
      assert.is_truthy(server)

      local isOpen, msg = ServerChecks.is_Port_Open("localhost", 18888)
      assert.is_true(isOpen)
      assert.is_truthy(msg:find("open"))

      server:close()
    end)

    it("returns a descriptive message", function()
      local _, msg = ServerChecks.is_Port_Open("localhost", 19998)
      assert.is_string(msg)
      assert.is_truthy(#msg > 0)
    end)
  end)
end)
