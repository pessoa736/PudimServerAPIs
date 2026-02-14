describe("cors", function()
  local cors

  setup(function()
    _G.log = require("loglua")
    _G.cjson = require("cjson.safe")
    cors = require("PudimServer.cors")
  end)

  describe("createConfig", function()
    it("returns defaults when no config provided", function()
      local config = cors.createConfig()
      assert.are.equal("*", config.AllowOrigins)
      assert.is_truthy(config.AllowMethods:find("GET"))
      assert.is_truthy(config.AllowMethods:find("POST"))
      assert.is_truthy(config.AllowHeaders:find("Content%-Type"))
      assert.is_false(config.AllowCredentials)
      assert.are.equal(86400, config.MaxAge)
    end)

    it("accepts custom origin string", function()
      local config = cors.createConfig{ AllowOrigins = "https://example.com" }
      assert.are.equal("https://example.com", config.AllowOrigins)
    end)

    it("accepts origin as table", function()
      local config = cors.createConfig{
        AllowOrigins = {"https://a.com", "https://b.com"}
      }
      assert.are.equal("https://a.com, https://b.com", config.AllowOrigins)
    end)

    it("accepts custom methods", function()
      local config = cors.createConfig{ AllowMethods = {"GET", "POST"} }
      assert.are.equal("GET, POST", config.AllowMethods)
    end)

    it("accepts custom headers", function()
      local config = cors.createConfig{ AllowHeaders = "X-Custom" }
      assert.are.equal("X-Custom", config.AllowHeaders)
    end)

    it("enables credentials", function()
      local config = cors.createConfig{ AllowCredentials = true }
      assert.is_true(config.AllowCredentials)
    end)

    it("accepts custom MaxAge", function()
      local config = cors.createConfig{ MaxAge = 3600 }
      assert.are.equal(3600, config.MaxAge)
    end)

    it("accepts ExposeHeaders", function()
      local config = cors.createConfig{ ExposeHeaders = {"X-Total", "X-Page"} }
      assert.are.equal("X-Total, X-Page", config.ExposeHeaders)
    end)
  end)

  describe("buildHeaders", function()
    it("builds headers from default config", function()
      local config = cors.createConfig()
      local headers = cors.buildHeaders(config)
      assert.are.equal("*", headers["Access-Control-Allow-Origin"])
      assert.is_truthy(headers["Access-Control-Allow-Methods"])
      assert.is_truthy(headers["Access-Control-Allow-Headers"])
      assert.are.equal("86400", headers["Access-Control-Max-Age"])
    end)

    it("omits Expose-Headers when empty", function()
      local config = cors.createConfig()
      local headers = cors.buildHeaders(config)
      assert.is_nil(headers["Access-Control-Expose-Headers"])
    end)

    it("includes Expose-Headers when set", function()
      local config = cors.createConfig{ ExposeHeaders = "X-Total" }
      local headers = cors.buildHeaders(config)
      assert.are.equal("X-Total", headers["Access-Control-Expose-Headers"])
    end)

    it("includes Credentials when enabled", function()
      local config = cors.createConfig{ AllowCredentials = true }
      local headers = cors.buildHeaders(config)
      assert.are.equal("true", headers["Access-Control-Allow-Credentials"])
    end)

    it("omits Credentials when disabled", function()
      local config = cors.createConfig{ AllowCredentials = false }
      local headers = cors.buildHeaders(config)
      assert.is_nil(headers["Access-Control-Allow-Credentials"])
    end)
  end)

  describe("preflightResponse", function()
    it("returns a 204 response", function()
      local config = cors.createConfig()
      local response = cors.preflightResponse(config)
      assert.is_string(response)
      assert.is_truthy(response:find("204"))
    end)

    it("includes CORS headers in preflight", function()
      local config = cors.createConfig{ AllowOrigins = "https://example.com" }
      local response = cors.preflightResponse(config)
      assert.is_truthy(response:find("Access%-Control%-Allow%-Origin: https://example.com"))
      assert.is_truthy(response:find("Access%-Control%-Allow%-Methods"))
    end)

    it("has empty body", function()
      local config = cors.createConfig()
      local response = cors.preflightResponse(config)
      assert.is_truthy(response:find("Content%-Length: 0"))
    end)
  end)
end)
