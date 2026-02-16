#!/bin/bash
# ================================================
# BOT WHATSAPP - WPPCONNECT + IA MEJORADA (SIN ESTADOS)
# ================================================
# CARACTERÍSTICAS:
# ✅ WPPCONNECT
# ✅ IA MEJORADA (SSH BOT PRO v8.7)
# ✅ PANEL VPS COMPLETO
# ✅ SIN CREACIÓN DE ESTADOS EN WHATSAPP
# ✅ SIN CREACIÓN AUTOMÁTICA DE USUARIOS SSH
# ✅ SIN PAGOS AUTOMÁTICOS
# ================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Banner
clear
echo -e "${CYAN}${BOLD}"
cat << "BANNER"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ████████╗██╗███████╗███╗   ██╗██████╗  █████╗          ║
║     ╚══██╔══╝██║██╔════╝████╗  ██║██╔══██╗██╔══██╗         ║
║        ██║   ██║█████╗  ██╔██╗ ██║██║  ██║███████║         ║
║        ██║   ██║██╔══╝  ██║╚██╗██║██║  ██║██╔══██║         ║
║        ██║   ██║███████╗██║ ╚████║██████╔╝██║  ██║         ║
║        ╚═╝   ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝         ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║       🤖 BOT WPPCONNECT + IA MEJORADA (SIN ESTADOS)         ║
║     ✅ WPPCONNECT · ✅ IA OMNIPRESENTE · ✅ SIN ESTADOS     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS:${NC}"
echo -e "  🤖 ${CYAN}IA MEJORADA${NC} - Asistencia técnica detallada"
echo -e "  📱 ${PURPLE}WPPConnect${NC} - Conexión WhatsApp estable"
echo -e "  📊 ${BLUE}Panel VPS${NC} - Estadísticas y control total"
echo -e "  🔕 ${RED}Sin Estados${NC} - NO crea estados en WhatsApp"
echo -e "  🚫 ${RED}Sin SSH${NC} - Sin creación automática de usuarios"
echo -e "  🚫 ${RED}Sin MercadoPago${NC} - Sin pagos automáticos"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    exit 1
fi

# ================================================
# INSTALAR SQLITE3
# ================================================
echo -e "\n${CYAN}${BOLD}📦 INSTALANDO SQLITE3...${NC}"
apt-get update -y
apt-get install -y sqlite3

if command -v sqlite3 &> /dev/null; then
    echo -e "${GREEN}✅ SQLite3 instalado: $(sqlite3 --version)${NC}"
else
    echo -e "${RED}❌ Error instalando SQLite3${NC}"
    exit 1
fi

# ================================================
# CONFIGURACIÓN DEL NOMBRE
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT${NC}"
read -p "📝 NOMBRE PARA TU BOT (ej: LIBRE|AR): " BOT_NAME
BOT_NAME=${BOT_NAME:-"LIBRE|AR"}
echo -e "${GREEN}✅ Nombre: ${CYAN}$BOT_NAME${NC}"

# ================================================
# RUTAS FIJAS
# ================================================
INSTALL_DIR="/sshbot"
PROCESS_NAME="wppconnect-bot"
SESSION_DIR="/root/.wppconnect/session"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
INFO_FILE="$INSTALL_DIR/config/info.txt"
PROMPT_FILE="$INSTALL_DIR/config/gemini_prompt.txt"

echo -e "\n${YELLOW}📁 RUTAS:${NC}"
echo -e "   • Instalación: ${CYAN}$INSTALL_DIR${NC}"
echo -e "   • Proceso PM2: ${CYAN}$PROCESS_NAME${NC}"
echo -e "   • Base de datos: ${CYAN}$DB_FILE${NC}"

read -p "$(echo -e "${YELLOW}¿Continuar? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 0
fi

# ================================================
# LIMPIEZA
# ================================================
echo -e "\n${CYAN}${BOLD}🧹 LIMPIEZA...${NC}"
if command -v pm2 &> /dev/null; then
    pm2 list | grep -E "(wppconnect-bot|bot)" | awk '{print $2}' | xargs -r pm2 delete 2>/dev/null || true
    pm2 kill 2>/dev/null || true
fi
pkill -f chrome 2>/dev/null || true
pkill -f node 2>/dev/null || true
rm -rf /sshbot 2>/dev/null
rm -rf /root/.wppconnect 2>/dev/null
echo -e "${GREEN}✅ Limpieza completada${NC}"

