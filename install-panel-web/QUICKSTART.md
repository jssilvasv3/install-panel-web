# ⚡ QUICK START - Instalação em 5 Minutos

## 🚀 Início Rápido

### 1️⃣ Download (30 segundos)

```bash
# Criar diretório
mkdir ~/install-panel && cd ~/install-panel

# Baixar scripts
wget https://seu-servidor/install-panel-fixed.sh
wget https://seu-servidor/generate-all-configs.sh

# Dar permissão
chmod +x *.sh
```

### 2️⃣ Teste (1 minuto)

```bash
# Testar sintaxe dos scripts
bash -n install-panel-fixed.sh
bash -n generate-all-configs.sh

# Ver output
echo "Scripts validados ✅"
```

### 3️⃣ Instalação (5-15 minutos)

```bash
# Executar como root
sudo ./install-panel-fixed.sh

# Responder as perguntas:
# - Digite seu domínio: seu-dominio.com
# - Digite seu email: seu-email@gmail.com

# Aguardar conclusão...
```

### 4️⃣ Configuração (1 minuto)

```bash
# Gerar configurações
cd /opt/panel-completo
./scripts/generate-all-configs.sh

# Output mostrará:
# ✅ TODAS AS CONFIGURAÇÕES GERADAS COM SUCESSO!
```

### 5️⃣ Iniciar (30 segundos)

```bash
# Iniciar serviços
./scripts/panel-control.sh start

# Verificar status
./scripts/panel-control.sh status

# Acessar painel
# http://seu-dominio:8080
```

---

## 📊 O Que Será Instalado

```
✅ 9 Protocolos
   • Hysteria2
   • TUIC 5
   • Xray REALITY
   • Trojan-Go
   • ShadowTLS V3
   • Shadowsocks + Cloak
   • gOST
   • WireGuard
   • OpenVPN

✅ Interface Web
   • Dashboard em tempo real
   • Gerenciamento de clientes
   • Geração de QR Codes
   • Download de configurações

✅ Ferramentas de Controle
   • Start/Stop/Restart
   • Visualização de logs
   • Status dos serviços
   • Gerenciamento de PIDs

✅ Segurança
   • Certificados SSL (Let's Encrypt)
   • Senhas aleatórias
   • UUIDs únicos
   • Logs de auditoria
```

---

## ⚙️ Comandos Essenciais

```bash
# Iniciar todos os serviços
/opt/panel-completo/scripts/panel-control.sh start

# Parar todos os serviços
/opt/panel-completo/scripts/panel-control.sh stop

# Reiniciar todos os serviços
/opt/panel-completo/scripts/panel-control.sh restart

# Verificar status
/opt/panel-completo/scripts/panel-control.sh status

# Ver logs de um serviço
/opt/panel-completo/scripts/panel-control.sh logs hysteria

# Ver logs de instalação
tail -f /opt/panel-completo/logs/install-errors.log
```

---

## 📱 Acessar Painel

```
URL: http://seu-dominio:8080
Usuário: Configurado durante instalação
Senha: Gerado automaticamente
```

---

## 🔧 Configurações Rápidas

### Mudar Porta (443 → 8443)

```bash
# Editar Hysteria2
nano /opt/panel-completo/config/hysteria2/config.json
# De: "listen": ":443"
# Para: "listen": ":8443"

# Editar TUIC
nano /opt/panel-completo/config/tuic/config.toml
# De: listen = "[::]:443"
# Para: listen = "[::]:8443"

# Reiniciar
./scripts/panel-control.sh restart
```

### Adicionar Novo Usuário (Hysteria2)

```bash
nano /opt/panel-completo/config/hysteria2/config.json
# Alterar "password": "sua-nova-senha"
./scripts/panel-control.sh restart
```

---

## 📋 Requisitos Mínimos

```
OS:        Debian, Ubuntu, CentOS, Fedora
Privilégio: root/sudo
Memória:   2GB RAM (mínimo)
Disco:     10GB (mínimo)
Rede:      Conexão com Internet
Porta:     443 disponível (ou outra configurável)
```

---

## 🆘 Problemas Comuns

### ❌ "Permissão negada"
```bash
# Solução:
sudo chmod +x install-panel-fixed.sh
sudo ./install-panel-fixed.sh
```

