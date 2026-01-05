# Contribuindo para o Pudim Server

Obrigado por considerar contribuir com o Pudim Server! 🎉

## Como contribuir

### Reportando bugs

1. Verifique se o bug já não foi reportado nas [issues](https://github.com/pessoa736/PudimServerAPIs/issues)
2. Se não encontrar, crie uma nova issue com:
   - Título claro e descritivo
   - Passos para reproduzir o problema
   - Comportamento esperado vs comportamento atual
   - Versão do Lua e sistema operacional
   - Código de exemplo (se possível)

### Sugerindo features

1. Verifique o [Roadmap](README_PT-BR.MD#roadmap) para ver se já está planejado
2. Abra uma issue com a tag `feature request`
3. Descreva:
   - O problema que a feature resolve
   - Como você imagina a API/uso
   - Exemplos de código (se aplicável)

### Enviando Pull Requests

1. **Fork** o repositório
2. **Clone** seu fork:
   ```sh
   git clone https://github.com/seu-usuario/PudimServerAPIs.git
   cd PudimServerAPIs
   ```
3. Crie uma **branch** para sua feature/fix:
   ```sh
   git checkout -b minha-feature
   ```
4. Faça suas alterações
5. **Teste** suas mudanças:
   ```sh
   lua ./PS/mysandbox/test.lua
   ```
6. **Commit** suas mudanças:
   ```sh
   git add .
   git commit -m "feat: descrição da feature"
   ```
7. **Push** para seu fork:
   ```sh
   git push origin minha-feature
   ```
8. Abra um **Pull Request** para a branch `dev`

## Convenções de código

### Estilo

- Indentação com **2 espaços**
- Nomes de variáveis em **camelCase**
- Nomes de classes/módulos em **PascalCase**
- Comentários em português ou inglês

## Estrutura do projeto

```
PudimServerAPIs/
├── PS/                    # Código fonte principal
│   ├── init.lua           # Módulo principal (PudimServer)
│   ├── http.lua           # Parser HTTP e respostas
│   ├── utils.lua          # Utilitários e helpers
│   ├── ServerChecks.lua   # Validações do servidor
│   └── mysandbox/         # Testes e experimentações
├── rockspecs/             # Specs para LuaRocks
├── README_PT-BR.MD        # Documentação em português
└── LICENSE                # Licença MIT
```

## Ambiente de desenvolvimento

### Requisitos

- Lua >= 5.4
- LuaRocks
- LuaSocket
- lua-cjson

### Instalação local

```sh
# Instalar dependências
luarocks install luasocket --local
luarocks install lua-cjson --local

# Rodar testes
lua ./PS/mysandbox/test.lua
```

## Dúvidas?

Sinta-se à vontade para abrir uma issue com a tag `question` ou entrar em contato com [Davi](https://github.com/pessoa736).

---

Obrigado por contribuir! 🍮
