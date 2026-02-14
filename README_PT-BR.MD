# Pudim Server

Criação de servidores HTTP simples, leves e customizáveis

> [!WARNING]
> Projeto experimental. APIs podem mudar sem aviso.

🇺🇸 [Read in English](README.md)

## Sumário

- [Sobre](#sobre)
- [Dependências](#dependências)
- [Como Começar](#como-começar)
  - [Instalação](#instalação)
  - [Criando o Servidor](#criando-o-servidor)
  - [Criando Rotas](#criando-rotas)
  - [Iniciando o Servidor](#iniciando-o-servidor)
  - [Objeto Request](#objeto-request)
  - [Objeto Response](#objeto-response)
- [CORS](#cors)
- [Pipeline](#pipeline)
- [Cache](#cache)
- [Exemplo Completo](#exemplo-completo)
- [Exemplos](#exemplos)
- [Roadmap](#roadmap)
- [Licença](#licença)
- [Contribuindo](#contribuindo)

## Sobre

Pudim Server é uma lib Lua focada em fornecer APIs simples para criação de servidores web com um sistema de rotas. Feito para aceitar requisições HTTP, interpretá-las, despachar para um handler e devolver uma resposta.

Essa lib está sendo projetada com base no que [Davi](https://github.com/pessoa736) entende de **servidor**. Ele pretende expandir a lib para algo mais complexo com o tempo, mas mantendo em foco a simplicidade, leveza e customização.

## Dependências

- Lua >= 5.4
- LuaSocket
- lua-cjson
- loglua

## Como Começar

### Instalação

```sh
# Instalação local
luarocks install PudimServer --local

# Instalação global
sudo luarocks install PudimServer
```

### Criando o Servidor

```lua
local PudimServer = require("PudimServer")

local server = PudimServer:Create{
  ServiceName = "Meu Serviço",
  Port = 8080,
  Address = "localhost"
}
```

Todos os campos são opcionais. Padrões: `ServiceName = "Pudim Server"`, `Port = 8080`, `Address = "localhost"`.

### Criando Rotas

Handlers de rota recebem `(req, res)` e devem retornar `res:response(status, body, headers)`.

```lua
-- Página HTML
server:Routes("/", function(req, res)
  if req.method == "GET" then
    return res:response(200, "<h1>Olá!</h1>", {["Content-Type"] = "text/html"})
  end
  return res:response(405, {error = "Método não permitido"})
end)

-- API JSON (tabelas são auto-convertidas para JSON)
server:Routes("/api/users", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      {id = 1, name = "João"},
      {id = 2, name = "Maria"}
    })
  end

  if req.method == "POST" then
    return res:response(201, {msg = "Usuário criado!", data = req.body})
  end

  return res:response(405, {error = "Método não permitido"})
end)
```

### Iniciando o Servidor

```lua
server:Run()
```

### Objeto Request

| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| `method` | string | Método HTTP (GET, POST, PUT, DELETE, etc) |
| `path` | string | Caminho da requisição (ex: "/api/users") |
| `version` | string | Versão do HTTP (ex: "HTTP/1.1") |
| `headers` | table | Headers da requisição (chaves em lowercase) |
| `body` | string | Corpo da requisição |

### Objeto Response

`res:response(status, body, headers)`:

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `status` | number | ✅ | Código de status HTTP (200, 404, 500, etc) |
| `body` | string/table | ✅ | Corpo da resposta. Tabelas são auto-convertidas para JSON |
| `headers` | table | ❌ | Headers customizados da resposta |

## CORS

Habilite CORS com `EnableCors()`. Requisições preflight `OPTIONS` são tratadas automaticamente.

```lua
-- Permitir todas as origens (padrão)
server:EnableCors()

-- Configuração restrita
server:EnableCors{
  AllowOrigins = {"https://meuapp.com", "https://admin.meuapp.com"},
  AllowMethods = {"GET", "POST"},
  AllowHeaders = "Content-Type, Authorization",
  AllowCredentials = true,
  ExposeHeaders = {"X-Total-Count"},
  MaxAge = 3600
}
```

| Opção | Tipo | Padrão |
|-------|------|--------|
| `AllowOrigins` | string \| string[] | `"*"` |
| `AllowMethods` | string \| string[] | `"GET, POST, PUT, DELETE, PATCH, OPTIONS"` |
| `AllowHeaders` | string \| string[] | `"Content-Type, Authorization"` |
| `ExposeHeaders` | string \| string[] | `""` |
| `AllowCredentials` | boolean | `false` |
| `MaxAge` | number | `86400` |

## Pipeline

O sistema de pipeline permite adicionar handlers de request/response que rodam antes dos handlers de rota. Cada handler recebe `(req, res, next)` — chame `next()` para continuar ou retorne diretamente para interromper.

```lua
-- Logger de requisições
server:UseHandler{
  name = "logger",
  Handler = function(req, res, next)
    print(req.method .. " " .. req.path)
    return next()
  end
}

-- Autenticação (interrompe em caso de falha)
server:UseHandler{
  name = "auth",
  Handler = function(req, res, next)
    if req.path:find("^/api/protected") and not req.headers["authorization"] then
      return res:response(401, {error = "Não autorizado"})
    end
    return next()
  end
}

-- Wrapper de resposta
server:UseHandler{
  name = "timer",
  Handler = function(req, res, next)
    local start = os.clock()
    local response = next()
    print(("Requisição levou %.3fs"):format(os.clock() - start))
    return response
  end
}

-- Remover um handler
server:RemoveHandler("logger")
```

Handlers rodam na ordem em que são registrados. O handler de rota roda por último.

## Cache

Cache de respostas em memória com TTL e eviction automática. Apenas requisições `GET` são cacheadas.

```lua
local Cache = require("PudimServer.cache")

-- Criar instância do cache
local cache = Cache.new{
  MaxSize = 200,     -- máximo de entradas (padrão: 100)
  DefaultTTL = 120   -- segundos (padrão: 60)
}

-- Adicionar ao pipeline (forma mais fácil)
server:UseHandler(Cache.createPipelineHandler(cache))

-- Ou usar manualmente em uma rota
server:Routes("/api/data", function(req, res)
  local cached = cache:get("minha-chave")
  if cached then return cached end

  local response = res:response(200, {data = "computação pesada"})
  cache:set("minha-chave", response, 30) -- TTL customizado
  return response
end)

-- Invalidar entradas
cache:invalidate("minha-chave")
cache:clear()
```

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `MaxSize` | number | `100` | Máximo de entradas antes da eviction |
| `DefaultTTL` | number | `60` | TTL em segundos |

## Exemplo Completo

```lua
local PudimServer = require("PudimServer")
local Cache = require("PudimServer.cache")

local server = PudimServer:Create{
  ServiceName = "Minha API",
  Port = 3000,
  Address = "localhost"
}

-- Habilitar CORS
server:EnableCors()

-- Logger de requisições
server:UseHandler{
  name = "logger",
  Handler = function(req, res, next)
    print(("[%s] %s %s"):format(os.date("%H:%M:%S"), req.method, req.path))
    return next()
  end
}

-- Cache (apenas GET, TTL de 30s)
local cache = Cache.new{ DefaultTTL = 30 }
server:UseHandler(Cache.createPipelineHandler(cache))

-- Rotas
server:Routes("/", function(req, res)
  if req.method == "GET" then
    return res:response(200, "<h1>Bem-vindo!</h1>", {["Content-Type"] = "text/html"})
  end
  return res:response(405, {error = "Método não permitido"})
end)

server:Routes("/api/data", function(req, res)
  if req.method == "GET" then
    return res:response(200, {
      status = "ok",
      timestamp = os.time(),
      message = "API funcionando!"
    })
  end
  return res:response(405, {error = "Método não permitido"})
end)

print("Servidor rodando em http://localhost:3000")
server:Run()
```

## Exemplos

Exemplos funcionais estão disponíveis no diretório [`examples/`](examples/):

| Arquivo | Descrição |
|---------|-----------|
| [`json_response_example.lua`](examples/json_response_example.lua) | Auto encoding de tabelas para JSON |
| [`cors_example.lua`](examples/cors_example.lua) | CORS com configuração padrão |
| [`cors_restricted_example.lua`](examples/cors_restricted_example.lua) | CORS com origens restritas e credentials |
| [`pipeline_example.lua`](examples/pipeline_example.lua) | Logger, auth e header customizado no pipeline |
| [`cache_example.lua`](examples/cache_example.lua) | Cache via pipeline e cache manual |

Execute qualquer exemplo com:

```sh
lua ./examples/json_response_example.lua
```

## Roadmap

> [!NOTE]
> Este projeto está em fase experimental. Confira abaixo o que já foi implementado e o que está planejado.

### ✅ Implementado

- [x] Sistema de rotas básico
- [x] Parsing de requisições HTTP (method, path, headers, body)
- [x] Respostas JSON automáticas (tables convertidas para JSON)
- [x] Sistema de logs configurável
- [x] CORS helpers (Cross-Origin Resource Sharing)
- [x] Pipeline de request/response (middleware no nível HTTP)
- [x] Cache de respostas em memória com TTL

### 📋 Planejado

- [ ] Rotas dinâmicas com parâmetros (`/users/:id`, `/posts/:slug`)
- [ ] Parsing automático de query strings (`?page=1&limit=10`)
- [ ] Mais códigos de status HTTP mapeados
- [ ] Suporte a uploads de arquivos (multipart/form-data)
- [ ] Servir arquivos estáticos (HTML, CSS, JS, imagens)
- [ ] Rate limiting básico

### 🔮 Futuro (talvez)

- [ ] Suporte a WebSockets
- [ ] Multi-threading / concorrência
- [ ] HTTPS nativo (sem precisar de wrapper externo)
- [ ] Hot reload em desenvolvimento
- [ ] CLI para criar projetos

## Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## Contribuindo

Contribuições são bem-vindas! Veja o guia completo em [CONTRIBUTING_PT-BR.MD](CONTRIBUTING_PT-BR.MD).

---

Feito com ❤️ por [Davi](https://github.com/pessoa736)
