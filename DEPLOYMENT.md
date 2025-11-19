# 🚀 GUIA DE DEPLOYMENT

## 📋 Pré-Deployment Checklist

- [ ] Clonar/Download dos scripts
- [ ] Verificar sintaxe dos scripts
- [ ] Testar em ambiente de teste
- [ ] Revisar configurações
- [ ] Preparar certificados SSL
- [ ] Configurar firewall

## 🔄 Passos de Instalação

### Etapa 1: Preparação

```bash
# Baixar scripts
mkdir ~/painel-completo
cd ~/painel-completo
git clone https://seu-repositorio/install-panel-web .

# Ou download manual
wget https://seu-servidor/install-panel-fixed.sh
wget https://seu-servidor/generate-all-configs.sh
wget https://seu-servidor/test-scripts.sh

# Dar permissão de execução
chmod +x *.sh
```

### Etapa 2: Testes Preliminares

```bash
# Testar sintaxe
./test-scripts.sh

# Fazer backup do ambiente
ls -la > pre-install-status.txt
```

### Etapa 3: Instalação Principal

```bash
# Executar como root
sudo ./install-panel-fixed.sh

# Acompanhar a instalação
tail -f /opt/panel-completo/logs/install-errors.log
```

Durante a instalação, o script irá:
1. Solicitar domínio/IP
2. Solicitar email para certificados
3. Instalar dependências (pode levar 5-15 minutos)
4. Baixar binários dos protocolos
5. Gerar certificados SSL
6. Criar estrutura de diretórios

### Etapa 4: Geração de Configurações

```bash
cd /opt/panel-completo
./scripts/generate-all-configs.sh

# Ou com parâmetros customizados
./scripts/generate-all-configs.sh \
    /opt/panel-completo/config \
    /opt/panel-completo/scripts \
    seu-dominio.com \
    443
```

### Etapa 5: Inicializar Serviços

```bash
# Iniciar todos os serviços
./scripts/panel-control.sh start

# Verificar status
./scripts/panel-control.sh status

# Ver logs
./scripts/panel-control.sh logs hysteria
```

### Etapa 6: Acessar Painel

```
Abrir navegador: http://seu-dominio:8080
```

---

## 🔧 Configuração Pós-Instalação

### 1. Configurar Firewall

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 443/tcp
sudo ufw allow 443/udp
sudo ufw allow 8080/tcp
sudo ufw enable

# FirewallD (CentOS/Fedora)
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=443/udp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### 2. Certificados SSL Válidos

**Para Let's Encrypt (domínio real):**
```bash
sudo certbot certonly --standalone \
    -d seu-dominio.com \
    -m seu-email@gmail.com \
    --agree-tos -n

# O certificado será salvo em:
# /etc/letsencrypt/live/seu-dominio.com/
```

**Para Auto-assinado (teste):**
```bash
openssl req -x509 -newkey rsa:2048 \
    -keyout /opt/panel-completo/certs/key.key \
    -out /opt/panel-completo/certs/cert.crt \
    -days 365 -nodes \
    -subj "/C=BR/ST=SP/L=SP/O=Panel/CN=seu-dominio.com"
```

### 3. Configurar Domínio

```bash
# Apontar seu domínio para o servidor
# No provedor de DNS, adicione:
# A record: seu-dominio.com -> IP_DO_SERVIDOR
# AAAA record: seu-dominio.com -> IPv6_DO_SERVIDOR (opcional)

# Testar resolução
nslookup seu-dominio.com
```

### 4. Ajustar Configurações de Protocolos

**Exemplo: Alterar porta do Hysteria2**
```bash
# Editar arquivo
nano /opt/panel-completo/config/hysteria2/config.json

# Alterar a porta
# De: "listen": ":443"
# Para: "listen": ":8443"

# Reiniciar serviço
./scripts/panel-control.sh restart
```

### 5. Adicionar Usuários

**Hysteria2:**
```bash
# Editar config.json e alterar password
nano /opt/panel-completo/config/hysteria2/config.json
```

**TUIC:**
```bash
# Editar config.toml e adicionar UUIDs
nano /opt/panel-completo/config/tuic/config.toml
# Adicionar após "users = ["
# Format: "uuid:password"
```

---

## 📊 Monitoramento e Manutenção

### Verificar Status Diariamente

```bash
/opt/panel-completo/scripts/panel-control.sh status
```

