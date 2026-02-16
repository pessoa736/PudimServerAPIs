# Pudim Server

Create simple, lightweight and customizable HTTP servers

> [!WARNING]
> Experimental project. APIs may change without notice.

🇧🇷 [Leia em Português](README_PT-BR.MD)

## Table of Contents

- [About](#about)
- [Dependencies](#dependencies)
- [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Creating the Server](#creating-the-server)
  - [Creating Routes](#creating-routes)
  - [Starting the Server](#starting-the-server)
  - [Request Object](#request-object)
  - [Response Object](#response-object)
- [CORS](#cors)
- [Pipeline](#pipeline)
- [Cache](#cache)
- [Complete Example](#complete-example)
- [Examples](#examples)
- [Roadmap](#roadmap)
- [License](#license)
- [Contributing](#contributing)

## About

Pudim Server is a Lua library focused on providing simple APIs for creating web servers with a routing system. It's designed to accept HTTP requests, parse them, dispatch to a handler, and return a response.

This library is being designed based on what [Davi](https://github.com/pessoa736) understands about **servers**. He intends to expand the library into something more complex over time, while keeping the focus on simplicity, lightness, and customization.

## Dependencies

- Lua >= 5.4
- LuaSocket
- lua-cjson
- loglua

## Getting Started

### Installation

```sh
# Local installation
luarocks install PudimServer --local

# Global installation
sudo luarocks install PudimServer
```

### Creating the Server

```lua
local PudimServer = require("PudimServer")

local server = PudimServer:Create{
  ServiceName = "My Service",
  Port = 8080,
  Address = "localhost"
}
```

All fields are optional. Defaults: `ServiceName = "Pudim Server"`, `Port = 8080`, `Address = "localhost"`.

### Creating Routes

Route handlers receive `(req, res)` and must return `res:response(status, body, headers)`.

```lua
-- HTML page
server:Routes("/", function(req, res)
  if req.method == "GET" then
    return res:response(200, "<h1>Hello!</h1>", {["Content-Type"] = "text/html"})
  end
  return res:response(405, {error = "Method not allowed"})
end)

-- JSON API (tables are auto-encoded to JSON)
server:Routes("/api/users", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      {id = 1, name = "John"},
      {id = 2, name = "Mary"}
    })
  end

  if req.method == "POST" then
    return res:response(201, {msg = "User created!", data = req.body})
  end

  return res:response(405, {error = "Method not allowed"})
end)
```

### Starting the Server

```lua
server:Run()
```

### Request Object

| Property | Type | Description |
|----------|------|-------------|
| `method` | string | HTTP method (GET, POST, PUT, DELETE, etc) |
| `path` | string | Request path (e.g.: "/api/users") |
| `version` | string | HTTP version (e.g.: "HTTP/1.1") |
| `headers` | table | Request headers (keys in lowercase) |
| `body` | string | Request body |
| `query` | table<string, string\|string[]>? | Parsed query string |
| `params` | table<string, string>? | Dynamic route params |

### Response Object

`res:response(status, body, headers)`:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `status` | number | ✅ | HTTP status code (200, 404, 500, etc) |
| `body` | string/table | ✅ | Response body. Tables are auto-converted to JSON |
| `headers` | table | ❌ | Custom response headers |

## CORS

Enable CORS with `EnableCors()`. Preflight `OPTIONS` requests are handled automatically.

```lua
-- Allow all origins (defaults)
server:EnableCors()

-- Restricted configuration
server:EnableCors{
  AllowOrigins = {"https://myapp.com", "https://admin.myapp.com"},
  AllowMethods = {"GET", "POST"},
  AllowHeaders = "Content-Type, Authorization",
  AllowCredentials = true,
  ExposeHeaders = {"X-Total-Count"},
  MaxAge = 3600
}
```

| Option | Type | Default |
|--------|------|---------|
| `AllowOrigins` | string \| string[] | `"*"` |
| `AllowMethods` | string \| string[] | `"GET, POST, PUT, DELETE, PATCH, OPTIONS"` |
| `AllowHeaders` | string \| string[] | `"Content-Type, Authorization"` |
| `ExposeHeaders` | string \| string[] | `""` |
| `AllowCredentials` | boolean | `false` |
| `MaxAge` | number | `86400` |

## Pipeline

The pipeline system lets you add request/response handlers that run before your route handlers. Each handler receives `(req, res, next)` — call `next()` to continue or return early to short-circuit.

```lua
-- Request logger
server:UseHandler{
  name = "logger",
  Handler = function(req, res, next)
    print(req.method .. " " .. req.path)
    return next()
  end
}

-- Authentication (short-circuits on failure)
server:UseHandler{
  name = "auth",
  Handler = function(req, res, next)
    if req.path:find("^/api/protected") and not req.headers["authorization"] then
      return res:response(401, {error = "Unauthorized"})
    end
    return next()
  end
}

-- Response wrapper
server:UseHandler{
  name = "timer",
  Handler = function(req, res, next)
    local start = os.clock()
    local response = next()
    print(("Request took %.3fs"):format(os.clock() - start))
    return response
  end
}

-- Remove a handler
server:RemoveHandler("logger")
```

Handlers run in the order they are registered. The route handler runs last.

## Cache

In-memory response cache with TTL and automatic eviction. Only `GET` requests are cached.

```lua
local Cache = require("PudimServer.cache")

-- Create cache instance
local cache = Cache.new{
  MaxSize = 200,     -- max entries (default: 100)
  DefaultTTL = 120   -- seconds (default: 60)
}

-- Add to pipeline (easiest way)
server:UseHandler(Cache.createPipelineHandler(cache))

-- Or use manually in a route
server:Routes("/api/data", function(req, res)
  local cached = cache:get("my-key")
  if cached then return cached end

  local response = res:response(200, {data = "expensive computation"})
  cache:set("my-key", response, 30) -- custom TTL
  return response
end)

-- Invalidate entries
cache:invalidate("my-key")
cache:clear()
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `MaxSize` | number | `100` | Max entries before eviction |
| `DefaultTTL` | number | `60` | TTL in seconds |

## Complete Example

```lua
local PudimServer = require("PudimServer")
local Cache = require("PudimServer.cache")

local server = PudimServer:Create{
  ServiceName = "My API",
  Port = 3000,
  Address = "localhost"
}

-- Enable CORS
server:EnableCors()

-- Add request logger
server:UseHandler{
  name = "logger",
  Handler = function(req, res, next)
    print(("[%s] %s %s"):format(os.date("%H:%M:%S"), req.method, req.path))
    return next()
  end
}

-- Add cache (GET only, 30s TTL)
local cache = Cache.new{ DefaultTTL = 30 }
server:UseHandler(Cache.createPipelineHandler(cache))

-- Routes
server:Routes("/", function(req, res)
  if req.method == "GET" then
    return res:response(200, "<h1>Welcome!</h1>", {["Content-Type"] = "text/html"})
  end
  return res:response(405, {error = "Method not allowed"})
end)

server:Routes("/api/data", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      status = "ok",
      timestamp = os.time(),
      message = "API working!"
    })
  end
  return res:response(405, {error = "Method not allowed"})
end)

print("Server running at http://localhost:3000")
server:Run()
```

## Examples

Functional examples are available in the [`examples/`](examples/) directory:

| File | Description |
|------|-------------|
| [`json_response_example.lua`](examples/json_response_example.lua) | Auto JSON encoding for table responses |
| [`cors_example.lua`](examples/cors_example.lua) | CORS with default settings |
| [`cors_restricted_example.lua`](examples/cors_restricted_example.lua) | CORS with restricted origins and credentials |
| [`pipeline_example.lua`](examples/pipeline_example.lua) | Logger, auth and custom header pipeline handlers |
| [`cache_example.lua`](examples/cache_example.lua) | Pipeline cache and manual cache usage |
| [`query_dynamic_example.lua`](examples/query_dynamic_example.lua) | Query string parsing and dynamic route params |
| [`https_concurrency_example.lua`](examples/https_concurrency_example.lua) | Native HTTPS (luasec) with cooperative concurrency |
| [`hot_reload_example.lua`](examples/hot_reload_example.lua) | Development hot reload without file watcher |
| [`complete_featured_example.lua`](examples/complete_featured_example.lua) | Full setup with CORS, pipeline, cache, query, dynamic routes, hot reload, and optional HTTPS |

Run any example with:

```sh
lua ./examples/json_response_example.lua
```

## Roadmap

> [!NOTE]
> This project is in experimental phase. Check below what has been implemented and what is planned.

### ✅ Implemented

- [x] Basic routing system
- [x] HTTP request parsing (method, path, headers, body, query, params)
- [x] Automatic JSON responses (tables converted to JSON)
- [x] Configurable logging system
- [x] CORS helpers (Cross-Origin Resource Sharing)
- [x] Request/response pipeline (middleware at HTTP level)
- [x] In-memory response cache with TTL
- [x] Dynamic routes with parameters (`/users/:id`, `/posts/:slug`)
- [x] Automatic query string parsing (`?page=1&limit=10`)
- [x] More HTTP status codes mapped
- [x] Multi-threading / concurrency (cooperative coroutines)
- [x] Native HTTPS support (luasec)
- [x] Hot reload in development (without file watcher)

### 📋 Planned

- [ ] File upload support (multipart/form-data)
- [ ] Serve static files (HTML, CSS, JS, images)
- [ ] Basic rate limiting

### 🔮 Future (maybe)

- [ ] WebSocket support

### Hot Reload (no file watcher)

Enable hot reload by invalidating selected Lua modules from `package.loaded` on each request.

```lua
local server = PudimServer:Create{
  Port = 8080,
  HotReload = {
    Enabled = true,
    Modules = {"examples.hot_reload_message"},
    Prefixes = {"app."}
  }
}
```

Use `Modules` for exact module names and `Prefixes` to invalidate groups. This is for development only.

## License

This project is under the MIT license. See the [LICENSE](LICENSE) file for more details.

## Contributing

Contributions are welcome! See the complete guide at [CONTRIBUTING.md](CONTRIBUTING.md).

---

Made with ❤️ by [Davi](https://github.com/pessoa736)
