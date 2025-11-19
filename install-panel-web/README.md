# 🔥 Painel Completo - Todos os Protocolos

Script de instalação automático para um painel VPN/Proxy completo com suporte a múltiplos protocolos.

## ⚡ Instalação Rápida (Uma Linha!)

```bash
bash <(curl -sSL https://raw.githubusercontent.com/SEU-USERNAME/install-panel-web/main/install.sh)
```

**O que faz:**
✅ Baixa automaticamente todos os scripts  
✅ Valida integridade dos arquivos  
✅ Executa instalação completa  
✅ Configura 9 protocolos VPN/Proxy  
✅ Cria interface web  
✅ Ativa todos os serviços  

**Tempo:** 5-10 minutos | **Requisitos:** Linux, root, Internet

## 📋 Protocolos Suportados

- ⚡ **Hysteria2** - Protocolo UDP moderno com anti-censura
- 🚀 **TUIC 5** - Protocolo de alto desempenho baseado em QUIC
- 🛡️ **Xray REALITY** - VLESS com REALITY (sem TLS fingerprint)
- 🎭 **Trojan-Go** - Tráfego disfarçado de HTTPS
- 👻 **ShadowTLS V3** - Tunelamento TLS com sombra
- 🔒 **Shadowsocks + Cloak** - Clássico com camuflagem
- 🔄 **gOST** - FakeTLS + WSS + QUIC + HTTP2
- 🔄 **WireGuard** - VPN moderna e rápida
- 🔰 **OpenVPN + Obfs4** - Compatibilidade máxima

## ✅ Correções e Melhorias Implementadas

### Script `install-panel-fixed.sh`

✅ **Verificações de Pré-requisitos:**
- Verificação de privilégios root
- Detecção automática do SO (Debian, RedHat, Fedora)
- Validação de conectividade com internet
- Verificação de portas disponíveis

✅ **Tratamento de Erros:**
- Funções de log de erro e sucesso
- Validação de cada comando
- Arquivo de log centralizado
- Tratamento de falhas em downloads

