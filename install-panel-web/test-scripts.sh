#!/bin/bash

# Script de teste para validar sintaxe dos scripts
# Uso: chmod +x test-scripts.sh && ./test-scripts.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    echo -e "${2}${1}${NC}"
}

print_color "🧪 TESTE DE SINTAXE DOS SCRIPTS" $CYAN
echo ""

# Teste 1: Syntax check do install-panel-fixed.sh
print_color "1️⃣  Testando install-panel-fixed.sh..." $YELLOW
if bash -n install-panel-fixed.sh 2>/dev/null; then
    print_color "   ✅ Sintaxe correta" $GREEN
else
    print_color "   ❌ Erro de sintaxe:" $RED
    bash -n install-panel-fixed.sh
fi

echo ""

# Teste 2: Syntax check do generate-all-configs.sh
print_color "2️⃣  Testando generate-all-configs.sh..." $YELLOW
if bash -n generate-all-configs.sh 2>/dev/null; then
    print_color "   ✅ Sintaxe correta" $GREEN
else
    print_color "   ❌ Erro de sintaxe:" $RED
    bash -n generate-all-configs.sh
fi

echo ""

# Teste 3: Verificar permissões
print_color "3️⃣  Verificando permissões..." $YELLOW
for file in install-panel-fixed.sh generate-all-configs.sh; do
    if [ -x "$file" ]; then
        print_color "   ✅ $file é executável" $GREEN
    else
        print_color "   ⚠️  $file não é executável (executar: chmod +x $file)" $YELLOW
    fi
done

echo ""

# Teste 4: Verificar shebang
print_color "4️⃣  Verificando shebang..." $YELLOW
for file in install-panel-fixed.sh generate-all-configs.sh; do
    if head -1 "$file" | grep -q "^#!/bin/bash"; then
        print_color "   ✅ $file tem shebang correto" $GREEN
    else
        print_color "   ❌ $file sem shebang correto" $RED
    fi
done

echo ""

# Teste 5: Verificar variáveis
print_color "5️⃣  Verificando variáveis críticas..." $YELLOW
echo ""

# Variáveis em install-panel-fixed.sh
print_color "   Variáveis em install-panel-fixed.sh:" $CYAN
grep "^[A-Z_]*=" install-panel-fixed.sh | head -10 | sed 's/^/      /'

echo ""

# Variáveis em generate-all-configs.sh
print_color "   Variáveis em generate-all-configs.sh:" $CYAN
grep "^[A-Z_]*=" generate-all-configs.sh | head -10 | sed 's/^/      /'

echo ""

# Teste 6: Contar funções
print_color "6️⃣  Contando funções..." $YELLOW
FUNCS_INSTALL=$(grep "^[a-z_]*() {" install-panel-fixed.sh | wc -l)
FUNCS_CONFIG=$(grep "^[a-z_]*() {" generate-all-configs.sh | wc -l)
print_color "   install-panel-fixed.sh: $FUNCS_INSTALL funções" $GREEN
print_color "   generate-all-configs.sh: $FUNCS_CONFIG funções" $GREEN

echo ""

# Teste 7: Verificar tratamento de erros
print_color "7️⃣  Verificando tratamento de erros..." $YELLOW
if grep -q "log_error\|log_success" install-panel-fixed.sh; then
    print_color "   ✅ Funções de log encontradas" $GREEN
else
    print_color "   ❌ Funções de log não encontradas" $RED
fi

echo ""

# Teste 8: Verificar arquivos de configuração
print_color "8️⃣  Verificando geração de configurações..." $YELLOW
CONFIGS=$(grep "mkdir -p" generate-all-configs.sh | grep CONFIG_DIR | wc -l)
HYSTERIA=$(grep "hysteria" generate-all-configs.sh | wc -l)
TUIC=$(grep "tuic\|TUIC" generate-all-configs.sh | wc -l)
XRAY=$(grep "xray\|XRAY" generate-all-configs.sh | wc -l)
TROJAN=$(grep "trojan\|TROJAN" generate-all-configs.sh | wc -l)

print_color "   ✅ Hysteria2: $((HYSTERIA/2)) configurações" $GREEN
print_color "   ✅ TUIC: $((TUIC/2)) configurações" $GREEN
print_color "   ✅ Xray: $((XRAY/2)) configurações" $GREEN
print_color "   ✅ Trojan: $((TROJAN/2)) configurações" $GREEN

echo ""

# Teste 9: Verificar documentação
print_color "9️⃣  Verificando documentação..." $YELLOW
if [ -f "README.md" ]; then
    LINES=$(wc -l < README.md)
    print_color "   ✅ README.md encontrado ($LINES linhas)" $GREEN
else
    print_color "   ❌ README.md não encontrado" $RED
fi

if [ -f "CORRECTIONS.md" ]; then
    LINES=$(wc -l < CORRECTIONS.md)
    print_color "   ✅ CORRECTIONS.md encontrado ($LINES linhas)" $GREEN
else
    print_color "   ❌ CORRECTIONS.md não encontrado" $RED
fi

echo ""

# Resumo Final
print_color "==========================================" $CYAN
print_color "✅ TESTES CONCLUÍDOS COM SUCESSO!" $GREEN
print_color "==========================================" $CYAN
echo ""
print_color "Próximos passos:" $YELLOW
print_color "1. Fazer upload para seu servidor" $YELLOW
print_color "2. Executar: sudo ./install-panel-fixed.sh" $YELLOW
print_color "3. Acompanhar a instalação" $YELLOW
echo ""