# ================================================
# CREAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes,panel/static,views}
mkdir -p "$SESSION_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 "$SESSION_DIR"
echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# CONFIGURACIÓN DE GEMINI AI
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CONFIGURACIÓN DE IA${NC}"
read -p "🔑 Ingresa tu API Key de Google Gemini: " GEMINI_API_KEY
GEMINI_API_KEY=${GEMINI_API_KEY:-""}

if [ -n "$GEMINI_API_KEY" ]; then
    echo -e "${GREEN}✅ API Key configurada${NC}"
else
    echo -e "${RED}❌ API Key necesaria${NC}"
    exit 1
fi

# ================================================
# GUARDAR PROMPT (SIN GENERACIÓN DE ESTADOS)
# ================================================
echo -e "\n${CYAN}💬 Guardando prompt (sin estados)...${NC}"
cat > "$PROMPT_FILE" << 'PROMPT_EOF'
Eres un asistente virtual de una empresa que vende servicio de internet ilimitado para celulares Android y iPhone llamada $BOT_NAME.

REGLAS IMPORTANTES:
- NO debes crear ni publicar ningún estado en WhatsApp
- NO debes cambiar tu foto de perfil, nombre o información
- Solo debes responder mensajes directos de los clientes
- NO debes enviar mensajes automáticos a grupos o contactos

INFORMACIÓN DE LA EMPRESA:
- El servicio funciona SOLO para PERSONAL (abono y prepago)
- NO disponible para Movistar, Tuenti o Claro
- Se vende como archivos de configuración (servidores, servers, "llavecita")
- Pago por transferencia bancaria
- NO realices ventas ni pidas comprobantes
- Para contratar, ofrece transferir con representante
- Horario representantes: 10:30 a 22:30

GUÍA DE ASISTENCIA TÉCNICA:
🔧 SOLUCIÓN RÁPIDA:
1️⃣ Verifica usuario/contraseña (minúsculas, sin espacios)
2️⃣ Conéctate a 4G con buena señal (3+ barras)
3️⃣ Desactiva límite de datos y ahorro de batería
4️⃣ Reinicia la aplicación

⚙️ PASOS DETALLADOS:
● Verifica que tus datos estén bien escritos, todo minúscula y sin espacios.
● Borra y vuelve a escribir tu usuario y contraseña.
● Conectate a WiFi y prueba actualizar la app.
● Revisa los ajustes de batería desde la opción "Menú".
● Siempre conecta con el botón AUTO.

RESPUESTAS:
1. Si detectas un problema técnico, ofrece la guía de solución
2. Si no, muestra este menú:

*⚙️ $BOT_NAME ChatBot* 🧑‍💻
             ⸻↓⸻
> 🕋 BIENVENIDO A TIENDA $BOT_NAME

1 ⁃📢 INFORMACIÓN
2 ⁃🏷️ PRECIOS
3 ⁃🛍️ REVENDER SERVICIO
4 ⁃👥 HABLAR CON UN REPRESENTANTE

👉 Elige una opción (1-4):

⚠️ Horario representantes: 10:30 a 22:30hs.

RECUERDA: SOLO RESPONDES MENSAJES DIRECTOS, NUNCA CREES ESTADOS.
PROMPT_EOF

sed -i "s/\$BOT_NAME/$BOT_NAME/g" "$PROMPT_FILE"

# ================================================
# CONFIGURACIÓN DEL BOT
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURANDO OPCIONES...${NC}"

read -p "📲 Link de descarga para Android: " APP_LINK
APP_LINK=${APP_LINK:-"https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"}

read -p "🆘 Número de WhatsApp para representante (sin +): " SUPPORT_NUMBER
SUPPORT_NUMBER=${SUPPORT_NUMBER:-"543435071016"}

echo -e "\n${YELLOW}💰 PRECIOS:${NC}"
read -p "Precio 7 días (3000): " PRICE_7D
PRICE_7D=${PRICE_7D:-3000}
read -p "Precio 15 días (4000): " PRICE_15D
PRICE_15D=${PRICE_15D:-4000}
read -p "Precio 30 días (7000): " PRICE_30D
PRICE_30D=${PRICE_30D:-7000}
read -p "Precio 50 días (9700): " PRICE_50D
PRICE_50D=${PRICE_50D:-9700}

