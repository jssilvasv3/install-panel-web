#!/bin/bash

# Script de instalação única do Painel VPN/Proxy
# Uso: curl -sSL https://github.com/SEU-USUARIO/install-panel-web/raw/main/install.sh | bash

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    echo -e "${2}${1}${NC}"
}

# Banner
clear
print_color "╔═══════════════════════════════════════════════════════════╗" $CYAN
print_color "║          🔥 PAINEL VPN/PROXY - INSTALAÇÃO 🔥             ║" $CYAN
print_color "║                   Um Comando Apenas!                      ║" $CYAN
print_color "╚═══════════════════════════════════════════════════════════╝" $CYAN
echo ""

# Verificar root
if [[ $EUID -ne 0 ]]; then
    print_color "❌ Este script deve ser executado como root!" $RED
    print_color "   Execute: sudo bash (ou use su antes)" $YELLOW
    exit 1
fi

print_color "✅ Privilégios root verificados" $GREEN
echo ""

# Definir variáveis
REPO_URL="https://github.com/SEU-USUARIO/install-panel-web"
TEMP_DIR="/tmp/painel-install-$$"
INSTALL_DIR="/opt/panel-completo"

print_color "📥 Baixando arquivos do repositório..." $CYAN
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Baixar com git (mais rápido e limpo)
if command -v git &> /dev/null; then
    print_color "   Usando git clone..." $YELLOW
    git clone --depth 1 "$REPO_URL.git" . 2>/dev/null || {
        print_color "   ❌ Erro ao clonar repositório" $RED
        exit 1
    }
else
    # Fallback: wget para todos os arquivos
    print_color "   Usando wget (git não disponível)..." $YELLOW
    BASE="https://raw.githubusercontent.com/SEU-USUARIO/install-panel-web/main"
    
    # Baixar scripts
    wget -q "$BASE/install-panel-fixed.sh" || print_color "   ⚠️  Script principal não encontrado" $YELLOW
    wget -q "$BASE/generate-all-configs.sh" || true
    
    # Fazer executável
    chmod +x *.sh 2>/dev/null || true
fi

print_color "✅ Arquivos baixados com sucesso" $GREEN
echo ""

# Validar scripts
if [ ! -f "install-panel-fixed.sh" ]; then
    print_color "❌ Script principal não foi baixado!" $RED
    exit 1
fi

print_color "🔍 Validando sintaxe..." $CYAN
bash -n install-panel-fixed.sh || {
    print_color "❌ Erro na sintaxe do script" $RED
    exit 1
}
print_color "✅ Sintaxe válida" $GREEN
echo ""

# Dar permissão
chmod +x *.sh

# Executar instalação
print_color "🚀 Iniciando instalação..." $CYAN
print_color "═══════════════════════════════════════════════════════════" $CYAN
echo ""

# Executar com opção de entrar em modo interativo
if [ -f "install-panel-fixed.sh" ]; then
    bash install-panel-fixed.sh
else
    print_color "❌ Script não encontrado!" $RED
    exit 1
fi

# Limpeza
print_color "🧹 Limpando arquivos temporários..." $YELLOW
cd /
rm -rf "$TEMP_DIR"

print_color "✅ Instalação concluída com sucesso!" $GREEN
echo ""
print_color "═══════════════════════════════════════════════════════════" $CYAN
print_color "🎉 PAINEL INSTALADO COM SUCESSO!" $GREEN
print_color "═══════════════════════════════════════════════════════════" $CYAN
echo ""
print_color "📍 Próximos passos:" $CYAN
print_color "   1. cd /opt/panel-completo" $CYAN
print_color "   2. ./scripts/generate-all-configs.sh" $CYAN
print_color "   3. ./scripts/panel-control.sh start" $CYAN
print_color "   4. Acesse: http://seu-dominio:8080" $CYAN
echo ""
print_color "📚 Documentação:" $CYAN
print_color "   GitHub: $REPO_URL" $CYAN
echo ""
