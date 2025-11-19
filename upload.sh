#!/bin/bash

# Script para fazer upload dos arquivos para o servidor
# Uso: ./upload.sh seu-usuario@seu-servidor.com:/caminho/destino

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    echo -e "${2}${1}${NC}"
}

# Verificar argumentos
if [ -z "$1" ]; then
    print_color "❌ Uso: ./upload.sh usuario@servidor:/caminho/destino" $RED
    echo ""
    print_color "Exemplos:" $YELLOW
    print_color "  ./upload.sh root@192.168.1.10:/tmp/painel" $YELLOW
    print_color "  ./upload.sh usuario@exemplo.com:/home/usuario/painel" $YELLOW
    exit 1
fi

DESTINO="$1"
ARQUIVOS_SCRIPT=("install-panel-fixed.sh" "generate-all-configs.sh" "test-scripts.sh")
ARQUIVOS_DOC=("START-HERE.md" "QUICKSTART.md" "README.md" "CORRECTIONS.md" "DEPLOYMENT.md" "SUMMARY.md" "INDEX.md" "REPORT.md" "MANIFEST.md" "CHANGELOG.md")

print_color "📤 INICIANDO UPLOAD PARA: $DESTINO" $CYAN
echo ""

# Contar arquivos
TOTAL=$((${#ARQUIVOS_SCRIPT[@]} + ${#ARQUIVOS_DOC[@]}))
print_color "📦 Total de arquivos: $TOTAL" $CYAN
echo ""

# Fazer upload dos scripts
print_color "🔄 Fazendo upload dos scripts..." $YELLOW
for arquivo in "${ARQUIVOS_SCRIPT[@]}"; do
    if [ -f "$arquivo" ]; then
        print_color "  ↳ $arquivo" $GREEN
        scp "$arquivo" "$DESTINO/" 2>/dev/null
        if [ $? -eq 0 ]; then
            print_color "    ✅ OK" $GREEN
        else
            print_color "    ❌ ERRO" $RED
        fi
    else
        print_color "  ❌ $arquivo não encontrado" $RED
    fi
done

echo ""

# Fazer upload da documentação
print_color "📚 Fazendo upload da documentação..." $YELLOW
for arquivo in "${ARQUIVOS_DOC[@]}"; do
    if [ -f "$arquivo" ]; then
        print_color "  ↳ $arquivo" $GREEN
        scp "$arquivo" "$DESTINO/" 2>/dev/null
        if [ $? -eq 0 ]; then
            print_color "    ✅ OK" $GREEN
        else
            print_color "    ❌ ERRO" $RED
        fi
    else
        print_color "  ❌ $arquivo não encontrado" $RED
    fi
done

echo ""
print_color "✅ UPLOAD CONCLUÍDO!" $GREEN
print_color "Próximo passo: ssh $DESTINO" $CYAN
print_color "Depois: cd painel && sudo ./install-panel-fixed.sh" $CYAN