read -p "⏰ Horas de prueba gratis (2): " TEST_HOURS
TEST_HOURS=${TEST_HOURS:-2}
read -p "🌐 Puerto panel VPS (3000): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-3000}

SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
SERVER_IP=${SERVER_IP:-"127.0.0.1"}

# ================================================
# TEXTO DE INFORMACIÓN
# ================================================
cat > "$INFO_FILE" << EOF
🔥 INTERNET ILIMITADO $BOT_NAME ⚡📱

Es una aplicación que te permite conectar y navegar en internet de manera ilimitada/infinita. Sin necesidad de tener saldo/crédito o MG/GB.

📢 Te ofrecemos internet Ilimitado para la empresa PERSONAL, tanto ABONO como PREPAGO a través de nuestra aplicación!

✅ Disponible para ANDROID y IPHONE
❌ NO disponible para Movistar, Tuenti o Claro

❓ Cómo funciona? Instalamos y configuramos nuestra app para que tengas acceso al servicio, una vez instalada puedes usar todo el internet que quieras sin preocuparte por tus datos!

📲 Probamos que todo funcione correctamente para que recién puedas abonar vía transferencia!

⚙️ Tienes soporte técnico por los 30 días que contrates por cualquier inconveniente! 

⚠️ Nos hacemos cargo de cualquier problema!
EOF

# ================================================
# GUARDAR CONFIGURACIÓN
# ================================================
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "$BOT_NAME",
        "version": "3.0-WPPCONNECT-NO-STATUS",
        "server_ip": "$SERVER_IP",
        "test_hours": $TEST_HOURS,
        "info_file": "$INFO_FILE",
        "process_name": "$PROCESS_NAME",
        "panel_port": $PANEL_PORT,
        "disable_status": true
    },
    "gemini": {
        "api_key": "$GEMINI_API_KEY",
        "enabled": true,
        "model": "gemini-pro",
        "prompt_file": "$PROMPT_FILE"
    },
    "prices": {
        "price_7d": $PRICE_7D,
        "price_15d": $PRICE_15D,
        "price_30d": $PRICE_30D,
        "price_50d": $PRICE_50D,
        "currency": "ARS"
    },
    "links": {
        "app_android": "$APP_LINK",
        "support": "https://wa.me/$SUPPORT_NUMBER"
    },
    "ai_features": {
        "technical_support": true,
        "auto_detect_problems": true,
        "detailed_responses": true
    },
    "paths": {
        "database": "$DB_FILE",
        "sessions": "$SESSION_DIR",
        "qr_codes": "$INSTALL_DIR/qr_codes"
    }
}
EOF

# ================================================
# CREAR BASE DE DATOS
# ================================================
echo -e "\n${CYAN}🗄️ Creando base de datos...${NC}"

sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT UNIQUE,
    name TEXT,
    last_menu TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);
CREATE TABLE IF NOT EXISTS conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    message TEXT,
    response TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS technical_issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    issue_type TEXT,
    description TEXT,
    resolution TEXT,
    resolved BOOLEAN DEFAULT 0,
    confidence_score REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_conversations_phone ON conversations(phone);
SQL

echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# INSTALAR DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias del sistema...${NC}"
apt-get update -y
apt-get install -y curl wget git unzip nginx

# Node.js 18.x
echo -e "${YELLOW}📦 Instalando Node.js 18.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs gcc g++ make

# Chrome
echo -e "${YELLOW}🌐 Instalando Google Chrome...${NC}"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - 2>/dev/null || true
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# PM2
echo -e "${YELLOW}⚡ Instalando PM2...${NC}"
npm install -g pm2

# ================================================
# CREAR PACKAGE.JSON
# ================================================
echo -e "\n${CYAN}📦 Creando package.json...${NC}"

cat > "$INSTALL_DIR/package.json" << 'EOF'
{
    "name": "wppconnect-bot-no-status",
    "version": "3.0.0",
    "description": "Bot WhatsApp con WPPConnect e IA (sin estados)",
    "main": "bot.js",
    "scripts": {
        "start": "node bot.js",
        "pm2": "pm2 start bot.js --name wppconnect-bot",
        "pm2-logs": "pm2 logs wppconnect-bot"
    },
    "dependencies": {
        "@google/generative-ai": "^0.8.0",
        "@wppconnect-team/wppconnect": "^1.30.0",
        "qrcode-terminal": "^0.12.0",
        "express": "^4.18.2",
        "sqlite3": "^5.1.7",
        "cors": "^2.8.5",
        "moment": "^2.30.1",
        "axios": "^1.6.7"
    }
}
EOF

