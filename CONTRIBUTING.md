# Contributing to Pudim Server

Thank you for considering contributing to Pudim Server! 🎉

🇧🇷 [Leia em Português](CONTRIBUTING_PT-BR.MD)

## How to Contribute

### Reporting Bugs

1. Check if the bug hasn't already been reported in [issues](https://github.com/pessoa736/PudimServerAPIs/issues)
2. If not found, create a new issue with:
   - Clear and descriptive title
   - Steps to reproduce the problem
   - Expected behavior vs actual behavior
   - Lua version and operating system
   - Example code (if possible)

### Suggesting Features

1. Check the [Roadmap](README.md#roadmap) to see if it's already planned
2. Open an issue with the `feature request` tag
3. Describe:
   - The problem the feature solves
   - How you imagine the API/usage
   - Code examples (if applicable)

### Submitting Pull Requests

1. **Fork** the repository
2. **Clone** your fork:
   ```sh
   git clone https://github.com/your-username/PudimServerAPIs.git
   cd PudimServerAPIs
   ```
3. Create a **branch** for your feature/fix:
   ```sh
   git checkout -b my-feature
   ```
4. Make your changes
5. **Test** your changes:
   ```sh
   lua ./PS/mysandbox/test.lua
   ```
6. **Commit** your changes:
   ```sh
   git add .
   git commit -m "feat: feature description"
   ```
7. **Push** to your fork:
   ```sh
   git push origin my-feature
   ```
8. Open a **Pull Request** to the `dev` branch

## Code Conventions

### Style

- Indentation with **2 spaces**
- Variable names in **camelCase**
- Class/module names in **PascalCase**
- Comments in Portuguese or English

### Commits

We follow the [Conventional Commits](https://www.conventionalcommits.org/) pattern:

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `refactor` | Code refactoring |
| `test` | Adding/modifying tests |
| `chore` | Other changes (build, configs, etc) |

Examples:
```
feat: add query string support
fix: fix header parsing with spaces
docs: update README with new examples
```

## Project Structure

```
PudimServerAPIs/
├── PS/                    # Main source code
│   ├── init.lua           # Main module (PudimServer)
│   ├── http.lua           # HTTP parser and responses
│   ├── utils.lua          # Utilities and helpers
│   ├── ServerChecks.lua   # Server validations
│   └── mysandbox/         # Tests and experiments
├── rockspecs/             # LuaRocks specs
├── README.md              # Documentation in English
├── README_PT-BR.MD        # Documentation in Portuguese
└── LICENSE                # MIT License
```

## Development Environment

### Requirements

- Lua >= 5.4
- LuaRocks
- LuaSocket
- lua-cjson

### Local Installation

```sh
# Install dependencies
luarocks install luasocket --local
luarocks install lua-cjson --local

# Run tests
lua ./PS/mysandbox/test.lua
```

## Questions?

Feel free to open an issue with the `question` tag or contact [Davi](https://github.com/pessoa736).

---

Thank you for contributing! 🍮
