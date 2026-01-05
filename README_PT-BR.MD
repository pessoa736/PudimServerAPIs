# Pudim Server

Criação de servidores HTTP simples, leves e customizaveis

> [!WARNING]
> Projeto experimental. APIs podem mudar sem aviso.

🇺🇸 [Read in English](README.md)

## sumario

- [sobre o que se trata](#sobre-o-que-se-trata)
- [dependencias](#dependencias)
- [Como funciona e como começar?](#como-funciona-e-como-começar)
  - [instalação](#instalação)
  - [Criando o servidor](#criando-o-servidor)
  - [Criando Rotas](#criando-rotas)
  - [Iniciando o servidor](#iniciando-o-servidor)
  - [Objeto Request](#objeto-request)
  - [Objeto Response](#objeto-response)
  - [Customizando o wrapper do client](#customizando-o-wrapper-do-client)
- [Exemplo completo](#exemplo-completo)
- [Roadmap](#roadmap)
- [Licença](#licença)
- [Contribuindo](#contribuindo)

## sobre o que se trata?

Atualmente Pudim Server é um lib lua focada em fazer APIs simples para criação de servidores web, com um sistema de rotas. feito para aceitar requisções HTTP e interpretar, despachar para um handler e devolver uma resposta.

Essa lib esta sendo projetada com base no que [Davi](https://github.com/pessoa736) entende de **servidor**. Ele pretende expandir a lib para algo mais complexo com o tempo, mas mantendo em foco a simplicidade, leveza e customização.

## dependencias

- lua >= 5.4
- luaSocket
- lua-cjson

## Como funciona e como começar?

### instalação

primeiramente para poder rodá-lo precisamos instala-lo, e para isso no usaremos o luarocks

```sh
# instalação local
luarocks install PudimServer --local


# instalação global
sudo luarocks install PudimServer
```

### Criando o servidor

agora criaremos um arquivo para o servidor nomeremos de `Server.lua` para importar o PudimServer e configura-lo para criar-mos o servidor.

```lua
local PudimServer = require("PudimServer") --importando o PudimServer

local MyServer = PudimServer:Create{
    ServiceName = "nome do Serviço",  -- auto-explicativo, é o nome do serviço.
    Port = 8080,                      -- porta que o servidor va ser aberto.
    Address = "localhost",            -- ou quaquer endereço mapeado pela sua maquina.
    wrapClientFunc = function(Server) -- para o tratamento customizado para o client, caso não use pode deixar como nil.

        --- aqui vc pode organizar o servidor para usar SSL ou TSL com adição de outras libs, ou o que quiser fazer.
        local client = Server:accept()
        return client
    end
}

local MyServer = PudimServer:Create() -- assim ele cria o server com a configuração padrão
```

### Criando Rotas

a criação de rotas segue algo parecido com o next.js onde vc criar uma função para tratar os diferentes tipos de requisção para a rota e retorna respostas.

no PudimServer utilizamos o função Routes, ela recebe primeiramente a rota com string e depois 
a função que trata a resposta da requisão dela

- exemplo de uma pagina html:

```lua
MyServer:Routes(
    "/", -- rota 
    function (req, res)
        if req.method == "GET" then --- tipo da requisição
            
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

        return res:response(400, {msg = "metodo não é valido"}) -- caso não seja enviado menhuma resposta
  end
)
```

- exemplo de uma API JSON:

```lua
MyServer:Routes(
    "/api/users",
    function (req, res)
        if req.method == "GET" then
            local users = {
                {id = 1, name = "João"},
                {id = 2, name = "Maria"}
            }
            return res:response(200, users) -- tabelas são automaticamente convertidas para JSON
        end

        if req.method == "POST" then
            -- processar o body da requisição
            local data = req.body
            return res:response(200, {msg = "Usuário criado!", data = data})
        end

        return res:response(400, {error = "Método não suportado"})
    end
)
```

### Iniciando o servidor

após criar as rotas, basta chamar o método `Run` para iniciar o servidor:

```lua
MyServer:Run() -- o servidor ficará rodando e escutando requisições
```

### Objeto Request

O objeto `req` passado para o handler contém as seguintes propriedades:

| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| `method` | string | Método HTTP (GET, POST, PUT, DELETE, etc) |
| `path` | string | Caminho da requisição (ex: "/api/users") |
| `version` | string | Versão do HTTP (ex: "HTTP/1.1") |
| `headers` | table | Headers da requisição (chaves em lowercase) |
| `body` | string | Corpo da requisição |

### Objeto Response

O método `res:response()` recebe os seguintes parâmetros:

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `status` | number | ✅ | Código de status HTTP (200, 404, 500, etc) |
| `body` | string/table | ✅ | Corpo da resposta. Se for uma table, será convertido para JSON |
| `headers` | table | ❌ | Headers customizados da resposta |

### Customizando o wrapper do client

O `wrapClientFunc` permite customizar como o cliente é tratado, útil para implementar SSL/TLS:

```lua
local MyServer = PudimServer:Create{
    ServiceName = "Servidor Seguro",
    Port = 443,
    Address = "0.0.0.0",
    wrapClientFunc = function(Server)
        local client = Server:accept()
        -- aqui você pode wrappear o client com SSL
        -- exemplo: client = ssl.wrap(client, params)
        return client
    end
}

-- ou definir depois:
MyServer:SetWrapClientFunc(function(Server)
    return Server:accept()
end)
```

## Exemplo completo

```lua
local PudimServer = require("PudimServer")

local MyServer = PudimServer:Create{
    ServiceName = "Minha API",
    Port = 3000,
    Address = "localhost"
}

-- Rota principal
MyServer:Routes("/", function(req, res)
    if req.method == "GET" then
        return res:response(200, "<h1>Bem-vindo!</h1>", {["Content-Type"] = "text/html"})
    end
    return res:response(405, {error = "Método não permitido"})
end)

-- API de dados
MyServer:Routes("/api/data", function(req, res)
    if req.method == "GET" then
        return res:response(200, {
            status = "ok",
            timestamp = os.time(),
            message = "API funcionando!"
        })
    end
    return res:response(405, {error = "Método não permitido"})
end)

-- Inicia o servidor
print("Servidor rodando em http://localhost:3000")
MyServer:Run()
```

## Roadmap

> [!NOTE]
> Este projeto está em fase experimental. Confira abaixo o que já foi implementado e o que está planejado.

### ✅ Implementado

- [x] Sistema de rotas básico
- [x] Parsing de requisições HTTP (method, path, headers, body)
- [x] Respostas JSON automáticas (tables convertidas para JSON)
- [x] Customização do wrapper do client (`wrapClientFunc`)
- [x] Sistema de logs configurável

### Planejado

- [ ] Rotas dinâmicas com parâmetros (`/users/:id`, `/posts/:slug`)
- [ ] Parsing automático de query strings (`?page=1&limit=10`)
- [ ] Sistema de middleware para interceptar requisições
- [ ] Helpers para CORS (Cross-Origin Resource Sharing)
- [ ] Mais códigos de status HTTP mapeados
- [ ] Suporte a uploads de arquivos (multipart/form-data)
- [ ] Servir arquivos estáticos (HTML, CSS, JS, imagens)
- [ ] Rate limiting básico

### Futuro 

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