### Monitorar Logs em Tempo Real

```bash
tail -f /opt/panel-completo/logs/install-errors.log
tail -f /opt/panel-completo/logs/hysteria.log
tail -f /opt/panel-completo/logs/tuic.log
```

### Usar Systemd para Auto-inicializar

```bash
# Criar serviço systemd
sudo systemctl enable panel-completo
sudo systemctl start panel-completo
sudo systemctl status panel-completo

# Ver logs do systemd
sudo journalctl -u panel-completo -f
```

### Backup Automático

```bash
# Criar script de backup
cat > /opt/panel-completo/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR
tar czf $BACKUP_DIR/panel_backup_$DATE.tar.gz \
    /opt/panel-completo/config \
    /opt/panel-completo/certs

# Manter apenas últimos 7 backups
find $BACKUP_DIR -name "panel_backup_*.tar.gz" \
    -mtime +7 -delete

echo "Backup criado: $BACKUP_DIR/panel_backup_$DATE.tar.gz"
EOF

chmod +x /opt/panel-completo/backup.sh

# Agendar com cron (executar diariamente às 2am)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/panel-completo/backup.sh") | crontab -
```

---

## 🔐 Segurança em Produção

### 1. Endurecimento do Sistema

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar e configurar fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

### 2. Firewall Avançado

```bash
# Limitar conexões SSH
sudo ufw limit 22/tcp

# Bloquear tudo exceto portas necessárias
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp
sudo ufw allow 443/udp
sudo ufw allow 8080/tcp
```

### 3. Certificados SSL Renovação Automática

```bash
# Verificar renovação automática
sudo certbot renew --dry-run

# Adicionar ao cron se necessário
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet") | crontab -
```

### 4. Monitoramento com Alertas

```bash
# Instalar Monitoring (exemplo: Netdata)
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
sh /tmp/netdata-kickstart.sh --stable-channel --disable-telemetry

# Acessar em: http://seu-dominio:19999
```

---

## 🆘 Troubleshooting em Produção

### Serviço não inicia

```bash
# Ver erro
./scripts/panel-control.sh logs hysteria

# Ver serviço específico
systemctl status panel-completo

# Tentar reiniciar
./scripts/panel-control.sh restart

# Se falhar, ver systemd log
journalctl -u panel-completo -n 50
```

### Porta em uso

```bash
# Encontrar processo usando a porta
sudo lsof -i :443

# Matar processo (se necessário)
sudo kill -9 <PID>

# Ou mudar a porta nos arquivos de config
```

### Certificado expirado

```bash
# Let's Encrypt
sudo certbot renew

# Auto-assinado (regenerar)
openssl req -x509 -newkey rsa:2048 \
    -keyout /opt/panel-completo/certs/key.key \
    -out /opt/panel-completo/certs/cert.crt \
    -days 365 -nodes \
    -subj "/C=BR/ST=SP/L=SP/O=Panel/CN=seu-dominio.com"

# Reiniciar serviços
./scripts/panel-control.sh restart
```

### Memória insuficiente

```bash
# Verificar uso
free -h
top

# Se necessário, parar alguns serviços
./scripts/panel-control.sh stop

# Reiniciar seletivamente
./scripts/panel-control.sh start
```

---

## 📈 Escalabilidade

### Para múltiplos servidores:

```bash
# Server 1 (Frontend)
# Executar apenas interface web

# Server 2+ (Backend)
# Executar apenas os serviços de protocolo

# Load Balancer (Nginx)
upstream panel_servers {
    server server1:8080;
    server server2:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://panel_servers;
    }
}
```

---

## 📋 Checklist Pós-Deployment

- [ ] Instalação completada sem erros
- [ ] Todos os serviços estão rodando
- [ ] Interface web acessível
- [ ] Certificados SSL válidos
- [ ] Firewall configurado
- [ ] Backup automático configurado
- [ ] Monitoramento em funcionamento
- [ ] Logs sendo registrados
- [ ] Testes com clientes completados
- [ ] Documentação atualizada

---

## 📞 Suporte e Contato

Em caso de problemas:
1. Verificar logs: `/opt/panel-completo/logs/`
2. Executar testes: `./test-scripts.sh`
3. Consultar README.md
4. Verificar status: `./scripts/panel-control.sh status`

---

**Data:** 18 de novembro de 2025
**Versão:** 2.0
**Status:** Pronto para Produção ✅