# ================================================
# CREAR ARCHIVO PRINCIPAL DEL BOT (SIN ESTADOS)
# ================================================
echo -e "\n${CYAN}📝 Creando archivo principal del bot (sin estados)...${NC}"

cat > "$INSTALL_DIR/bot.js" << 'EOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const { GoogleGenerativeAI } = require("@google/generative-ai");
const qrcode = require('qrcode-terminal');
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const moment = require('moment');

// Configuración
const config = JSON.parse(fs.readFileSync('/sshbot/config/config.json'));
const promptSistema = fs.readFileSync(config.gemini.prompt_file, 'utf8');

// Inicializar Gemini
const genAI = new GoogleGenerativeAI(config.gemini.api_key);
const model = genAI.getGenerativeModel({ model: "gemini-pro" });

// Base de datos
const db = new sqlite3.Database(config.paths.database);

// Express app
const app = express();
app.use(cors());
app.use(express.json());

// ================================================
// DETECCIÓN DE PROBLEMAS TÉCNICOS
// ================================================
function detectTechnicalProblem(message) {
    const text = message.toLowerCase();
    const keywords = [
        'no funciona', 'falla', 'error', 'problema', 'no anda',
        'no conecta', 'llave', 'servidor', 'aplicación', 'app',
        'técnico', 'ayuda', 'soporte', 'conexión', 'configurar'
    ];
    
    let score = 0;
    keywords.forEach(keyword => {
        if (text.includes(keyword)) score += 0.2;
    });
    
    return {
        detected: score >= 0.4,
        confidence: Math.min(score, 1.0)
    };
}

// ================================================
// FUNCIÓN DE IA (SIN GENERAR ESTADOS)
// ================================================
async function procesarConIA(mensaje, numero, nombreUsuario = 'Cliente') {
    try {
        const techDetection = detectTechnicalProblem(mensaje);
        
        const contexto = `
Usuario: ${nombreUsuario}
Número: ${numero}
Hora: ${moment().format('HH:mm')}
Fecha: ${moment().format('DD/MM/YYYY')}
Mensaje: "${mensaje}"
Problema técnico: ${techDetection.detected ? 'SÍ' : 'NO'}

INSTRUCCIÓN IMPORTANTE:
SOLO debes responder a este mensaje directo.
NO debes crear ni publicar ningún estado en WhatsApp.
NO debes cambiar la foto de perfil ni el nombre del bot.
`;

        const fullPrompt = `${promptSistema}\n\n${contexto}`;
        const result = await model.generateContent(fullPrompt);
        const response = await result.response;
        const text = response.text();
        
        db.run(
            'INSERT INTO conversations (phone, message, response) VALUES (?, ?, ?)',
            [numero, mensaje.substring(0, 500), text.substring(0, 500)]
        );
        
        if (techDetection.detected) {
            db.run(
                'INSERT INTO technical_issues (phone, issue_type, description, confidence_score) VALUES (?, ?, ?, ?)',
                [numero, 'auto_detected', mensaje.substring(0, 200), techDetection.confidence]
            );
        }
        
        return text;
    } catch (error) {
        console.error('Error en IA:', error);
        return `*⚙️ ${config.bot.name} ChatBot* 🧑‍💻
             ⸻↓⸻
> 🕋 BIENVENIDO A TIENDA ${config.bot.name}

1 ⁃📢 INFORMACIÓN
2 ⁃🏷️ PRECIOS
3 ⁃🛍️ REVENDER SERVICIO
4 ⁃👥 HABLAR CON UN REPRESENTANTE

👉 Elige una opción (1-4):

⚠️ Horario representantes: 10:30 a 22:30hs.`;
    }
}

