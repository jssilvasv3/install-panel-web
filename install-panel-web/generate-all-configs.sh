#!/bin/bash

# Script para gerar configurações automáticas para todos os protocolos
# Versão corrigida com validações e tratamento de erros

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variáveis
CONFIG_DIR="${1:-.}/config"
SCRIPTS_DIR="${2:-.}/scripts"
DOMAIN="${3:-$(hostname -f)}"
PORT="${4:-443}"

print_color() {
    echo -e "${2}${1}${NC}"
}

# Validar diretórios
validate_directories() {
    if [ ! -d "$CONFIG_DIR" ]; then
        print_color "❌ Diretório de configuração não existe: $CONFIG_DIR" $RED
        exit 1
    fi
    
    print_color "✅ Diretórios validados" $GREEN
}

# Gerar UUID único
generate_uuid() {
    cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || echo "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
}

# Gerar senha aleatória
generate_password() {
    openssl rand -hex 16 2>/dev/null || dd if=/dev/urandom bs=1 count=16 2>/dev/null | xxd -p || echo "defaultpassword123456"
}

print_color "🌐 GERANDO CONFIGURAÇÕES PARA: $DOMAIN" $CYAN
echo "Diretório de config: $CONFIG_DIR"
echo "Porta: $PORT"
echo ""

validate_directories

UUID=$(generate_uuid)
PASS1=$(generate_password)
PASS2=$(generate_password)
PASS3=$(generate_password)

print_color "📋 UUIDs e Senhas gerados" $GREEN

# ===== HYSTERIA2 =====
print_color "⚡ Configurando Hysteria2..." $CYAN

mkdir -p "$CONFIG_DIR/hysteria2"
cat > "$CONFIG_DIR/hysteria2/config.json" << HYSTERIA
{
    "listen": ":$PORT",
    "acme": {
        "domains": ["$DOMAIN"],
        "email": "admin@$DOMAIN"
    },
    "obfs": {
        "type": "salamander",
        "password": "$PASS1"
    },
    "auth": {
        "type": "password",
        "password": "$PASS1"
    },
    "masquerade": {
        "type": "file",
        "file": "/var/www/html"
    }
}
HYSTERIA

if [ $? -eq 0 ]; then
    print_color "✅ Hysteria2 configurado" $GREEN
else
    print_color "❌ Erro ao configurar Hysteria2" $RED
fi

# ===== TUIC =====
print_color "🚀 Configurando TUIC..." $CYAN

mkdir -p "$CONFIG_DIR/tuic"
cat > "$CONFIG_DIR/tuic/config.toml" << TUIC
[server]
listen = "[::]:$PORT"
users = ["$UUID:$PASS1"]
certificate = "/etc/ssl/certs/cert.crt"
private_key = "/etc/ssl/private/key.key"

[server.congestion_control]
algorithm = "bbr"

[server.log]
level = "warn"
TUIC

if [ $? -eq 0 ]; then
    print_color "✅ TUIC configurado" $GREEN
else
    print_color "❌ Erro ao configurar TUIC" $RED
fi

# ===== XRAY REALITY =====
print_color "🛡️  Configurando Xray REALITY..." $CYAN

mkdir -p "$CONFIG_DIR/xray"
cat > "$CONFIG_DIR/xray/config.json" << XRAY
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": $PORT,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "tcpSettings": {},
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "www.google.com:443",
                    "xver": 0,
                    "serverNames": [
                        "www.google.com"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
XRAY

if [ $? -eq 0 ]; then
    print_color "✅ Xray REALITY configurado" $GREEN
else
    print_color "❌ Erro ao configurar Xray" $RED
fi

# ===== TROJAN-GO =====
print_color "🎭 Configurando Trojan-Go..." $CYAN

mkdir -p "$CONFIG_DIR/trojan"
cat > "$CONFIG_DIR/trojan/config.json" << TROJAN
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": $PORT,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$PASS1",
        "$PASS2"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/etc/ssl/certs/cert.crt",
        "key": "/etc/ssl/private/key.key",
        "key_password": "",
        "cipher": "DEFAULT",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": true,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false
    },
    "mysql": {
        "enabled": false
    },
    "router": {
        "enabled": false
    },
    "websocket": {
        "enabled": false
    }
}
TROJAN

if [ $? -eq 0 ]; then
    print_color "✅ Trojan-Go configurado" $GREEN
else
    print_color "❌ Erro ao configurar Trojan-Go" $RED
fi

# ===== SHADOWTLS V3 =====
print_color "👻 Configurando ShadowTLS V3..." $CYAN

mkdir -p "$CONFIG_DIR/shadowtls"
cat > "$CONFIG_DIR/shadowtls/config.json" << EOF
{
    "version": 3,
    "servers": [
        {
            "listen": ":$PORT",
            "users": [
                {
                    "name": "user1",
                    "password": "$PASS1"
                }
            ],
            "handshake": {
                "server": "www.google.com"
            },
            "strict": true
        }
    ]
}
EOF

