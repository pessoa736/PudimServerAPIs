---@meta PudimServer
---PudimServer
---a simple server builder 

---@module "PudimServer"
---@author Davi Passos


---@class ConfigServer
---@field ServiceName string? Nome do serviço (default: "Pudim Server")
---@field Address string? Endereço do servidor (default: "localhost")
---@field Port number? Porta do servidor (default: 8080)
---@field Middlewares Middlewares[]? Middlewares de socket
---@field Https HttpsConfig? Configuração HTTPS nativa (luasec)
---@field Concurrency ConcurrencyConfig? Configuração de concorrência cooperativa
---@field HotReload HotReloadConfig? Hot reload em desenvolvimento sem watcher (limpa package.loaded)


---@class Server : ConfigServer
---@field ServerSocket table|userdata Socket do servidor
---@field _routes RouteEntry[] Tabela de rotas registradas
---@field _corsConfig table? Config CORS resolvida
---@field _pipeline Pipeline Pipeline de handlers HTTP
---@field _httpsConfig table? Config HTTPS interna
---@field _concurrencyConfig ConcurrencyConfig Config de concorrência interna
---@field _hotReloadConfig HotReloadConfig Config de hot reload interna
---@field __index Server

---@class PudimServer : Server
local PudimServer = {}
PudimServer.__index = PudimServer


---@param lib PudimServer 
---@param config? ConfigServer
---@return PudimServer
function  PudimServer.Create(lib, config) end


---@param self PudimServer 
---@param path string
---@param handler fun(Request: Request, Response: httpParser):string?
function PudimServer.Routes(self, path, handler) end


---@param self PudimServer
function PudimServer.Run(self) end


--- Adds a socket-level middleware that transforms the client connection.
--- Middlewares run on the raw TCP socket before HTTP parsing.
---@param self PudimServer
---@param Middleware Middlewares Middleware with name and Handler function(client) → client
function PudimServer.SetMiddleware(self, Middleware)end



--- Removes a socket-level middleware by name.
---@param self PudimServer
---@param name string Name of the middleware to remove
---@return boolean removed True if middleware was found and removed
function PudimServer.RemoveMiddleware(self, name) end


--- Adds a handler to the HTTP pipeline (runs before route handler).
---@param self PudimServer
---@param entry PipelineEntry
function PudimServer.UseHandler(self, entry) end

--- Removes an HTTP pipeline handler by name.
---@param self PudimServer
---@param name string
---@return boolean removed
function PudimServer.RemoveHandler(self, name) end

--- Enable cross-origin resource sharing with optional config.
---@param self PudimServer
---@param config? CorsConfig
function PudimServer.EnableCors(self, config) end

--- Enable hot reload behaviour without a filesystem watcher.
---@param self PudimServer
---@param config? HotReloadConfig
function PudimServer.EnableHotReload(self, config) end



---@class Middlewares: table
---@field name string
---@field Handler fun(Client: any): any




---@class HttpsConfig
---@field Enabled boolean? Habilitar HTTPS nativo (default: false)
---@field Mode string? Modo SSL (default: "server")
---@field Protocol string? Protocolo SSL (default: "any")
---@field Key string? Caminho da chave privada
---@field Certificate string? Caminho do certificado
---@field Verify string? Política de verificação (default: "none")
---@field Options string? Opções SSL (ex: "all")

---@class ConcurrencyConfig
---@field Enabled boolean? Habilitar concorrência cooperativa com corrotinas (default: false)
---@field Sleep number? Intervalo de espera do loop quando ocioso (default: 0.001)

---@class HotReloadConfig
---@field Enabled boolean? Habilitar hot reload sem watcher (default: false)
---@field Modules string[]? Módulos exatos para invalidar em package.loaded
---@field Prefixes string[]? Prefixos de módulos para invalidar em package.loaded







---@class RouteEntry
---@field path string Caminho original da rota
---@field handler RouteHandler Handler da rota
---@field dynamic boolean Se a rota tem parâmetros dinâmicos
---@field pattern string? Pattern compilado para matching dinâmico
---@field paramNames string[]? Nomes dos parâmetros dinâmicos

---@class RoutesParams
---@field path string Caminho da rota
---@field handler RouteHandler Handler da rota


return PudimServer