# Copilot Instructions for PudimServer

## Project Overview

PudimServer is a Lua HTTP server library distributed via LuaRocks. It provides a routing system where users create a server instance with `PudimServer:Create{}`, register routes with `:Routes(path, handler)`, and start with `:Run()`. Route handlers receive `(req, res)` and must return `res:response(status, body, headers)`.

## Dependencies & Runtime

- **Lua >= 5.4** (`.luarc.json` targets Lua 5.5)
- **LuaRocks** for package management
- Core deps: `luasocket`, `lua-cjson`, `loglua`, `luasec` (ssl)

Install dependencies:

```sh
luarocks install luasocket --local
luarocks install lua-cjson --local
```

## Running the Test Server

```sh
lua ./PudimServer/mysandbox/test.lua
```

This starts a local server on `localhost:8080` serving HTML/CSS pages from `PudimServer/mysandbox/`.

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

## Architecture

The library entry point is `PudimServer/init.lua`, which exports the `PudimServer` table (used as a class via metatables). Key modules:

- **`init.lua`** — Server lifecycle: `Create`, `Routes`, `Run`, `SetMiddlewares`, `RemoveMiddlewares`. `Run()` enters an infinite accept loop with middleware pipeline.
- **`http.lua`** — HTTP parsing (`ParseRequest`) and response building (`response`). Tables passed as body are auto-encoded to JSON via `cjson`.
- **`utils.lua`** — Shared utilities: file I/O, runtime type-checking system (`createInterface`/`verifyTypes`), and `loadMessageOnChange` for deduplicated logging.
- **`cors.lua`** — CORS helpers: `createConfig`, `buildHeaders`, `preflightResponse`. Enabled via `Server:EnableCors(config)`.
- **`pipeline.lua`** — Request/response pipeline (middleware chain at HTTP level). Handlers receive `(req, res, next)` and call `next()` to continue or return early to short-circuit.
- **`cache.lua`** — In-memory response cache with TTL and eviction. Provides `Cache.new(config)` and `Cache.createPipelineHandler(cache)` for pipeline integration.
- **`ServerChecks.lua`** — Network utilities (port-open check via TCP connect).

### Runtime Type System

The codebase uses a custom interface/contract system instead of relying solely on Lua's dynamic typing. Interfaces are created with `utils:createInterface{field = "type"}` and validated with `utils:verifyTypes(value, interface, logFn, shouldExit)`. This pattern is used extensively — new code should follow it.

### Middleware Pipeline

Middlewares are registered via `Server:SetMiddlewares{name = "...", Handler = function(client) ... end}` and run sequentially in `GetClient()` on each accepted connection. The `Run()` method currently auto-registers an SSL middleware.

### Logging

All logging uses the `loglua` library via the global `_G.log`. Modules use `log.inSection("name")` for scoped loggers and `utils:loadMessageOnChange()` to avoid duplicate log messages.

## Code Conventions

- **Indentation:** 2 spaces
- **Naming:** `camelCase` for variables/functions, `PascalCase` for classes/modules
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`)
- **PR target:** Always target the `dev` branch
- **LuaDoc annotations:** Use `---@class`, `---@field`, `---@type`, `---@param` annotations for type hints
- **Comments:** Portuguese or English are both acceptable
- **Globals:** `_G.log` and `_G.cjson` are initialized on first require and expected to be available globally

## LuaRocks Module Map

The rockspec at `rockspecs/pudimserver-0.1.0-1.rockspec` maps module names to files:

```
PudimServer              → PudimServer/init.lua
PudimServer.http         → PudimServer/http.lua
PudimServer.utils        → PudimServer/utils.lua
PudimServer.cors         → PudimServer/cors.lua
PudimServer.pipeline     → PudimServer/pipeline.lua
PudimServer.cache        → PudimServer/cache.lua
PudimServer.ServerChecks → PudimServer/ServerChecks.lua
```

New modules must be added to both the `modules` table in the rockspec and follow the `PudimServer/` directory structure.