// ================================================
// INICIALIZAR WPPCONNECT (SIN FUNCIONES DE ESTADO)
// ================================================
async function startBot() {
    try {
        const client = await wppconnect.create({
            session: 'ssh-bot-session',
            statusFind: (statusSession, session) => {
                // Solo loguear, no crear estados
                console.log('Status Session:', statusSession);
            },
            headless: true,
            devtools: false,
            useChrome: true,
            debug: false,
            logQR: true,
            disableWelcome: true, // Desactiva mensaje de bienvenida automático
            updatesLog: false,     // Desactiva logs de actualizaciones
            browserWS: '',
            browserArgs: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-accelerated-2d-canvas',
                '--no-first-run',
                '--no-zygote',
                '--disable-gpu'
            ],
            puppeteerOptions: {
                executablePath: '/usr/bin/google-chrome'
            },
            // Desactivar funciones de estado
            createOptions: {
                status: false,
                disableStatus: true
            }
        });

        console.log('✅ WPPConnect iniciado (MODO SIN ESTADOS)');

        // Sobrescribir funciones de estado para asegurar que no se usen
        client.setStatus = async () => {
            console.log('🚫 Intento de cambiar estado bloqueado');
            return;
        };

        client.setProfileStatus = async () => {
            console.log('🚫 Intento de cambiar perfil bloqueado');
            return;
        };

        // Solo escuchar mensajes directos
        client.onMessage(async (message) => {
            // Ignorar mensajes de grupos y estados
            if (message.isGroupMsg) return;
            if (message.from.includes('status')) return;
            if (message.from.includes('broadcast')) return;
            
            const numero = message.from;
            const texto = message.body;
            
            console.log(`📨 Mensaje de ${numero}: ${texto.substring(0, 50)}`);
            
            // Registrar usuario
            db.get('SELECT * FROM users WHERE phone = ?', [numero], async (err, user) => {
                if (!user) {
                    db.run('INSERT INTO users (phone, name) VALUES (?, ?)',
                        [numero, message.sender.pushname || 'Cliente']);
                }
                
                // Procesar con IA
                const respuesta = await procesarConIA(
                    texto,
                    numero,
                    message.sender.pushname || 'Cliente'
                );
                
                if (respuesta) {
                    await client.sendText(numero, respuesta);
                }
            });
        });

        return client;
    } catch (error) {
        console.error('Error iniciando WPPConnect:', error);
        throw error;
    }
}

// ================================================
// PANEL VPS - API ENDPOINTS
// ================================================
app.get('/api/stats', (req, res) => {
    db.get(`
        SELECT 
            (SELECT COUNT(*) FROM users) as total_users,
            (SELECT COUNT(*) FROM conversations WHERE date(created_at) = date('now')) as today_conversations,
            (SELECT COUNT(*) FROM technical_issues) as total_issues,
            (SELECT COUNT(*) FROM technical_issues WHERE resolved = 0) as pending_issues
    `, (err, row) => {
        if (err) res.status(500).json({ error: err.message });
        else res.json(row || { total_users: 0, today_conversations: 0, total_issues: 0, pending_issues: 0 });
    });
});

app.get('/api/conversations/recent', (req, res) => {
    db.all(`SELECT * FROM conversations ORDER BY created_at DESC LIMIT 20`, (err, rows) => {
        if (err) res.status(500).json({ error: err.message });
        else res.json(rows || []);
    });
});

app.get('/api/issues/recent', (req, res) => {
    db.all(`SELECT * FROM technical_issues ORDER BY created_at DESC LIMIT 20`, (err, rows) => {
        if (err) res.status(500).json({ error: err.message });
        else res.json(rows || []);
    });
});

app.get('/api/bot/info', (req, res) => {
    res.json({
        name: config.bot.name,
        version: config.bot.version,
        status: 'online',
        ai_model: 'gemini-pro',
        status_mode: 'DESACTIVADO' // Importante: indicar que los estados están desactivados
    });
});

