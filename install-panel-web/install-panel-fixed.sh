#!/bin/bash

# Painel Completo - Todos os Protocolos
# Script de instalação automático - VERSÃO CORRIGIDA

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variáveis globais
PANEL_DIR="/opt/panel-completo"
CONFIG_DIR="$PANEL_DIR/config"
SCRIPTS_DIR="$PANEL_DIR/scripts"
LOG_DIR="$PANEL_DIR/logs"
DOMAIN=""
EMAIL=""
ERROR_LOG="$LOG_DIR/install-errors.log"

# Função para imprimir com cores
print_color() {
    echo -e "${2}${1}${NC}"
}

# Função para log de erros
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"
    print_color "❌ ERRO: $1" $RED
}

# Função para log de sucesso
log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$ERROR_LOG"
    print_color "✅ $1" $GREEN
}

# Função para verificar se é root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script deve ser executado como root!"
        exit 1
    fi
    log_success "Verificação de root passou"
}

# Função para detectar sistema
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    print_color "🖥️  Sistema detectado: $OS $VER" $CYAN
}

# Função para solicitar entrada do usuário
get_user_input() {
    read -p "$(print_color '📝 Digite o domínio ou IP do servidor: ' $YELLOW)" DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        DOMAIN=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
        print_color "⚠️  Usando IP detectado: $DOMAIN" $YELLOW
    fi
    
    read -p "$(print_color '📧 Digite o email (opcional, para certificados): ' $YELLOW)" EMAIL
    EMAIL=${EMAIL:-"admin@$DOMAIN"}
    
    print_color "✅ Configurações:" $GREEN
    print_color "   Domínio/IP: $DOMAIN" $GREEN
    print_color "   Email: $EMAIL" $GREEN
}

# Função para validar conectividade
check_connectivity() {
    print_color "🌐 Verificando conectividade..." $CYAN
    
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_error "Sem conexão com internet! Instale as dependências manualmente."
        exit 1
    fi
    log_success "Conexão com internet OK"
}

# Função para verificar se porta está disponível
check_port() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        print_color "⚠️  Porta $port já está em uso" $YELLOW
        return 1
    fi
    return 0
}

# Função para instalar dependências
install_dependencies() {
    print_color "📦 Instalando dependências..." $YELLOW
    
    if command -v apt &> /dev/null; then
        apt update || log_error "Falha ao atualizar apt"
        apt install -y curl wget git python3 python3-pip nodejs npm build-essential \
            libssl-dev zlib1g-dev libpcre3-dev libev-dev cmake golang-go \
            qrencode jq net-tools openssl certbot nginx || log_error "Falha ao instalar dependências com apt"
    elif command -v yum &> /dev/null; then
        yum install -y curl wget git python3 python3-pip nodejs npm gcc-c++ \
            openssl-devel pcre-devel libev-devel cmake golang \
            qrencode jq net-tools openssl certbot nginx || log_error "Falha ao instalar dependências com yum"
    elif command -v dnf &> /dev/null; then
        dnf install -y curl wget git python3 python3-pip nodejs npm gcc-c++ \
            openssl-devel pcre-devel libev-devel cmake golang \
            qrencode jq net-tools openssl certbot nginx || log_error "Falha ao instalar dependências com dnf"
    else
        log_error "Gerenciador de pacotes não suportado. Instale manualmente: apt, yum ou dnf"
        exit 1
    fi
    
    log_success "Dependências instaladas"
}

# Função para instalar Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        print_color "🐳 Instalando Docker..." $YELLOW
        
        if curl -fsSL https://get.docker.com -o get-docker.sh 2>/dev/null; then
            sh get-docker.sh || log_error "Falha ao instalar Docker via script oficial"
            systemctl start docker 2>/dev/null || log_error "Falha ao iniciar Docker"
            systemctl enable docker 2>/dev/null || log_error "Falha ao ativar Docker no boot"
            rm -f get-docker.sh
            log_success "Docker instalado"
        else
            log_error "Não foi possível baixar script de instalação do Docker"
            exit 1
        fi
    else
        log_success "Docker já está instalado"
    fi
}

# Função para criar estrutura de diretórios
create_structure() {
    print_color "📁 Criando estrutura de diretórios..." $BLUE
    
    mkdir -p "$PANEL_DIR"/{config,scripts,web,logs,clients,certs} || log_error "Falha ao criar diretórios principais"
    mkdir -p "$CONFIG_DIR"/{hysteria2,tuic,xray,trojan,shadowtls,shadowsocks,gost,wireguard,openvpn} || log_error "Falha ao criar diretórios de protocolo"
    mkdir -p "$PANEL_DIR/clients"/{configs,qrcodes,links} || log_error "Falha ao criar diretórios de clientes"
    
    touch "$ERROR_LOG"
    chmod 600 "$ERROR_LOG"
    
    log_success "Estrutura de diretórios criada"
}

