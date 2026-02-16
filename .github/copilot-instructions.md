# Copilot Instructions for PudimServer

## Project Overview

PudimServer is a Lua HTTP server library distributed via LuaRocks. It provides a routing system, CORS support, a request/response pipeline (middleware chain), and in-memory caching.

## Dependencies & Runtime

- **Lua >= 5.4** (`.luarc.json` targets Lua 5.4)
- **LuaRocks** for package management
- Core deps: `luasocket`, `lua-cjson`, `loglua`, `luasec` (optional, for SSL)

Install dependencies:

```sh
luarocks install luasocket --local
luarocks install lua-cjson --local
luarocks install loglua --local
```

## Running Tests

Unit tests use [busted](https://lunarmodules.github.io/busted/). Tests live in `spec/`.

```sh
# Run all tests
./lua_modules/bin/busted --no-auto-insulate spec/

# Run a single test file
./lua_modules/bin/busted --no-auto-insulate spec/utils_spec.lua

# Run tests matching a pattern
./lua_modules/bin/busted --no-auto-insulate spec/ --filter "ParseRequest"
```

**Note:** `--no-auto-insulate` is required because modules share global state (`_G.log`, `_G.cjson`).

## Complete API Reference

### PudimServer (init.lua) — Main Server

```lua
local PudimServer = require("PudimServer")
```

#### `PudimServer:Create(config?) → Server`

Creates a new server instance bound to an address and port.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.ServiceName` | `string?` | `"Pudim Server"` | Service name for logging |
| `config.Address` | `string?` | `"localhost"` | Bind address (`"localhost"`, `"127.0.0.1"`, `"0.0.0.0"`) |
| `config.Port` | `number?` | `8080` | Port number |
| `config.Middlewares` | `table?` | `{}` | Initial socket-level middlewares |
| `config.Https` | `table?` | `nil` | Native HTTPS config (`luasec`) |
| `config.Concurrency` | `table?` | `nil` | Cooperative concurrency config |
| `config.HotReload` | `table?` | `nil` | Dev hot reload without file watcher |

```lua
local server = PudimServer:Create{
  ServiceName = "My API",
  Address = "0.0.0.0",
  Port = 3000
}
```

#### `Server:Routes(path, handler)`

Registers an HTTP route. Handler receives `(req, res)` and must return `res:response(...)`.

```lua
server:Routes("/api/users", function(req, res)
  if req.method == "GET" then
    return res:response(200, {users = {"Alice", "Bob"}})
  end
  return res:response(405, "Method Not Allowed")
end)
```

#### `Server:EnableCors(config?)`

Enables CORS. Handles OPTIONS preflight automatically and injects headers.

```lua
-- Allow all origins
server:EnableCors()

-- Restricted
server:EnableCors{
  AllowOrigins = {"https://mysite.com"},
  AllowMethods = "GET, POST",
  AllowCredentials = true
}
```

#### `Server:UseHandler(entry)`

Adds a handler to the HTTP-level pipeline. Handlers run before route matching.

```lua
server:UseHandler{
  name = "auth",
  Handler = function(req, res, next)
    if not req.headers["authorization"] then
      return res:response(401, "Unauthorized")
    end
    return next()  -- continue pipeline
  end
}
```

#### `Server:RemoveHandler(name) → boolean`

Removes a pipeline handler by name.

#### `Server:SetMiddlewares(middleware)`

Adds a socket-level middleware (runs on raw TCP, before HTTP parsing).

```lua
server:SetMiddlewares{
  name = "ssl",
  Handler = function(client)
    return ssl.wrap(client, sslParams)
  end
}
```

#### `Server:RemoveMiddlewares(name)`

Removes a socket middleware by name.

#### `Server:Run()`

Starts the server (blocks). Place all setup before calling.

#### `Server:EnableHotReload(config?)`

Enables development hot reload **without file watcher** by invalidating selected modules in `package.loaded` before each request.

```lua
server:EnableHotReload{
  Enabled = true,
  Modules = {"examples.hot_reload_message"},
  Prefixes = {"app."}
}
```

### PudimServer.http (http.lua) — HTTP Parsing & Response

```lua
local http = require("PudimServer.http")
```

#### `http:ParseRequest(raw) → Request`

Parses raw HTTP string into `{method, path, version, headers, body}`.

#### `http:response(status, body, headers?) → string`

Builds HTTP response string. Tables as body auto-encode to JSON.

```lua
-- Plain text
http:response(200, "Hello!")

-- JSON auto-encoding
http:response(200, {name = "Pudim"})

-- Custom headers
http:response(200, "<h1>Hi</h1>", {["Content-Type"] = "text/html"})
```

### Request Object

| Field | Type | Description |
|---|---|---|
| `method` | `string` | HTTP method (GET, POST, PUT, DELETE, etc) |
| `path` | `string` | Request path (e.g. "/api/users") |
| `version` | `string` | HTTP version (e.g. "HTTP/1.1") |
| `headers` | `table<string,string>` | Request headers (keys are lowercase) |
| `body` | `string` | Request body |
| `query` | `table<string, string\|string[]>?` | Parsed query string |
| `params` | `table<string, string>?` | Dynamic route params |

### PudimServer.cors (cors.lua) — CORS Support

```lua
local cors = require("PudimServer.cors")
```

#### `cors.createConfig(config?) → table`

Creates resolved CORS config with defaults.

#### `cors.buildHeaders(config, requestOrigin?) → table`

Builds CORS response headers from resolved config.

#### `cors.preflightResponse(config) → string`

Returns 204 HTTP response for OPTIONS preflight.

**CorsConfig options:**

| Field | Type | Default |
|---|---|---|
| `AllowOrigins` | `string\|string[]` | `"*"` |
| `AllowMethods` | `string\|string[]` | `"GET, POST, PUT, DELETE, PATCH, OPTIONS"` |
| `AllowHeaders` | `string\|string[]` | `"Content-Type, Authorization"` |
| `ExposeHeaders` | `string\|string[]` | `""` |
| `AllowCredentials` | `boolean` | `false` |
| `MaxAge` | `number` | `86400` |

### PudimServer.pipeline (pipeline.lua) — Request Pipeline

```lua
local Pipeline = require("PudimServer.pipeline")
```

#### `Pipeline.new() → Pipeline`

Creates new pipeline.

#### `Pipeline:use(entry)`

Adds handler. Entry: `{name = "string", Handler = function(req, res, next) ... end}`.

#### `Pipeline:remove(name) → boolean`

Removes handler by name.

#### `Pipeline:execute(req, res, finalHandler) → string?`

Executes handler chain. Each handler calls `next()` to continue or returns response to short-circuit.

### PudimServer.cache (cache.lua) — Response Cache

```lua
local Cache = require("PudimServer.cache")
```

#### `Cache.new(config?) → Cache`

Creates cache. Options: `MaxSize` (default 100), `DefaultTTL` (default 60s).

#### `Cache:get(key) → string?`

Get cached response (nil if expired/missing).

#### `Cache:set(key, response, ttl?)`

Store response with optional TTL.

#### `Cache:invalidate(key)`

Remove single entry.

#### `Cache:clear()`

Remove all entries.

#### `Cache.createPipelineHandler(cache, ttl?) → PipelineEntry`

Returns pipeline handler that caches GET responses. Key format: `"GET:/path"`.

```lua
local cache = Cache.new{ MaxSize = 50, DefaultTTL = 30 }
server:UseHandler(Cache.createPipelineHandler(cache))
```

### PudimServer.utils (utils.lua) — Utilities

```lua
local utils = require("PudimServer.utils")
```

#### `utils:createInterface(fields, extends?) → Interface`

Creates runtime type contract. Fields map names to type strings or arrays of types.

```lua
local UserInter = utils:createInterface{
  name = "string",
  age = "number",
  email = {"string", "nil"}  -- optional
}
```

#### `utils:verifyTypes(value, contract, printerFn?, break?) → boolean, string?`

Validates value against interface. Returns `(true)` or `(false, errorMsg)`.

#### `utils:loadMessageOnChange(channel, msg, printerFn)`

Prints message only when changed from last call on same channel.

#### `utils:checkFilesExist(file) → boolean`

#### `utils:getContentFile(file) → string`

#### `utils:writeFile(file, content)`

#### `utils:mkdir(path)`

### PudimServer.ServerChecks (ServerChecks.lua)

#### `ServerChecks.is_Port_Open(address, port) → boolean, string`

Checks if TCP port is open.

## Architecture

### Module Dependency Graph

```
init.lua ──→ http.lua
         ──→ cors.lua ──→ http.lua
         ──→ pipeline.lua
         ──→ utils.lua
         ──→ socket (luasocket)

http.lua ──→ utils.lua
         ──→ cjson (lua-cjson)

cache.lua ──→ utils.lua
          ──→ socket (luasocket)

ServerChecks.lua ──→ utils.lua
                 ──→ socket (luasocket)
```

### Request Flow in Server:Run()

1. `socket:accept()` → raw TCP client
2. Socket middlewares run sequentially (`SetMiddlewares`)
3. Optional hot reload invalidates configured modules (`EnableHotReload`/`config.HotReload`)
4. `client:receive()` → raw HTTP data
5. `http:ParseRequest(raw)` → `Request` object
6. CORS preflight check → 204 if OPTIONS
7. `pipeline:execute(req, res, routeHandler)` → runs pipeline handlers, then route
8. CORS header injection into response
9. `client:send(response)` → send to client

### Runtime Type System

All public functions validate parameters using `utils:createInterface` + `utils:verifyTypes`. New code **must** follow this pattern:

```lua
local MyInterface = utils:createInterface{
  fieldName = "string",
  optionalField = {"number", "nil"}
}

function myModule:myFunction(params)
  utils:verifyTypes(params, MyInterface, log.error, true)
  -- ...
end
```

### Globals

- `_G.log` — `loglua` logger (auto-initialized on first `require`)
- `_G.cjson` — `cjson.safe` (auto-initialized on first `require`)

## Code Conventions

- **Indentation:** 2 spaces
- **Naming:** `camelCase` for variables/functions, `PascalCase` for classes/modules
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`)
- **PR target:** Always target the `dev` branch
- **LuaDoc annotations:** Use `---@class`, `---@field`, `---@type`, `---@param`, `---@return` annotations
- **LuaDoc concrete tables:** when declaring methods as `function myTable:method(...)`, declare `---@class myTable` and type the table as `---@type myTable` to avoid “Fields cannot be injected...” diagnostics
- **Comments:** Portuguese or English are both acceptable
- **Type validation:** All public API functions must validate inputs with `utils:verifyTypes`
- **Logging:** Use `log.inSection("name")` for scoped loggers

