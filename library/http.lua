


---@meta PudimServer.http
---@module "PudimServer.http"




---@class Request
---@field method string Método HTTP (GET, POST, etc)
---@field path string Caminho da requisição
---@field version string Versão do HTTP
---@field headers table<string, string> Headers da requisição
---@field body string Corpo da requisição
---@field query table<string, string|string[]>? Query string parsed
---@field params table<string, string>? Parâmetros de rota dinâmica




---@class Response
---@field response fun(self: httpParser, status: number, body: string|table, headers?: table<string, string>): string
---@field __index httpParser

---@class httpParser
local httpParser = {}
httpParser.__index = httpParser


--- Parses a raw HTTP request string into a structured Request object.
---@param self httpParser
---@param raw string Raw HTTP request data
---@return Request req Parsed request with method, path, version, headers, body
function httpParser.Request(self, raw)end

--- Builds an HTTP response string.
--- Tables passed as body are automatically encoded to JSON with Content-Type application/json.
---@param self httpParser
---@param status number HTTP status code (200, 404, 500, etc)
---@param body string|table Response body (tables auto-encode to JSON)
---@param headers? table<string, string> Custom response headers
---@return string response Raw HTTP response string ready to send
function httpParser.Response(self, status, body, headers) end


---@alias RouteHandler fun(req: Request, res: httpParser): any

return httpParser