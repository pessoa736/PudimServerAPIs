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
  - [Customizing the Client Wrapper](#customizing-the-client-wrapper)
- [Complete Example](#complete-example)
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

## Getting Started

### Installation

First, to run it we need to install it using LuaRocks:

```sh
# Local installation
luarocks install PudimServer --local

# Global installation
sudo luarocks install PudimServer
```

### Creating the Server

Now let's create a file for the server called `Server.lua` to import PudimServer and configure it:

```lua
local PudimServer = require("PudimServer") -- importing PudimServer

local MyServer = PudimServer:Create{
    ServiceName = "Service Name",     -- self-explanatory, it's the service name.
    Port = 8080,                      -- port the server will open on.
    Address = "localhost",            -- or any address mapped by your machine.
    wrapClientFunc = function(Server) -- for custom client handling, can be nil if not used.

        --- here you can set up the server to use SSL or TLS with additional libs, or whatever you want.
        local client = Server:accept()
        return client
    end
}

local MyServer = PudimServer:Create() -- this creates the server with default configuration
```

### Creating Routes

Route creation follows something similar to Next.js where you create a function to handle different request types for the route and return responses.

In PudimServer we use the `Routes` function, which receives first the route as a string and then the function that handles the request response.

- HTML page example:

```lua
MyServer:Routes(
    "/", -- route 
    function (req, res)
        if req.method == "GET" then -- request type
            
            return res:response(
                200, -- status
                     -- body
                [[
                    <html>
                        <body>
                            <h1>MyServer</h1>
                        </body>
                    </html>
                ]], 
                {   -- headers
                    ["Content-Type"] = "text/html"
                }
            )
        
        end

        return res:response(400, {msg = "method not valid"}) -- if no response is sent
    end
)
```

- JSON API example:

```lua
MyServer:Routes(
    "/api/users",
    function (req, res)
        if req.method == "GET" then
            local users = {
                {id = 1, name = "John"},
                {id = 2, name = "Mary"}
            }
            return res:response(200, users) -- tables are automatically converted to JSON
        end

        if req.method == "POST" then
            -- process request body
            local data = req.body
            return res:response(200, {msg = "User created!", data = data})
        end

        return res:response(400, {error = "Method not supported"})
    end
)
```

### Starting the Server

After creating the routes, just call the `Run` method to start the server:

```lua
MyServer:Run() -- the server will keep running and listening for requests
```

### Request Object

The `req` object passed to the handler contains the following properties:

| Property | Type | Description |
|----------|------|-------------|
| `method` | string | HTTP method (GET, POST, PUT, DELETE, etc) |
| `path` | string | Request path (e.g.: "/api/users") |
| `version` | string | HTTP version (e.g.: "HTTP/1.1") |
| `headers` | table | Request headers (keys in lowercase) |
| `body` | string | Request body |

### Response Object

The `res:response()` method accepts the following parameters:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `status` | number | ✅ | HTTP status code (200, 404, 500, etc) |
| `body` | string/table | ✅ | Response body. If it's a table, it will be converted to JSON |
| `headers` | table | ❌ | Custom response headers |

### Customizing the Client Wrapper

The `wrapClientFunc` allows customizing how the client is handled, useful for implementing SSL/TLS:

```lua
local MyServer = PudimServer:Create{
    ServiceName = "Secure Server",
    Port = 443,
    Address = "0.0.0.0",
    wrapClientFunc = function(Server)
        local client = Server:accept()
        -- here you can wrap the client with SSL
        -- example: client = ssl.wrap(client, params)
        return client
    end
}

-- or define it later:
MyServer:SetWrapClientFunc(function(Server)
    return Server:accept()
end)
```

## Complete Example

```lua
local PudimServer = require("PudimServer")

local MyServer = PudimServer:Create{
    ServiceName = "My API",
    Port = 3000,
    Address = "localhost"
}

-- Main route
MyServer:Routes("/", function(req, res)
    if req.method == "GET" then
        return res:response(200, "<h1>Welcome!</h1>", {["Content-Type"] = "text/html"})
    end
    return res:response(405, {error = "Method not allowed"})
end)

-- Data API
MyServer:Routes("/api/data", function(req, res)
    if req.method == "GET" then
        return res:response(200, {
            status = "ok",
            timestamp = os.time(),
            message = "API working!"
        })
    end
    return res:response(405, {error = "Method not allowed"})
end)

-- Start the server
print("Server running at http://localhost:3000")
MyServer:Run()
```

## Roadmap

> [!NOTE]
> This project is in experimental phase. Check below what has been implemented and what is planned.

### ✅ Implemented

- [x] Basic routing system
- [x] HTTP request parsing (method, path, headers, body)
- [x] Automatic JSON responses (tables converted to JSON)
- [x] Client wrapper customization (`wrapClientFunc`)
- [x] Configurable logging system

### 📋 Planned

- [ ] Dynamic routes with parameters (`/users/:id`, `/posts/:slug`)
- [ ] Automatic query string parsing (`?page=1&limit=10`)
- [ ] Middleware system for intercepting requests
- [ ] CORS helpers (Cross-Origin Resource Sharing)
- [ ] More HTTP status codes mapped
- [ ] File upload support (multipart/form-data)
- [ ] Serve static files (HTML, CSS, JS, images)
- [ ] Basic rate limiting

### 🔮 Future (maybe)

- [ ] WebSocket support
- [ ] Multi-threading / concurrency
- [ ] Native HTTPS (without external wrapper)
- [ ] Hot reload in development
- [ ] CLI for creating projects

## License

This project is under the MIT license. See the [LICENSE](LICENSE) file for more details.

## Contributing

Contributions are welcome! See the complete guide at [CONTRIBUTING.md](CONTRIBUTING.md).

---

Made with ❤️ by [Davi](https://github.com/pessoa736)