## LuaRocks Module Map

```
PudimServer              → PudimServer/init.lua
PudimServer.http         → PudimServer/http.lua
PudimServer.utils        → PudimServer/utils.lua
PudimServer.cors         → PudimServer/cors.lua
PudimServer.pipeline     → PudimServer/pipeline.lua
PudimServer.cache        → PudimServer/cache.lua
PudimServer.ServerChecks → PudimServer/ServerChecks.lua
```

New modules must be added to the `modules` table in the rockspec.

## Common Patterns

### Creating a basic server

```lua
local PudimServer = require("PudimServer")

local server = PudimServer:Create{ Port = 8080 }

server:Routes("/", function(req, res)
  return res:response(200, "Hello World!")
end)

server:Run()
```

### Adding CORS + Pipeline + Cache

```lua
local PudimServer = require("PudimServer")
local Cache = require("PudimServer.cache")

local server = PudimServer:Create{ Port = 8080 }
server:EnableCors()

-- Pipeline: logging middleware
server:UseHandler{
  name = "logger",
  Handler = function(req, res, next)
    print(req.method .. " " .. req.path)
    return next()
  end
}

-- Cache GET responses for 30 seconds
local cache = Cache.new{ DefaultTTL = 30 }
server:UseHandler(Cache.createPipelineHandler(cache))

server:Routes("/api/data", function(req, res)
  return res:response(200, {timestamp = os.time()})
end)

server:Run()
```

### Adding Hot Reload (no file watcher)

```lua
local PudimServer = require("PudimServer")

local server = PudimServer:Create{
  Port = 8080,
  HotReload = {
    Enabled = true,
    Modules = {"examples.hot_reload_message"},
    Prefixes = {"app."}
  }
}

server:Routes("/reload", function(req, res)
  local messageProvider = require("examples.hot_reload_message")
  return res:response(200, messageProvider.get())
end)

server:Run()
```

### Notes

`PudimServer.help` and `PudimServer.version()` are not available in the current codebase.
