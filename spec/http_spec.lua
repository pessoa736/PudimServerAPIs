describe("http", function()
  local http

  setup(function()
    _G.log = require("loglua")
    _G.cjson = require("cjson.safe")
    http = require("PudimServer.http")
  end)

  describe("ParseRequest", function()
    it("parses a simple GET request", function()
      local raw = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"
      local req = http:ParseRequest(raw)
      assert.are.equal("GET", req.method)
      assert.are.equal("/", req.path)
      assert.are.equal("HTTP/1.1", req.version)
      assert.are.equal("localhost", req.headers["host"])
    end)

    it("parses a POST request with headers", function()
      local raw = "POST /api/users HTTP/1.1\r\n" ..
        "Content-Type: application/json\r\n" ..
        "Content-Length: 16\r\n\r\n"
      local req = http:ParseRequest(raw)
      assert.are.equal("POST", req.method)
      assert.are.equal("/api/users", req.path)
      assert.are.equal("application/json", req.headers["content-type"])
      assert.are.equal("16", req.headers["content-length"])
    end)

    it("parses multiple headers", function()
      local raw = "GET /test HTTP/1.1\r\n" ..
        "Host: example.com\r\n" ..
        "Accept: text/html\r\n" ..
        "User-Agent: test\r\n\r\n"
      local req = http:ParseRequest(raw)
      assert.are.equal("example.com", req.headers["host"])
      assert.are.equal("text/html", req.headers["accept"])
      assert.are.equal("test", req.headers["user-agent"])
    end)

    it("handles different HTTP methods", function()
      for _, method in ipairs({"GET", "POST", "PUT", "DELETE", "PATCH"}) do
        local raw = method .. " /resource HTTP/1.1\r\nHost: localhost\r\n\r\n"
        local req = http:ParseRequest(raw)
        assert.are.equal(method, req.method)
      end
    end)
  end)

  describe("response", function()
    it("builds a 200 OK response", function()
      local res = http:response(200, "Hello", {["Content-Type"] = "text/plain"})
      assert.is_truthy(res:find("HTTP/1.1 200 OK"))
      assert.is_truthy(res:find("Hello"))
      assert.is_truthy(res:find("Content%-Type: text/plain"))
    end)

    it("builds a 404 response", function()
      local res = http:response(404, "Not Found")
      assert.is_truthy(res:find("HTTP/1.1 404 Not Found"))
    end)

    it("sets Content-Length header", function()
      local body = "test body"
      local res = http:response(200, body)
      assert.is_truthy(res:find("Content%-Length: " .. #body))
    end)

    it("handles empty body", function()
      local res = http:response(200, "")
      assert.is_truthy(res:find("Content%-Length: 0"))
    end)

    it("builds response with explicit JSON Content-Type", function()
      local body = '{"msg":"hello"}'
      local res = http:response(200, body, {["Content-Type"] = "application/json"})
      assert.is_string(res)
      assert.is_truthy(res:find("HTTP/1.1 200 OK"))
      assert.is_truthy(res:find("application/json"))
      assert.is_truthy(res:find(body, 1, true))
    end)

    it("auto-encodes table body as JSON", function()
      local res = http:response(200, {msg = "hello"})
      assert.is_string(res)
      assert.is_truthy(res:find("HTTP/1.1 200 OK"))
      assert.is_truthy(res:find("application/json"))
      assert.is_truthy(res:find("hello"))
    end)

    it("preserves explicit Content-Type when body is a table", function()
      local res = http:response(200, {data = 1}, {["Content-Type"] = "text/plain"})
      assert.is_truthy(res:find("text/plain"))
    end)

    it("includes custom headers", function()
      local res = http:response(200, "ok", {
        ["X-Custom"] = "value",
        ["Content-Type"] = "text/plain"
      })
      assert.is_truthy(res:find("X%-Custom: value"))
    end)
  end)
end)