✅ **Segurança:**
- Geração de certificados SSL (Let's Encrypt + auto-assinado)
- Senhas aleatórias geradas com OpenSSL
- UUIDs únicos para cada serviço
- Permissões adequadas nos arquivos

✅ **Entrada do Usuário:**
- Solicita domínio/IP do servidor
- Solicita email para certificados
- Validação de entrada
- Fallback para IP detectado automaticamente

✅ **Estrutura Organizada:**
- Diretórios bem estruturados
- Separação clara entre config, scripts e logs
- Scripts de controle unificados
- Interface web responsiva

### Script `generate-all-configs.sh`

✅ **Agora é Executável Independente:**
- Não mais embutido em heredoc
- Pode ser executado manualmente
- Aceita parâmetros de entrada
- Validações robustas

✅ **Configurações Completas:**
- Todos os 9 protocolos configurados
- Validação de diretórios
- Geração de senhas/UUIDs únicos
- Relatório final detalhado

## 🚀 Instalação Rápida

### Pré-requisitos
- Linux (Debian, Ubuntu, RedHat, CentOS, Fedora)
- Acesso root (sudo)
- Conexão com internet
- Porta 443 disponível (personalizável)

### Passo 1: Fazer Download
```bash
wget https://seu-servidor/install-panel-fixed.sh
chmod +x install-panel-fixed.sh
```

### Passo 2: Executar Instalação
```bash
sudo ./install-panel-fixed.sh
```

O script irá:
1. ✅ Verificar privilégios root
2. ✅ Detectar o sistema operacional
3. ✅ Validar conectividade
4. ✅ Solicitar domínio e email
5. ✅ Instalar dependências
6. ✅ Instalar Docker
7. ✅ Criar estrutura de diretórios
8. ✅ Gerar certificados SSL
9. ✅ Baixar binários dos protocolos
10. ✅ Criar scripts de serviço
11. ✅ Gerar configurações

### Passo 3: Gerar Configurações
```bash
cd /opt/panel-completo
./scripts/generate-all-configs.sh
```

Ou com parâmetros personalizados:
```bash
./generate-all-configs.sh ./config ./scripts seu-dominio.com 443
```

## 📋 Uso do Painel

### Controlar Serviços
```bash
# Iniciar todos os serviços
/opt/panel-completo/scripts/panel-control.sh start

# Parar todos os serviços
/opt/panel-completo/scripts/panel-control.sh stop

# Reiniciar todos os serviços
/opt/panel-completo/scripts/panel-control.sh restart

# Verificar status dos serviços
/opt/panel-completo/scripts/panel-control.sh status

# Ver logs de um serviço
/opt/panel-completo/scripts/panel-control.sh logs hysteria
```

### Acessar Interface Web
```
http://seu-dominio:8080
```

A interface permite:
- 📊 Visualizar status dos serviços
- 📋 Gerar configurações por protocolo
- 📱 QR Codes para clientes
- 📥 Download de configurações
- 🔄 Reiniciar serviços

## 📁 Estrutura de Diretórios

```
/opt/panel-completo/
├── config/              # Configurações de cada protocolo
│   ├── hysteria2/
│   ├── tuic/
│   ├── xray/
│   ├── trojan/
│   ├── shadowtls/
│   ├── shadowsocks/
│   ├── gost/
│   ├── wireguard/
│   └── openvpn/
├── scripts/             # Scripts executáveis
│   ├── hysteria
│   ├── tuic-server
│   ├── xray
│   ├── trojan-go
│   ├── panel-control.sh
│   └── *.pid
├── web/                 # Interface web
│   ├── index.html
│   └── server.py
├── clients/             # Clientes e configurações
│   ├── configs/
│   ├── qrcodes/
│   └── links/
├── logs/                # Logs dos serviços
│   ├── install-errors.log
│   ├── hysteria.log
│   ├── tuic.log
│   └── ...
└── certs/               # Certificados SSL
    ├── cert.crt
    └── key.key
```

## 🔐 Certificados SSL

O script gera automaticamente certificados SSL:

1. **Let's Encrypt** (para domínios reais)
   - Validade: 90 dias
   - Renovação automática recomendada

2. **Auto-assinado** (para IPs)
   - Validade: 365 dias
   - Para testes e desenvolvimento

## 📊 Logs

Todos os erros são registrados em:
```
/opt/panel-completo/logs/install-errors.log
```

Para verificar o log:
```bash
tail -f /opt/panel-completo/logs/install-errors.log
```

## 🔧 Configurações Avançadas

### Personalizar Porta
Edite os arquivos de configuração:
```bash
nano /opt/panel-completo/config/hysteria2/config.json
```

Altere a porta e reinicie:
```bash
/opt/panel-completo/scripts/panel-control.sh restart
```

### Adicionar Usuários
Cada protocolo tem um método diferente. Exemplos:

**Hysteria2:**
```bash
# Editar password em config.json
nano /opt/panel-completo/config/hysteria2/config.json
```

**TUIC:**
```bash
# Adicionar UUID em config.toml
nano /opt/panel-completo/config/tuic/config.toml
```

## 🆘 Solução de Problemas

### Erro: "Sistema não suportado"
- Sistema deve ser Debian, RedHat, CentOS ou Fedora
- Use `cat /etc/os-release` para verificar

### Erro: "Porta já está em uso"
- Mude a porta nos arquivos de configuração
- Ou pare o serviço que usa a porta

### Erro: "Certificado expirado"
Para Let's Encrypt:
```bash
certbot renew
```

Para auto-assinado:
```bash
# Regenerar certificados
openssl req -x509 -newkey rsa:2048 -keyout /opt/panel-completo/certs/key.key \
    -out /opt/panel-completo/certs/cert.crt -days 365 -nodes \
    -subj "/C=BR/ST=State/L=City/O=Panel/CN=seu-dominio.com"
```

### Serviço não inicia
Verificar logs:
```bash
/opt/panel-completo/scripts/panel-control.sh logs hysteria
tail -f /opt/panel-completo/logs/hysteria.log
```

## 📝 Arquivo de Parâmetros

Crie um arquivo `.env` para valores padrão:
```bash
# /opt/panel-completo/.env
DOMAIN="seu-dominio.com"
EMAIL="seu-email@gmail.com"
PORT="443"
PANEL_PORT="8080"
```

## 🔄 Atualizações

Para atualizar binários:
```bash
cd /opt/panel-completo
rm scripts/hysteria scripts/tuic-server scripts/xray scripts/trojan-go
./install-panel-fixed.sh  # Executar novamente
```

## 📞 Suporte

Em caso de problemas:
1. Verifique os logs: `/opt/panel-completo/logs/install-errors.log`
2. Execute novamente: `./install-panel-fixed.sh`
3. Verifique a conectividade: `ping 8.8.8.8`
4. Verifique portas: `netstat -tuln | grep 443`

## 📄 Licença

Script de código aberto para uso educacional e pessoal.

## ⚠️ Disclaimer

Este script é fornecido "como está". O uso em produção requer ajustes e testes apropriados. O autor não é responsável por misuso ou danos resultantes do uso deste script.

---

**Última atualização:** 18 de novembro de 2025

**Versão:** 2.0 (Corrigida e Melhorada)