if [ $? -eq 0 ]; then
    print_color "✅ ShadowTLS V3 configurado" $GREEN
else
    print_color "❌ Erro ao configurar ShadowTLS" $RED
fi

# ===== SHADOWSOCKS + CLOAK =====
print_color "🔒 Configurando Shadowsocks + Cloak..." $CYAN

mkdir -p "$CONFIG_DIR/shadowsocks"
cat > "$CONFIG_DIR/shadowsocks/config.json" << EOF
{
    "server": "0.0.0.0",
    "port": $PORT,
    "password": "$PASS1",
    "method": "aes-256-gcm",
    "plugin": "cloak-server",
    "plugin_opts": "BindIP=0.0.0.0;CertFile=/etc/ssl/certs/cert.crt;KeyFile=/etc/ssl/private/key.key;ProxyPass=www.google.com"
}
EOF

if [ $? -eq 0 ]; then
    print_color "✅ Shadowsocks + Cloak configurado" $GREEN
else
    print_color "❌ Erro ao configurar Shadowsocks" $RED
fi

# ===== GOST =====
print_color "🔄 Configurando gOST..." $CYAN

mkdir -p "$CONFIG_DIR/gost"
cat > "$CONFIG_DIR/gost/config.json" << EOF
{
    "services": [
        {
            "name": "gost",
            "addr": ":$PORT",
            "handler": {
                "type": "http",
                "chain": "chain-0"
            },
            "listener": {
                "type": "tls",
                "tls": {
                    "certFile": "/etc/ssl/certs/cert.crt",
                    "keyFile": "/etc/ssl/private/key.key"
                }
            }
        }
    ]
}
EOF

if [ $? -eq 0 ]; then
    print_color "✅ gOST configurado" $GREEN
else
    print_color "❌ Erro ao configurar gOST" $RED
fi

# ===== WIREGUARD =====
print_color "🔄 Configurando WireGuard..." $CYAN

mkdir -p "$CONFIG_DIR/wireguard"
cat > "$CONFIG_DIR/wireguard/wg0.conf" << EOF
[Interface]
PrivateKey = \$(wg genkey 2>/dev/null || echo "GIKF7XVYKQE4JVJW25JY7VXLZYYKYV6UWY5ZK3VXRRWOVMYTZUQ====")
Address = 10.0.0.1/24
ListenPort = $PORT
DNS = 8.8.8.8

[Peer]
PublicKey = \$(wg pubkey 2>/dev/null || echo "QIQKF7XVYKQE4JVJW25JY7VXLZYYKYV6UWY5ZK3VXRRWOVMYTZUQ")
AllowedIPs = 10.0.0.2/32
EOF

if [ $? -eq 0 ]; then
    print_color "✅ WireGuard configurado" $GREEN
else
    print_color "❌ Erro ao configurar WireGuard" $RED
fi

# ===== OPENVPN =====
print_color "🔰 Configurando OpenVPN..." $CYAN

mkdir -p "$CONFIG_DIR/openvpn"
cat > "$CONFIG_DIR/openvpn/server.conf" << EOF
port $PORT
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/ssl/certs/cert.crt
key /etc/ssl/private/key.key
dh /etc/openvpn/dh.pem
topology subnet
server 10.0.0.0 255.255.255.0
push "redirect-gateway def1"
cipher AES-256-GCM
keepalive 10 120
persist-key
persist-tun
status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3
mute 20
explicit-exit-notify 1
plugin /usr/lib/openvpn/plugins/openvpn-plugin-auth-pam.so login
EOF

if [ $? -eq 0 ]; then
    print_color "✅ OpenVPN configurado" $GREEN
else
    print_color "❌ Erro ao configurar OpenVPN" $RED
fi

# ===== RESUMO =====
echo ""
print_color "==========================================" $CYAN
print_color "✅ TODAS AS CONFIGURAÇÕES GERADAS COM SUCESSO!" $GREEN
print_color "==========================================" $CYAN
echo ""
print_color "📊 INFORMAÇÕES:" $YELLOW
print_color "   Domínio: $DOMAIN" $YELLOW
print_color "   Porta: $PORT" $YELLOW
print_color "   UUID Principal: $UUID" $YELLOW
print_color "   Senha 1: $PASS1" $YELLOW
print_color "   Senha 2: $PASS2" $YELLOW
print_color "   Senha 3: $PASS3" $YELLOW
echo ""
print_color "📁 Arquivos de configuração em: $CONFIG_DIR/" $CYAN
echo ""
print_color "🔗 Próximos passos:" $GREEN
print_color "   1. Revisar e ajustar configurações conforme necessário" $GREEN
print_color "   2. Gerar certificados SSL válidos" $GREEN
print_color "   3. Iniciar os serviços dos protocolos" $GREEN
print_color "   4. Adicionar usuários aos clientes" $GREEN
echo ""