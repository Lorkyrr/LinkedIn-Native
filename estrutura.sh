#!/usr/bin/env bash
set -euo pipefail

README_FILE="README.md"
DOCS_DIR="architecture-docs"
CONFORMIDADE_FILE="${DOCS_DIR}/Conformidade-Diretrizes.md"

echo "===================================================="
echo "      LinkedIn-Native - Validador & Estrutura       "
echo "===================================================="

# ----------------------------------------------------
# 1. Criação da Estrutura de Pastas
# ----------------------------------------------------
echo "==> A criar a estrutura completa do projeto Nível 3..."

mkdir -p .github/workflows
mkdir -p .githooks
mkdir -p "$DOCS_DIR"
mkdir -p docs/adr
mkdir -p .planning/specs
mkdir -p .planning/epics
mkdir -p build
mkdir -p frontend/src/components
mkdir -p frontend/src/wailsjs
mkdir -p frontend/dist
mkdir -p pkg/app pkg/auth pkg/client pkg/queue pkg/validators
mkdir -p cmd/linkedin-native internal

echo "✓ Pastas do projeto criadas com sucesso."

# ----------------------------------------------------
# 2. Ficheiros Base e Placeholders
# ----------------------------------------------------
echo "==> A criar ficheiros base e placeholders..."

touch README.md CHANGELOG.md Makefile wails.json frontend/dist/.keep

# Inicializa main.go com sintaxe válida se estiver vazio
if [ ! -s main.go ]; then
    printf 'package main\n\nfunc main() {\n}\n' > main.go
fi

# Inicializa app.go com sintaxe válida se estiver vazio
if [ ! -s app.go ]; then
    printf 'package main\n\ntype App struct {\n}\n' > app.go
fi

# Módulo Go
if [ ! -f "go.mod" ]; then
    echo "⚠ Módulo Go não encontrado. A inicializar 'go mod init linkedin-native'..."
    go mod init linkedin-native || true
fi

# Documento de Conformidade em architecture-docs/
if [ ! -f "$CONFORMIDADE_FILE" ]; then
    printf '# Conformidade com as Diretrizes de Código\n\nAplicação das Diretrizes ao LinkedIn-Native.\n' > "$CONFORMIDADE_FILE"
    echo "✓ Ficheiro '$CONFORMIDADE_FILE' criado."
fi

# Git Hooks
touch .githooks/pre-commit .githooks/pre-push
chmod +x .githooks/pre-commit .githooks/pre-push

# ADRs
touch docs/adr/0000-modelo.md docs/adr/0001-arquitetura-wails-go.md

# ----------------------------------------------------
# 3. Configuração dos Git Hooks
# ----------------------------------------------------
echo "==> A ativar os hooks locais do Git..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    git config core.hooksPath .githooks
    echo "✓ Hooks do Git ativados em .githooks"
else
    echo "⚠️ Repositório Git não iniciado. Execute 'git init' e depois 'git config core.hooksPath .githooks'."
fi

# ----------------------------------------------------
# 4. Leitura do README e Detecção do Nível
# ----------------------------------------------------
if [ ! -f "$README_FILE" ]; then
    echo "❌ Erro Crítico: Ficheiro '$README_FILE' não encontrado."
    exit 1
fi

echo "==> A ler e analisar '$README_FILE'..."

LEVEL_LINE=$(grep -i "Nível do projeto" -A 3 "$README_FILE" | grep -iE "Nível [0-9]+" || true)

if [ -z "$LEVEL_LINE" ]; then
    echo "⚠️ Aviso: Nível não detetado. Assumindo Nível 1."
    LEVEL=1
else
    LEVEL=$(echo "$LEVEL_LINE" | grep -oE 'Nível [0-9]+' | grep -oE '[0-9]+' || echo "1")
fi

echo "==> Nível detetado no README: Nível $LEVEL"
echo "----------------------------------------------------"

# ----------------------------------------------------
# 5. Funções de Validação Adaptativas
# ----------------------------------------------------
run_level_1_checks() {
    echo "--> [Nível 1] A verificar formatação de código e sintaxe básica..."
    UNFORMATTED=$(gofmt -l .)
    if [ -n "$UNFORMATTED" ]; then
        echo "⚠️ Ficheiros Go não formatados encontrados:"
        echo "$UNFORMATTED"
        if [ "$LEVEL" -ge 4 ]; then
            echo "❌ Erro Nível 4: Formatação estrita (gofmt) é obrigatória."
            exit 1
        fi
    else
        echo "✓ Formatação Go (gofmt) OK."
    fi

    echo "A executar 'go vet'..."
    go vet ./...
    echo "✓ Verificação básica Nível 1 concluída."
}

run_level_2_checks() {
    run_level_1_checks
    echo "----------------------------------------------------"
    echo "--> [Nível 2] A executar testes unitários..."
    go test ./...
    
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        echo "A analisar frontend (Node/npm)..."
        (cd frontend && npm test --if-present)
    fi
    echo "✓ Verificação Nível 2 concluída."
}

run_level_3_checks() {
    run_level_2_checks
    echo "----------------------------------------------------"
    echo "--> [Nível 3] A aplicar testes de concorrência e lints..."
    
    echo "A executar testes Go com detector de race conditions (-race)..."
    go test -race ./...

    if command -v staticcheck &> /dev/null; then
        echo "A executar 'staticcheck'..."
        staticcheck ./...
    else
        echo "⚠️ Aviso: 'staticcheck' não instalado."
    fi

    if command -v govulncheck &> /dev/null; then
        echo "A verificar vulnerabilidades com 'govulncheck'..."
        govulncheck ./...
    else
        echo "⚠️ Aviso: 'govulncheck' não instalado."
    fi
    echo "✓ Verificação Nível 3 concluída."
}

run_level_4_checks() {
    echo "--> [Nível 4 - Serviço Crítico / Pagamentos & LGPD]"
    echo "----------------------------------------------------"
    UNFORMATTED=$(gofmt -l .)
    if [ -n "$UNFORMATTED" ]; then
        echo "❌ Erro Nível 4: Ficheiros sem formatação adequada:"
        echo "$UNFORMATTED"
        exit 1
    fi
    go vet ./...
    
    if command -v staticcheck &> /dev/null; then
        staticcheck ./...
    fi

    go test -race ./...

    if command -v govulncheck &> /dev/null; then
        govulncheck ./...
    fi

    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        (cd frontend && npm test --if-present && npm audit --audit-level=high)
    fi

    if [ -f "$CONFORMIDADE_FILE" ]; then
        echo "✓ Ficheiro '$CONFORMIDADE_FILE' localizado em '$DOCS_DIR'."
    else
        echo "❌ Erro Nível 4: Ficheiro '$CONFORMIDADE_FILE' ausente!"
        exit 1
    fi

    echo "✅ Sucesso nas exigências do Nível 4!"
}

# ----------------------------------------------------
# 6. Execução do Pipeline
# ----------------------------------------------------
case "$LEVEL" in
    1) run_level_1_checks ;;
    2) run_level_2_checks ;;
    3) run_level_3_checks ;;
    4) run_level_4_checks ;;
    *)
        echo "Nível desconhecido ($LEVEL). A executar testes padrões..."
        go test ./...
        ;;
esac

echo "===================================================="
echo "✅ Estrutura e verificações aplicadas com sucesso!"