// ================================================
// PANEL WEB
// ================================================
app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Panel VPS - ${config.bot.name} (SIN ESTADOS)</title>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    font-family: 'Segoe UI', sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    padding: 20px;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                }
                h1 {
                    color: white;
                    text-align: center;
                    margin-bottom: 30px;
                    text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
                }
                .status-badge {
                    background: #e74c3c;
                    color: white;
                    padding: 5px 10px;
                    border-radius: 5px;
                    display: inline-block;
                    margin-bottom: 20px;
                }
                .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                    gap: 20px;
                    margin-bottom: 30px;
                }
                .stat-card {
                    background: white;
                    padding: 20px;
                    border-radius: 10px;
                    text-align: center;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                }
                .stat-value {
                    font-size: 2.5em;
                    font-weight: bold;
                    color: #667eea;
                    margin: 10px 0;
                }
                .sections {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 20px;
                }
                .section {
                    background: white;
                    padding: 20px;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                }
                th, td {
                    padding: 10px;
                    text-align: left;
                    border-bottom: 1px solid #ddd;
                }
                .badge {
                    padding: 3px 8px;
                    border-radius: 3px;
                    font-size: 0.85em;
                }
                .badge-warning { background: #f39c12; color: white; }
                .refresh-btn {
                    display: block;
                    width: 200px;
                    margin: 20px auto;
                    padding: 10px;
                    background: #667eea;
                    color: white;
                    border: none;
                    border-radius: 5px;
                    cursor: pointer;
                }
                @media (max-width: 768px) {
                    .sections {
                        grid-template-columns: 1fr;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🤖 Panel VPS - ${config.bot.name}</h1>
                <div class="status-badge">🔕 MODO SIN ESTADOS ACTIVADO</div>
                
                <div class="stats-grid" id="stats">
                    <div class="stat-card">
                        <div>👥 Usuarios</div>
                        <div class="stat-value" id="totalUsers">0</div>
                    </div>
                    <div class="stat-card">
                        <div>💬 Conversaciones Hoy</div>
                        <div class="stat-value" id="todayChats">0</div>
                    </div>
                    <div class="stat-card">
                        <div>🔧 Problemas</div>
                        <div class="stat-value" id="totalIssues">0</div>
                    </div>
                    <div class="stat-card">
                        <div>⏳ Pendientes</div>
                        <div class="stat-value" id="pendingIssues">0</div>
                    </div>
                </div>

                <div class="sections">
                    <div class="section">
                        <h2>💬 Últimas Conversaciones</h2>
                        <table>
                            <thead>
                                <tr><th>Teléfono</th><th>Mensaje</th><th>Hora</th></tr>
                            </thead>
                            <tbody id="conversationsBody">
                                <tr><td colspan="3">Cargando...</td></tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="section">
                        <h2>🔧 Problemas Detectados</h2>
                        <table>
                            <thead>
                                <tr><th>Teléfono</th><th>Confianza</th><th>Estado</th></tr>
                            </thead>
                            <tbody id="issuesBody">
                                <tr><td colspan="3">Cargando...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <button class="refresh-btn" onclick="cargarDatos()">🔄 Actualizar</button>
            </div>
            <script>
                async function cargarDatos() {
                    try {
                        const stats = await fetch('/api/stats').then(r => r.json());
                        document.getElementById('totalUsers').textContent = stats.total_users || 0;
                        document.getElementById('todayChats').textContent = stats.today_conversations || 0;
                        document.getElementById('totalIssues').textContent = stats.total_issues || 0;
                        document.getElementById('pendingIssues').textContent = stats.pending_issues || 0;
                        
                        const conv = await fetch('/api/conversations/recent').then(r => r.json());
                        document.getElementById('conversationsBody').innerHTML = conv.length ?
                            conv.map(c => \`<tr><td>\${c.phone}</td><td>\${c.message.substring(0,30)}...</td><td>\${new Date(c.created_at).toLocaleTimeString()}</td></tr>\`).join('') :
                            '<tr><td colspan="3">Sin conversaciones</td></tr>';
                        
                        const issues = await fetch('/api/issues/recent').then(r => r.json());
                        document.getElementById('issuesBody').innerHTML = issues.length ?
                            issues.map(i => \`<tr><td>\${i.phone}</td><td>\${Math.round(i.confidence_score*100)}%</td><td><span class="badge badge-warning">\${i.resolved ? 'Resuelto' : 'Pendiente'}</span></td></tr>\`).join('') :
                            '<tr><td colspan="3">Sin problemas</td></tr>';
                    } catch (e) { console.error(e); }
                }
                cargarDatos();
                setInterval(cargarDatos, 30000);
            </script>
        </body>
        </html>
    `);
});

// ================================================
// INICIAR TODO
// ================================================
app.listen(config.bot.panel_port, '0.0.0.0', () => {
    console.log(`
╔══════════════════════════════════════════════════════════╗
║  📊 PANEL VPS: http://${config.bot.server_ip}:${config.bot.panel_port}
║  🤖 Bot: ${config.bot.name}
║  🔕 ESTADOS: COMPLETAMENTE DESACTIVADOS
║  🔧 IA Mejorada: ACTIVADA
╚══════════════════════════════════════════════════════════╝
    `);
});

startBot().catch(console.error);

process.on('uncaughtException', (error) => {
    console.error('Error:', error);
    db.run('INSERT INTO logs (type, message) VALUES (?, ?)',
        ['error', error.message]);
});
EOF

# ================================================
# INSTALAR DEPENDENCIAS NODE
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias Node.js...${NC}"
cd "$INSTALL_DIR"
npm install

# ================================================
# CONFIGURAR NGINX
# ================================================
echo -e "\n${CYAN}🌐 Configurando Nginx...${NC}"
cat > /etc/nginx/sites-available/wppconnect-panel << EOF
server {
    listen 80;
    server_name $SERVER_IP;
    location / {
        proxy_pass http://localhost:$PANEL_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/wppconnect-panel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx || echo -e "${YELLOW}⚠️ Nginx no configurado${NC}"

# ================================================
# INICIAR BOT CON PM2
# ================================================
echo -e "\n${CYAN}🚀 Iniciando bot con PM2 (SIN ESTADOS)...${NC}"
cd "$INSTALL_DIR"
pm2 start bot.js --name wppconnect-bot
pm2 save
pm2 startup

# ================================================
# CONFIGURAR CRON
# ================================================
echo -e "\n${CYAN}📝 Configurando limpieza...${NC}"
cat > /etc/cron.d/wppconnect-clean << EOF
0 0 * * * root find /sshbot/logs -type f -mtime +7 -delete
0 0 * * * root find /root/.pm2/logs -type f -mtime +7 -delete
0 0 * * * root find /sshbot/qr_codes -type f -mtime +1 -delete
EOF
chmod 644 /etc/cron.d/wppconnect-clean 2>/dev/null || true

# ================================================
# MOSTRAR INFORMACIÓN FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔════════════════════════════════════════════════════╗"
echo "║     ✅ INSTALACIÓN COMPLETADA                      ║"
echo "║     🔕 MODO SIN ESTADOS ACTIVADO                   ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}${BOLD}📱 BOT WPPCONNECT + IA MEJORADA${NC}"
echo -e "   • Nombre: ${GREEN}$BOT_NAME${NC}"
echo -e "   • Estados: ${RED}COMPLETAMENTE DESACTIVADOS${NC} 🔕"
echo -e "   • IA Mejorada: ${GREEN}ACTIVADA (detección técnica)${NC}"
echo -e "   • Panel VPS: ${GREEN}http://$SERVER_IP:$PANEL_PORT${NC}"
echo

echo -e "${CYAN}${BOLD}📋 MENÚ DEL BOT:${NC}"
echo -e "   *⚙️ $BOT_NAME ChatBot* 🧑‍💻"
echo -e "              ⸻↓⸻"
echo -e "   > 🕋 BIENVENIDO A TIENDA $BOT_NAME"
echo -e ""
echo -e "   1 ⁃📢 INFORMACIÓN"
echo -e "   2 ⁃🏷️ PRECIOS"
echo -e "   3 ⁃🛍️ REVENDER SERVICIO"
echo -e "   4 ⁃👥 HABLAR CON UN REPRESENTANTE"
echo

echo -e "${CYAN}${BOLD}🔄 COMANDOS PM2:${NC}"
echo -e "   • Ver QR: ${GREEN}pm2 logs wppconnect-bot${NC}"
echo -e "   • Ver logs: ${GREEN}pm2 logs wppconnect-bot${NC}"
echo -e "   • Reiniciar: ${GREEN}pm2 restart wppconnect-bot${NC}"
echo

echo -e "${RED}${BOLD}🔕 ESTADOS DE WHATSAPP: COMPLETAMENTE DESACTIVADOS${NC}"
echo -e "   • El bot NO crea estados"
echo -e "   • El bot NO cambia foto de perfil"
echo -e "   • El bot NO cambia nombre"
echo -e "   • El bot NO envía mensajes automáticos"
echo

echo -e "${GREEN}${BOLD}✅ MOSTRANDO LOGS (ESPERA EL QR)...${NC}"
sleep 2
pm2 logs wppconnect-bot
