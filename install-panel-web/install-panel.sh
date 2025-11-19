#!/bin/bash

# Painel Completo - Todos os Protocolos
# Script de instalação automático

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para imprimir com cores
print_color() {
    echo -e "${2}${1}${NC}"
}

# Função para verificar se é root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_color "Este script deve ser executado como root!" $RED
        exit 1
    fi
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
    
    print_color "Sistema detectado: $OS $VER" $CYAN
}

# Função para instalar dependências
install_dependencies() {
    print_color "Instalando dependências..." $YELLOW
    
    if command -v apt &> /dev/null; then
        apt update
        apt install -y curl wget git python3 python3-pip nodejs npm build-essential \
            libssl-dev zlib1g-dev libpcre3-dev libev-dev cmake golang-go \
            qrencode jq net-tools
    elif command -v yum &> /dev/null; then
        yum install -y curl wget git python3 python3-pip nodejs npm gcc-c++ \
            openssl-devel pcre-devel libev-devel cmake golang \
            qrencode jq net-tools
    elif command -v dnf &> /dev/null; then
        dnf install -y curl wget git python3 python3-pip nodejs npm gcc-c++ \
            openssl-devel pcre-devel libev-devel cmake golang \
            qrencode jq net-tools
    else
        print_color "Sistema não suportado automaticamente. Instale as dependências manualmente." $RED
        exit 1
    fi
}

# Função para instalar Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        print_color "Instalando Docker..." $YELLOW
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl start docker
        systemctl enable docker
        rm -f get-docker.sh
    else
        print_color "Docker já está instalado" $GREEN
    fi
}

# Função para criar estrutura de diretórios
create_structure() {
    print_color "Criando estrutura de diretórios..." $BLUE
    
    mkdir -p /opt/panel-completo/{config,scripts,web,logs,clients}
    mkdir -p /opt/panel-completo/config/{hysteria2,tuic,xray,trojan,shadowtls,shadowsocks,gost,wireguard,openvpn}
    mkdir -p /opt/panel-completo/clients/{configs,qrcodes,links}
    
    cd /opt/panel-completo
}

# Função para baixar e compilar binários
install_binaries() {
    print_color "Instalando/Compilando binários dos protocolos..." $PURPLE
    
    # Hysteria2
    if [ ! -f scripts/hysteria ]; then
        print_color "Instalando Hysteria2..." $CYAN
        wget -O scripts/hysteria https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64
        chmod +x scripts/hysteria
    fi
    
    # TUIC
    if [ ! -f scripts/tuic-server ]; then
        print_color "Instalando TUIC..." $CYAN
        wget -O scripts/tuic-server https://github.com/apernet/tuic/releases/latest/download/tuic-server-linux-amd64
        chmod +x scripts/tuic-server
    fi
    
    # Xray-core
    if [ ! -f scripts/xray ]; then
        print_color "Instalando Xray..." $CYAN
        wget -O scripts/xray https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
        unzip -o scripts/xray -d scripts/
        mv scripts/xray scripts/xray-bin
        chmod +x scripts/xray-bin
    fi
    
    # Trojan-Go
    if [ ! -f scripts/trojan-go ]; then
        print_color "Instalando Trojan-Go..." $CYAN
        wget -O scripts/trojan-go https://github.com/p4gefau1t/trojan-go/releases/latest/download/trojan-go-linux-amd64.zip
        unzip -o scripts/trojan-go -d scripts/
        chmod +x scripts/trojan-go
    fi
}