### ❌ "Porta já em uso"
```bash
# Ver qual processo usa a porta
sudo lsof -i :443

# Mudar para outra porta nos arquivos de config
# Depois reiniciar
./scripts/panel-control.sh restart
```

### ❌ "Serviço não inicia"
```bash
# Ver o erro
./scripts/panel-control.sh logs hysteria

# Ou verificar o arquivo de log
tail -f /opt/panel-completo/logs/hysteria.log
```

### ❌ "Conexão recusada na porta 8080"
```bash
# Verificar se interface web está rodando
ps aux | grep server.py

# Reiniciar manualmente
python3 /opt/panel-completo/web/server.py

# Ou usar o script de controle
./scripts/panel-control.sh start
```

---

## ✅ Verificação Pós-Instalação

```bash
# 1. Verificar se tudo foi criado
ls -la /opt/panel-completo/

# 2. Verificar permissões
ls -la /opt/panel-completo/certs/

# 3. Verificar serviços rodando
./scripts/panel-control.sh status

# 4. Testar conectividade
curl http://seu-dominio:8080

# 5. Verificar logs
tail -50 /opt/panel-completo/logs/install-errors.log
```

---

## 📞 Suporte Rápido

| Problema | Solução |
|----------|---------|
| Script não executa | `chmod +x *.sh` |
| Permissão negada | Use `sudo` |
| Porta em uso | Mude no arquivo de config |
| Serviço não inicia | Veja `logs/install-errors.log` |
| Interface web não abre | Restart: `./scripts/panel-control.sh restart` |
| Certificado expirado | Execute: `sudo certbot renew` |

---

## 🎯 Próximos Passos

Após instalação bem-sucedida:

1. **📊 Acessar o Painel**
   - http://seu-dominio:8080
   - Gerenciar clientes

2. **🔐 Configurar Firewall**
   - Liberar porta 443 (TCP/UDP)
   - Liberar porta 8080 (TCP)

3. **📱 Testar com Cliente**
   - Gerar configuração
   - Importar no cliente
   - Testar conexão

4. **🔄 Monitorar**
   - Verificar logs regularmente
   - Atualizar binários periodicamente
   - Fazer backup de configurações

5. **🔐 Renovar Certificados**
   - Let's Encrypt: automático
   - Auto-assinado: a cada 365 dias

---

## 📚 Documentação Completa

Para mais detalhes, consulte:

- **README.md** - Guia completo de uso
- **CORRECTIONS.md** - Detalhamento técnico
- **DEPLOYMENT.md** - Deploy em produção
- **SUMMARY.md** - Resumo executivo

---

## 💡 Dicas Pro

### 🚀 Performance
```bash
# Aumentar limite de conexões
ulimit -n 100000

# Adicionar ao /etc/security/limits.conf
* soft nofile 100000
* hard nofile 100000
```

### 📊 Monitoramento
```bash
# Instalar Netdata para monitoramento
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
sh /tmp/netdata-kickstart.sh
```

### 🔄 Auto-restart
```bash
# Adicionar ao cron
(crontab -l 2>/dev/null; echo "@reboot /opt/panel-completo/scripts/panel-control.sh start") | crontab -
```

### 📅 Backup Automático
```bash
# Script no /etc/cron.daily/
#!/bin/bash
tar czf /backup/panel_$(date +%Y%m%d).tar.gz /opt/panel-completo/config /opt/panel-completo/certs
```

---

## 🎓 Comandos Úteis

```bash
# Ver espaço em disco
df -h

# Ver memória disponível
free -h

# Ver processos rodando
top

# Ver logs em tempo real
tail -f /opt/panel-completo/logs/*.log

# Verificar porta
netstat -tuln | grep 443

# Testar conectividade
curl -I http://seu-dominio:8080

# Editar config
nano /opt/panel-completo/config/hysteria2/config.json

# Backup rápido
cp -r /opt/panel-completo /backup/
```

---

## ⏱️ Tempo Estimado

| Etapa | Tempo |
|-------|-------|
| Download | 30 seg |
| Teste sintaxe | 1 min |
| Instalação | 5-15 min |
| Configuração | 1 min |
| Inicialização | 30 seg |
| **Total** | **8-18 min** |

---

**🟢 Status: Pronto para Usar ✅**

Qualquer dúvida, consulte a documentação completa ou os logs!

**Boa sorte! 🚀**