# Função para gerar certificados SSL
generate_certificates() {
    print_color "🔐 Gerando certificados SSL..." $BLUE
    
    local CERT_DIR="$PANEL_DIR/certs"
    
    # Criar auto-assinado se não for um domínio real
    if [[ ! "$DOMAIN" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_color "📜 Tentando Let's Encrypt para $DOMAIN..." $CYAN
        
        if certbot certonly --standalone -d "$DOMAIN" -m "$EMAIL" --agree-tos -n 2>/dev/null; then
            log_success "Certificado Let's Encrypt obtido"
            return 0
        fi
    fi
    
    # Fallback: auto-assinado
    print_color "⚠️  Usando certificado auto-assinado" $YELLOW
    openssl req -x509 -newkey rsa:2048 -keyout "$CERT_DIR/key.key" \
        -out "$CERT_DIR/cert.crt" -days 365 -nodes \
        -subj "/C=BR/ST=State/L=City/O=Panel/CN=$DOMAIN" 2>/dev/null || \
        log_error "Falha ao gerar certificado auto-assinado"
    
    chmod 600 "$CERT_DIR/key.key" "$CERT_DIR/cert.crt"
    log_success "Certificados prontos em $CERT_DIR"
}

# Função para baixar e compilar binários
install_binaries() {
    print_color "⚙️  Instalando/Compilando binários dos protocolos..." $PURPLE
    
    # Hysteria2
    if [ ! -f "$SCRIPTS_DIR/hysteria" ]; then
        print_color "📥 Baixando Hysteria2..." $CYAN
        if wget -q -O "$SCRIPTS_DIR/hysteria" \
            "https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64" 2>/dev/null; then
            chmod +x "$SCRIPTS_DIR/hysteria"
            log_success "Hysteria2 instalado"
        else
            log_error "Falha ao baixar Hysteria2"
        fi
    fi
    
    # TUIC
    if [ ! -f "$SCRIPTS_DIR/tuic-server" ]; then
        print_color "📥 Baixando TUIC..." $CYAN
        if wget -q -O "$SCRIPTS_DIR/tuic-server" \
            "https://github.com/apernet/tuic/releases/latest/download/tuic-server-linux-amd64" 2>/dev/null; then
            chmod +x "$SCRIPTS_DIR/tuic-server"
            log_success "TUIC instalado"
        else
            log_error "Falha ao baixar TUIC"
        fi
    fi
    
    # Xray-core
    if [ ! -f "$SCRIPTS_DIR/xray" ]; then
        print_color "📥 Baixando Xray..." $CYAN
        if wget -q -O /tmp/xray.zip \
            "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" 2>/dev/null; then
            unzip -q -o /tmp/xray.zip -d "$SCRIPTS_DIR/" 2>/dev/null
            chmod +x "$SCRIPTS_DIR/xray"
            rm -f /tmp/xray.zip
            log_success "Xray instalado"
        else
            log_error "Falha ao baixar Xray"
        fi
    fi
    
    # Trojan-Go
    if [ ! -f "$SCRIPTS_DIR/trojan-go" ]; then
        print_color "📥 Baixando Trojan-Go..." $CYAN
        if wget -q -O /tmp/trojan-go.zip \
            "https://github.com/p4gefau1t/trojan-go/releases/latest/download/trojan-go-linux-amd64.zip" 2>/dev/null; then
            unzip -q -o /tmp/trojan-go.zip -d "$SCRIPTS_DIR/" 2>/dev/null
            chmod +x "$SCRIPTS_DIR/trojan-go"
            rm -f /tmp/trojan-go.zip
            log_success "Trojan-Go instalado"
        else
            log_error "Falha ao baixar Trojan-Go"
        fi
    fi
}

# Função para criar scripts de serviço
create_service_scripts() {
    print_color "🛠️  Criando scripts de serviço..." $BLUE
    
    # Script principal de controle
    cat > "$SCRIPTS_DIR/panel-control.sh" << 'EOF'
#!/bin/bash

PANEL_DIR="/opt/panel-completo"
CONFIG_DIR="$PANEL_DIR/config"
SCRIPTS_DIR="$PANEL_DIR/scripts"
LOG_DIR="$PANEL_DIR/logs"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    echo -e "${2}${1}${NC}"
}

start_services() {
    print_color "🚀 Iniciando serviços..." $CYAN
    
    mkdir -p "$LOG_DIR"
    
    # Hysteria2
    if [ -f "$CONFIG_DIR/hysteria/config.json" ] && [ -f "$SCRIPTS_DIR/hysteria" ]; then
        "$SCRIPTS_DIR/hysteria" server --config "$CONFIG_DIR/hysteria/config.json" > "$LOG_DIR/hysteria.log" 2>&1 &
        echo $! > "$SCRIPTS_DIR/hysteria.pid"
        print_color "   Hysteria2: iniciado (PID: $!)" $GREEN
    fi
    
    # TUIC
    if [ -f "$CONFIG_DIR/tuic/config.toml" ] && [ -f "$SCRIPTS_DIR/tuic-server" ]; then
        "$SCRIPTS_DIR/tuic-server" --config "$CONFIG_DIR/tuic/config.toml" > "$LOG_DIR/tuic.log" 2>&1 &
        echo $! > "$SCRIPTS_DIR/tuic.pid"
        print_color "   TUIC: iniciado (PID: $!)" $GREEN
    fi
    
    print_color "✅ Serviços iniciados!" $GREEN
}

stop_services() {
    print_color "⛔ Parando serviços..." $YELLOW
    
    for pid_file in "$SCRIPTS_DIR"/*.pid; do
        if [ -f "$pid_file" ]; then
            PID=$(cat "$pid_file")
            if kill "$PID" 2>/dev/null; then
                print_color "   Processo $PID finalizado" $GREEN
            fi
            rm -f "$pid_file"
        fi
    done
    
    print_color "✅ Serviços parados!" $GREEN
}

restart_services() {
    stop_services
    sleep 2
    start_services
}

show_status() {
    print_color "📊 Status dos Serviços:" $CYAN
    echo ""
    
    for service in hysteria tuic xray trojan shadowtls; do
        if [ -f "$SCRIPTS_DIR/${service}.pid" ]; then
            PID=$(cat "$SCRIPTS_DIR/${service}.pid")
            if kill -0 "$PID" 2>/dev/null; then
                print_color "   $service: 🟢 ATIVO (PID: $PID)" $GREEN
            else
                print_color "   $service: 🔴 INATIVO" $RED
            fi
        else
            print_color "   $service: 🔴 NÃO INICIADO" $RED
        fi
    done
    echo ""
}

show_logs() {
    local service=$1
    if [ -f "$LOG_DIR/${service}.log" ]; then
        print_color "📝 Logs de $service:" $CYAN
        tail -20 "$LOG_DIR/${service}.log"
    else
        print_color "❌ Log de $service não encontrado" $RED
    fi
}

case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    *)
        print_color "Uso: $0 {start|stop|restart|status|logs <service>}" $YELLOW
        exit 1
        ;;
esac
EOF

    chmod +x "$SCRIPTS_DIR/panel-control.sh"
    log_success "Scripts de serviço criados"
}

# Função para criar interface web
create_web_interface() {
    print_color "🌐 Criando interface web do painel..." $PURPLE
    
    cat > "$PANEL_DIR/web/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Painel Completo - Todos os Protocolos</title>
    <style>
        :root {
            --primary: #2563eb;
            --secondary: #7c3aed;
            --success: #059669;
            --danger: #dc2626;
            --warning: #d97706;
            --dark: #1f2937;
            --light: #f3f4f6;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            text-align: center;
            color: white;
            margin-bottom: 30px;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        .protocols-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .protocol-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .protocol-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 35px rgba(0,0,0,0.3);
        }
        
        .protocol-header {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--light);
        }
        
        .protocol-icon {
            font-size: 2rem;
            margin-right: 15px;
        }
        
        .protocol-title {
            font-size: 1.4rem;
            font-weight: bold;
            color: var(--dark);
        }
        
        .btn {
            padding: 10px 15px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s ease;
            margin: 5px 0;
            width: 100%;
        }
        
        .btn-primary { background: var(--primary); color: white; }
        .btn-primary:hover { background: #1d4ed8; }
        
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.8);
            z-index: 1000;
            align-items: center;
            justify-content: center;
        }
        
        .modal-content {
            background: white;
            padding: 30px;
            border-radius: 15px;
            max-width: 500px;
            width: 90%;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔥 PAINEL COMPLETO</h1>
            <p>Todos os protocolos no mesmo lugar</p>
        </div>
        
        <div class="protocols-grid">
            <div class="protocol-card">
                <div class="protocol-header">
                    <div class="protocol-icon">⚡</div>
                    <div class="protocol-title">Hysteria2</div>
                </div>
                <p>Protocolo UDP moderno com anti-censura</p>
                <button class="btn btn-primary">📋 Configurar</button>
            </div>
            
            <div class="protocol-card">
                <div class="protocol-header">
                    <div class="protocol-icon">🚀</div>
                    <div class="protocol-title">TUIC 5</div>
                </div>
                <p>Protocolo de alto desempenho baseado em QUIC</p>
                <button class="btn btn-primary">📋 Configurar</button>
            </div>
            
            <div class="protocol-card">
                <div class="protocol-header">
                    <div class="protocol-icon">🛡️</div>
                    <div class="protocol-title">Xray REALITY</div>
                </div>
                <p>VLESS com REALITY - Sem TLS fingerprint</p>
                <button class="btn btn-primary">📋 Configurar</button>
            </div>
        </div>
    </div>

    <div class="modal" id="configModal">
        <div class="modal-content">
            <h3 id="modalTitle">Configuração</h3>
            <div id="modalContent"></div>
            <button class="btn btn-primary" onclick="closeModal()">Fechar</button>
        </div>
    </div>

    <script>
        function closeModal() {
            document.getElementById('configModal').style.display = 'none';
        }
    </script>
</body>
</html>
EOF

    # Servidor web Python
    cat > "$PANEL_DIR/web/server.py" << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import json

PORT = 8080
WEB_DIR = "/opt/panel-completo/web"

class PanelHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)
    
    def do_GET(self):
        if self.path == '/status':
            self.send_json({'status': 'online'})
        else:
            super().do_GET()
    
    def send_json(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

if __name__ == "__main__":
    os.chdir(WEB_DIR)
    with socketserver.TCPServer(("", PORT), PanelHandler) as httpd:
        print(f"Servidor rodando em http://0.0.0.0:{PORT}")
        httpd.serve_forever()
EOF

    chmod +x "$PANEL_DIR/web/server.py"
    log_success "Interface web criada"
}

# Função para criar configurações dos protocolos
create_configs() {
    print_color "⚙️  Gerando configurações dos protocolos..." $PURPLE
    
    local UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)
    local PASSWORD=$(openssl rand -hex 16 2>/dev/null)
    
    # Hysteria2
    cat > "$CONFIG_DIR/hysteria/config.json" << HYSTERIA
{
    "listen": ":443",
    "acme": {
        "domains": ["$DOMAIN"],
        "email": "$EMAIL"
    },
    "obfs": {
        "type": "salamander",
        "password": "$PASSWORD"
    },
    "auth": {
        "type": "password",
        "password": "$PASSWORD"
    }
}
HYSTERIA

    # TUIC
    cat > "$CONFIG_DIR/tuic/config.toml" << TUIC
[server]
listen = "[::]:443"
users = ["$UUID"]

[server.congestion_control]
algorithm = "bbr"

[server.log]
level = "warn"
TUIC

    # Xray
    cat > "$CONFIG_DIR/xray/config.json" << XRAY
{
    "inbounds": [{
        "port": 443,
        "protocol": "vless",
        "settings": {
            "clients": [{
                "id": "$UUID",
                "flow": "xtls-rprx-vision"
            }],
            "decryption": "none"
        },
        "streamSettings": {
            "network": "tcp",
            "security": "reality",
            "realitySettings": {
                "show": false,
                "dest": "www.google.com:443"
            }
        }
    }],
    "outbounds": [{
        "protocol": "freedom"
    }]
}
XRAY

    # Trojan
    cat > "$CONFIG_DIR/trojan/config.json" << TROJAN
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": ["$PASSWORD"],
    "ssl": {
        "cert": "$PANEL_DIR/certs/cert.crt",
        "key": "$PANEL_DIR/certs/key.key"
    }
}
TROJAN

    log_success "Configurações dos protocolos criadas"
}

# Função principal
main_install() {
    print_color "🚀 INICIANDO INSTALAÇÃO DO PAINEL COMPLETO" $GREEN
    print_color "==========================================" $GREEN
    echo ""
    
    check_root
    detect_os
    check_connectivity
    get_user_input
    
    create_structure
    install_dependencies
    install_docker
    generate_certificates
    install_binaries
    create_service_scripts
    create_web_interface
    create_configs
    
    echo ""
    print_color "✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!" $GREEN
    echo ""
    print_color "📊 ACESSO AO PAINEL:" $CYAN
    print_color "   http://$DOMAIN:8080" $CYAN
    echo ""
    print_color "⚙️  CONTROLE DE SERVIÇOS:" $YELLOW
    print_color "   Iniciar:   $SCRIPTS_DIR/panel-control.sh start" $YELLOW
    print_color "   Parar:     $SCRIPTS_DIR/panel-control.sh stop" $YELLOW
    print_color "   Reiniciar: $SCRIPTS_DIR/panel-control.sh restart" $YELLOW
    print_color "   Status:    $SCRIPTS_DIR/panel-control.sh status" $YELLOW
    echo ""
    print_color "📁 DIRETÓRIOS:" $BLUE
    print_color "   Painel:  $PANEL_DIR" $BLUE
    print_color "   Config:  $CONFIG_DIR" $BLUE
    print_color "   Logs:    $LOG_DIR" $BLUE
    print_color "   Erros:   $ERROR_LOG" $BLUE
    echo ""
}

# Executar
main_install