# Função para criar scripts de serviço
create_service_scripts() {
    print_color "Criando scripts de serviço..." $BLUE
    
    # Script principal de controle
    cat > scripts/panel-control.sh << 'EOF'
#!/bin/bash

PANEL_DIR="/opt/panel-completo"
CONFIG_DIR="$PANEL_DIR/config"
SCRIPTS_DIR="$PANEL_DIR/scripts"
LOG_DIR="$PANEL_DIR/logs"

start_services() {
    echo "Iniciando todos os serviços..."
    
    # Hysteria2
    if [ -f $CONFIG_DIR/hysteria/config.json ]; then
        $SCRIPTS_DIR/hysteria server --config $CONFIG_DIR/hysteria/config.json > $LOG_DIR/hysteria.log 2>&1 &
        echo $! > $SCRIPTS_DIR/hysteria.pid
    fi
    
    # TUIC
    if [ -f $CONFIG_DIR/tuic/config.toml ]; then
        $SCRIPTS_DIR/tuic-server --config $CONFIG_DIR/tuic/config.toml > $LOG_DIR/tuic.log 2>&1 &
        echo $! > $SCRIPTS_DIR/tuic.pid
    fi
    
    echo "Serviços iniciados!"
}

stop_services() {
    echo "Parando todos os serviços..."
    
    for pid_file in $SCRIPTS_DIR/*.pid; do
        if [ -f "$pid_file" ]; then
            kill $(cat $pid_file) 2>/dev/null
            rm -f $pid_file
        fi
    done
    
    echo "Serviços parados!"
}

restart_services() {
    stop_services
    sleep 2
    start_services
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
        # Verificar processos em execução
        for service in hysteria tuic xray trojan shadowtls; do
            if [ -f "$SCRIPTS_DIR/${service}.pid" ] && kill -0 $(cat "$SCRIPTS_DIR/${service}.pid") 2>/dev/null; then
                echo "$service: 🟢 RUNNING"
            else
                echo "$service: 🔴 STOPPED"
            fi
        done
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF

    chmod +x scripts/panel-control.sh
}

# Função para criar interface web
create_web_interface() {
    print_color "Criando interface web do painel..." $PURPLE
    
    # HTML principal
    cat > web/index.html << 'EOF'
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
        
        .header p {
            font-size: 1.2rem;
            opacity: 0.9;
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
            border: 1px solid #e5e7eb;
        }
        
        .protocol-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 35px rgba(0,0,0,0.3);
        }
        
        .protocol-header {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
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
        
        .protocol-description {
            color: #6b7280;
            margin-bottom: 20px;
            line-height: 1.5;
        }
        
        .btn-group {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        
        .btn {
            padding: 12px 20px;
            border: none;
            border-radius: 8px;
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-align: center;
            text-decoration: none;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        
        .btn-primary {
            background: var(--primary);
            color: white;
        }
        
        .btn-primary:hover {
            background: #1d4ed8;
            transform: scale(1.05);
        }
        
        .btn-success {
            background: var(--success);
            color: white;
        }
        
        .btn-success:hover {
            background: #047857;
            transform: scale(1.05);
        }
        
        .btn-warning {
            background: var(--warning);
            color: white;
        }
        
        .btn-warning:hover {
            background: #b45309;
            transform: scale(1.05);
        }
        
        .btn-danger {
            background: var(--danger);
            color: white;
        }
        
        .btn-danger:hover {
            background: #b91c1c;
            transform: scale(1.05);
        }
        
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
            max-height: 80vh;
            overflow-y: auto;
        }
        
        .modal-header {
            display: flex;
            justify-content: between;
            align-items: center;
            margin-bottom: 20px;
        }
        
        .close-modal {
            background: none;
            border: none;
            font-size: 1.5rem;
            cursor: pointer;
            color: var(--danger);
        }
        
        .qrcode-container {
            text-align: center;
            margin: 20px 0;
        }
        
        .config-content {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
            font-family: monospace;
            white-space: pre-wrap;
            word-break: break-all;
            max-height: 200px;
            overflow-y: auto;
        }
        
        .status-badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: bold;
            margin-left: auto;
        }
        
        .status-running {
            background: #dcfce7;
            color: #166534;
        }
        
        .status-stopped {
            background: #fee2e2;
            color: #991b1b;
        }
        
        @media (max-width: 768px) {
            .protocols-grid {
                grid-template-columns: 1fr;
            }
            
            .header h1 {
                font-size: 2rem;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔥 PAINEL COMPLETO</h1>
            <p>Todos os protocolos no mesmo lugar</p>
        </div>
        
        <div class="protocols-grid" id="protocolsGrid">
            <!-- Protocolos serão inseridos via JavaScript -->
        </div>
    </div>

    <!-- Modal para exibir QR Code e configurações -->
    <div class="modal" id="configModal">
        <div class="modal-content">
            <div class="modal-header">
                <h3 id="modalTitle">Configuração</h3>
                <button class="close-modal" onclick="closeModal()">×</button>
            </div>
            <div id="modalContent">
                <!-- Conteúdo dinâmico -->
            </div>
        </div>
    </div>

    <script>
        // Dados dos protocolos
        const protocols = [
            {
                id: 'hysteria2',
                name: 'Hysteria2',
                icon: '⚡',
                description: 'Protocolo UDP moderno com anti-censura e aceleração',
                status: 'stopped'
            },
            {
                id: 'tuic',
                name: 'TUIC 5',
                icon: '🚀',
                description: 'Protocolo de alto desempenho baseado em QUIC',
                status: 'stopped'
            },
            {
                id: 'xray',
                name: 'Xray REALITY',
                icon: '🛡️',
                description: 'VMess/VLESS com REALITY - Sem TLS fingerprint',
                status: 'stopped'
            },
            {
                id: 'trojan',
                name: 'Trojan-Go',
                icon: '🎭',
                description: 'Tráfego disfarçado de HTTPS, difícil de detectar',
                status: 'stopped'
            },
            {
                id: 'shadowtls',
                name: 'ShadowTLS v3',
                icon: '👻',
                description: 'Tunelamento TLS com sombra, evita detecção',
                status: 'stopped'
            },
            {
                id: 'shadowsocks',
                name: 'Shadowsocks + Cloak',
                icon: '🔒',
                description: 'Clássico com Cloak para camuflagem adicional',
                status: 'stopped'
            },
            {
                id: 'gost',
                name: 'gOST',
                icon: '🔄',
                description: 'FakeTLS + WSS + QUIC + HTTP2 - Tudo em um',
                status: 'stopped'
            },
            {
                id: 'wireguard',
                name: 'WireGuard',
                icon: '🔄',
                description: 'VPN moderna e rápida - Configuração normal',
                status: 'stopped'
            },
            {
                id: 'wireguard-faketcp',
                name: 'WireGuard + FakeTCP',
                icon: '🎯',
                description: 'WG com emulação TCP para evitar bloqueios',
                status: 'stopped'
            },
            {
                id: 'wireguard-udp2raw',
                name: 'WireGuard + UDP2Raw',
                icon: '🔧',
                description: 'WG com encapsulamento raw para bypass avançado',
                status: 'stopped'
            },
            {
                id: 'openvpn',
                name: 'OpenVPN + Obfs4',
                icon: '🔰',
                description: 'Clássico com obfuscação - Compatibilidade máxima',
                status: 'stopped'
            }
        ];

        // Gerar cards dos protocolos
        function generateProtocolCards() {
            const grid = document.getElementById('protocolsGrid');
            
            protocols.forEach(protocol => {
                const card = document.createElement('div');
                card.className = 'protocol-card';
                card.innerHTML = `
                    <div class="protocol-header">
                        <div class="protocol-icon">${protocol.icon}</div>
                        <div class="protocol-title">${protocol.name}</div>
                        <div class="status-badge status-${protocol.status}">
                            ${protocol.status === 'running' ? 'ONLINE' : 'OFFLINE'}
                        </div>
                    </div>
                    <div class="protocol-description">${protocol.description}</div>
                    <div class="btn-group">
                        <button class="btn btn-primary" onclick="generateConfig('${protocol.id}')">
                            📋 Gerar Configuração
                        </button>
                        <button class="btn btn-success" onclick="showQRCode('${protocol.id}')">
                            📱 QR Code
                        </button>
                        <button class="btn btn-warning" onclick="showConfig('${protocol.id}')">
                            ⚙️ Ver Config
                        </button>
                        <button class="btn btn-danger" onclick="copyConfig('${protocol.id}')">
                            📋 Copiar Link
                        </button>
                    </div>
                `;
                grid.appendChild(card);
            });
        }

        // Funções do modal
        function showModal() {
            document.getElementById('configModal').style.display = 'flex';
        }

        function closeModal() {
            document.getElementById('configModal').style.display = 'none';
        }

        // Funções dos botões (exemplos)
        function generateConfig(protocolId) {
            const modalTitle = document.getElementById('modalTitle');
            const modalContent = document.getElementById('modalContent');
            
            modalTitle.textContent = `Gerar ${getProtocolName(protocolId)}`;
            modalContent.innerHTML = `
                <div class="qrcode-container">
                    <p>Configuração gerada com sucesso!</p>
                    <div class="config-content">
                        ${generateSampleConfig(protocolId)}
                    </div>
                    <button class="btn btn-success" onclick="downloadConfig('${protocolId}')">
                        💾 Download Config
                    </button>
                </div>
            `;
            showModal();
        }

        function showQRCode(protocolId) {
            const modalTitle = document.getElementById('modalTitle');
            const modalContent = document.getElementById('modalContent');
            
            modalTitle.textContent = `QR Code - ${getProtocolName(protocolId)}`;
            modalContent.innerHTML = `
                <div class="qrcode-container">
                    <p>Escaneie este QR Code com seu cliente:</p>
                    <div style="background: #f0f0f0; padding: 20px; display: inline-block; margin: 15px 0;">
                        [QR CODE - ${protocolId.toUpperCase()}]
                    </div>
                    <p>Configuração: ${protocolId}</p>
                </div>
            `;
            showModal();
        }

        function showConfig(protocolId) {
            const modalTitle = document.getElementById('modalTitle');
            const modalContent = document.getElementById('modalContent');
            
            modalTitle.textContent = `Configuração - ${getProtocolName(protocolId)}`;
            modalContent.innerHTML = `
                <div class="config-content">
                    ${generateSampleConfig(protocolId)}
                </div>
                <button class="btn btn-primary" onclick="copyConfig('${protocolId}')" style="margin-top: 15px;">
                    📋 Copiar Configuração
                </button>
            `;
            showModal();
        }

        function copyConfig(protocolId) {
            const config = generateSampleConfig(protocolId);
            navigator.clipboard.writeText(config).then(() => {
                alert('Configuração copiada para a área de transferência!');
            });
        }

        function downloadConfig(protocolId) {
            const config = generateSampleConfig(protocolId);
            const blob = new Blob([config], { type: 'text/plain' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `${protocolId}-config.json`;
            a.click();
            URL.revokeObjectURL(url);
        }

        // Funções auxiliares
        function getProtocolName(protocolId) {
            const protocol = protocols.find(p => p.id === protocolId);
            return protocol ? protocol.name : 'Protocolo';
        }

        function generateSampleConfig(protocolId) {
            const configs = {
                hysteria2: `{
    "server": "your-server.com:443",
    "auth": "your-password",
    "transport": {
        "type": "udp",
        "path": "/hy2"
    }
}`,
                tuic: `{
    "relay": {
        "server": "your-server.com:443",
        "uuid": "your-uuid",
        "password": "your-password"
    }
}`,
                xray: `{
    "outbounds": [{
        "protocol": "vless",
        "settings": {
            "vnext": [{
                "address": "your-server.com",
                "port": 443,
                "users": [{"id": "your-uuid"}]
            }]
        },
        "streamSettings": {
            "network": "tcp",
            "security": "reality"
        }
    }]
}`,
                // ... outros protocolos
            };
            
            return configs[protocolId] || `Configuração para ${protocolId}\n\nPreencha com seus dados específicos.`;
        }

        // Inicializar
        document.addEventListener('DOMContentLoaded', generateProtocolCards);

        // Fechar modal clicando fora
        document.getElementById('configModal').addEventListener('click', function(e) {
            if (e.target === this) closeModal();
        });
    </script>
</body>
</html>
EOF

    # Servidor web simples em Python
    cat > web/server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import json
import subprocess

PORT = 8080
WEB_DIR = "/opt/panel-completo/web"

class PanelHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)
    
    def do_GET(self):
        if self.path == '/status':
            self.send_status()
        else:
            super().do_GET()
    
    def do_POST(self):
        if self.path == '/generate-config':
            self.generate_config()
        else:
            self.send_error(404)
    
    def send_status(self):
        status = {}
        try:
            # Verificar status dos serviços (exemplo)
            result = subprocess.run(['/opt/panel-completo/scripts/panel-control.sh', 'status'], 
                                  capture_output=True, text=True)
            status['output'] = result.stdout
        except Exception as e:
            status['error'] = str(e)
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(status).encode())
    
    def generate_config(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = json.loads(post_data)
        
        # Aqui você implementaria a geração real da configuração
        response = {
            'success': True,
            'message': f'Configuração {data.get("protocol")} gerada com sucesso',
            'config': 'configuração-exemplo'
        }
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())

def main():
    os.chdir(WEB_DIR)
    with socketserver.TCPServer(("", PORT), PanelHandler) as httpd:
        print(f"Servidor web rodando na porta {PORT}")
        print(f"Acesse: http://localhost:{PORT}")
        httpd.serve_forever()

if __name__ == "__main__":
    main()
EOF

    chmod +x web/server.py
}

# Função para criar script de inicialização
create_startup_script() {
    print_color "Criando script de inicialização..." $BLUE
    
    cat > /etc/systemd/system/panel-completo.service << EOF
[Unit]
Description=Painel Completo - Todos os Protocolos
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/panel-completo
ExecStart=/usr/bin/python3 /opt/panel-completo/web/server.py
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
}

# Função principal de instalação
main_install() {
    print_color "🚀 INICIANDO INSTALAÇÃO DO PAINEL COMPLETO" $GREEN
    print_color "===========================================" $GREEN
    
    check_root
    detect_os
    install_dependencies
    install_docker
    create_structure
    install_binaries
    create_service_scripts
    create_web_interface
    create_startup_script
    
    print_color "✅ Instalação concluída com sucesso!" $GREEN
    print_color "" $NC
    print_color "📊 PAINEL PRINCIPAL:" $CYAN
    print_color "   Acesse: http://$(curl -s ifconfig.me):8080" $CYAN
    print_color "" $NC
    print_color "⚙️ COMANDOS DE CONTROLE:" $YELLOW
    print_color "   Iniciar serviços: /opt/panel-completo/scripts/panel-control.sh start" $YELLOW
    print_color "   Parar serviços: /opt/panel-completo/scripts/panel-control.sh stop" $YELLOW
    print_color "   Reiniciar: /opt/panel-completo/scripts/panel-control.sh restart" $YELLOW
    print_color "   Status: /opt/panel-completo/scripts/panel-control.sh status" $YELLOW
    print_color "" $NC
    print_color "🌐 SERVIÇO WEB:" $PURPLE
    print_color "   systemctl start panel-completo" $PURPLE
    print_color "   systemctl enable panel-completo" $PURPLE
    print_color "" $NC
    print_color "📁 DIRETÓRIOS:" $BLUE
    print_color "   Configurações: /opt/panel-completo/config/" $BLUE
    print_color "   Scripts: /opt/panel-completo/scripts/" $BLUE
    print_color "   Web: /opt/panel-completo/web/" $BLUE
    print_color "   Logs: /opt/panel-completo/logs/" $BLUE
}

# Executar instalação
main_install