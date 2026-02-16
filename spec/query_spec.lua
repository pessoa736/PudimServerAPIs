describe("http query parsing", function()
  local http

  setup(function()
    -- prefer local repo modules during tests
    package.path = "./PudimServer/?.lua;./PudimServer/?/init.lua;" .. package.path
    _G.log = require("loglua")
    _G.cjson = require("cjson.safe")
    http = require("PudimServer.http")
  end)

  it("parses query string into req.query with repeated keys as arrays", function()
    local raw = "GET /search?q=hello&page=2&tag=lua&tag=testing HTTP/1.1\r\nHost: localhost\r\n\r\n"
    local req = http:ParseRequest(raw)
    assert.is_table(req.query)
    assert.are.equal("hello", req.query["q"]) 
    assert.are.equal("2", req.query["page"]) 
    assert.is_table(req.query["tag"]) 
    assert.are.equal("lua", req.query["tag"][1])
    assert.are.equal("testing", req.query["tag"][2])
  end)
end)
