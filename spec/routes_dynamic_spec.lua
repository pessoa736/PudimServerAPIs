describe("PudimServer Routes dynamic", function()
  local PudimServer

  setup(function()
    -- prefer local repo modules during tests
    package.path = "./PudimServer/?.lua;./PudimServer/?/init.lua;" .. package.path
    _G.log = require("loglua")
    _G.cjson = require("cjson.safe")
    PudimServer = require("PudimServer")
  end)

  it("stores dynamic route entry with pattern and paramNames", function()
    local server = setmetatable({}, PudimServer)
    server:Routes("/users/:id/posts/:postId", function() end)
    assert.is_table(server._routes)
    local entry = server._routes[1]
    assert.is_true(entry.dynamic)
    assert.are.same({"id","postId"}, entry.paramNames)
    local caps = { string.match("/users/123/posts/456", entry.pattern) }
    assert.are.equal("123", caps[1])
    assert.are.equal("456", caps[2])
  end)

  it("keeps static routes available alongside dynamic ones", function()
    local server = setmetatable({}, PudimServer)
    server:Routes("/resource", function() end)
    server:Routes("/resource/:id", function() end)
    local foundStatic = false
    for _, e in ipairs(server._routes) do
      if not e.dynamic and e.path == "/resource" then foundStatic = true end
    end
    assert.is_true(foundStatic)
  end)
end)
