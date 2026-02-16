#!/bin/bash
# ================================================
# BOT WHATSAPP - VERSIÓN CON PANEL VPS Y GEMINI AI
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
║        🤖 BOT WHATSAPP - VERSIÓN PANEL VPS + GEMINI        ║
║     ✅ CON IA DE GEMINI · ✅ PANEL DE CONTROL               ║
║     ✅ SIN PAGOS · ✅ SIN SSH · ✅ RUTA FIJA /sshbot        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS:${NC}"
echo -e "  🤖 ${CYAN}Gemini AI${NC} - Integración con Google Gemini"
echo -e "  💬 ${YELLOW}Prompt personalizado${NC} - Asistente de ventas configurado"
echo -e "  📱 ${PURPLE}Android/iPhone${NC} - Información para ambos sistemas"
echo -e "  📊 ${BLUE}Panel VPS${NC} - Estadísticas y control total"
echo -e "  🚫 ${RED}Sin SSH${NC} - Sin creación automática de usuarios"
echo -e "  🚫 ${RED}Sin MercadoPago${NC} - Sin pagos automáticos"
echo -e "  🚫 ${RED}Sin estados${NC} - No publica estados en WhatsApp"
echo -e "  📁 ${CYAN}Ruta fija${NC} - /sshbot (el nombre es solo visual)"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    exit 1
fi

# ================================================
# INSTALAR DEPENDENCIAS BÁSICAS PRIMERO
# ================================================
echo -e "\n${CYAN}${BOLD}📦 INSTALANDO DEPENDENCIAS BÁSICAS...${NC}"
apt-get update -y
apt-get install -y curl wget git nano sqlite3 jq unzip nginx chromium-browser chromium-chromedriver
apt-get install -y gcc g++ make

# Instalar Node.js 18.x si no está
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}📦 Instalando Node.js 18.x...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# Instalar PM2 si no está
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}📦 Instalando PM2...${NC}"
    npm install -g pm2
fi

# Verificar instalaciones
echo -e "${GREEN}✅ Node.js: $(node --version)${NC}"
echo -e "${GREEN}✅ npm: $(npm --version)${NC}"
echo -e "${GREEN}✅ PM2: $(pm2 --version)${NC}"
echo -e "${GREEN}✅ SQLite3: $(sqlite3 --version)${NC}"

# ================================================
# CONFIGURACIÓN DEL NOMBRE (SOLO VISUAL)
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT${NC}"

read -p "📝 NOMBRE PARA TU BOT (ej: TIENDA LIBRE|AR o SERVERTUC): " BOT_NAME
BOT_NAME=${BOT_NAME:-"TIENDA LIBRE|AR"}

echo -e "\n${GREEN}✅ NOMBRE CONFIGURADO:${NC}"
echo -e "   • Nombre visible: ${CYAN}$BOT_NAME${NC}"
echo -e "   • Ruta de instalación: ${CYAN}/sshbot (fija)${NC}"

# ================================================
# RUTAS FIJAS
# ================================================
INSTALL_DIR="/sshbot"
SESSION_DIR="/root/.wppconnect/session"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
INFO_FILE="$INSTALL_DIR/config/info.txt"
PROMPT_FILE="$INSTALL_DIR/config/gemini_prompt.txt"

echo -e "\n${YELLOW}📁 RUTAS FIJAS:${NC}"
echo -e "   • Instalación: ${CYAN}$INSTALL_DIR${NC}"
echo -e "   • Proceso PM2: ${CYAN}wassh-bot${NC}"
echo -e "   • Sesión WhatsApp: ${CYAN}$SESSION_DIR${NC}"
echo -e "   • Base de datos: ${CYAN}$DB_FILE${NC}"

read -p "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 0
fi

# ================================================
# LIMPIEZA
# ================================================
echo -e "\n${CYAN}${BOLD}🧹 LIMPIEZA...${NC}"

# Detener procesos si existen
pm2 list | grep -E "wassh-bot" | awk '{print $2}' | xargs -r pm2 delete 2>/dev/null || true
pkill -f chrome 2>/dev/null || true
pkill -f node 2>/dev/null || true

# Limpiar directorios
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
echo -e "${GREEN}✅ Estructura creada en $INSTALL_DIR${NC}"

# ================================================
# CONFIGURACIÓN DE GEMINI AI
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CONFIGURACIÓN DE IA GEMINI${NC}"
read -p "🔑 Ingresa tu API Key de Google Gemini (deja vacío para desactivar): " GEMINI_API_KEY
GEMINI_API_KEY=${GEMINI_API_KEY:-""}

if [ -n "$GEMINI_API_KEY" ]; then
    echo -e "${GREEN}✅ API Key de Gemini configurada${NC}"
else
    echo -e "${YELLOW}⚠️  Gemini AI desactivado (sin API Key)${NC}"
fi

# ================================================
# GUARDAR PROMPT DE GEMINI
# ================================================
echo -e "\n${CYAN}💬 Guardando prompt personalizado...${NC}"
cat > "$PROMPT_FILE" << 'PROMPT_EOF'
actúa como un asistente de una compañía de venta de servicios de internet para celulares Android y iPhone!

dicho servicio se vende como archivos de Configuración llamados también (servidores, servers) (algunos clientes se referirán a el como llavecita)

(MUY IMPORTANTE QUE ACLARES QUE ESTA DISPONIBLE PARA ANDROID Y IPHONE) Y SOLO PARA PERSONAL ABONO Y PREPAGO!

(NO DISPONIBLE PARA OTRAS EMPRESAS COMO: MOVISTAR, TUENTI O CLARO)

NUESTRO SERVICIO FUNCIONA EN ANDROID Y EN IPHONE

ANTE TODO PREGUNTA SIEMPRE SI YA CUENTAN CON NUESTO SERVICIO O SI QUIEREN CONTRATAR

MENSIONA EL METODO DE PAGO:

(El método de pago es vía transferencia)

(NO HAGAS VENTAS NI PIDAS COMPROBANTE)

PREGUNTA SI LE INTERESA AL CLIENTE LO PUEDES TRANFERIR CON UN REPRESENTANTE (ESTAN DISPONIBLES DE 10:30 a 22:30) Y ACLARA EL HORARIO AL TRANFERIRLOS CON LOS REPRESENTANTES.
PROMPT_EOF
echo -e "${GREEN}✅ Prompt guardado${NC}"

# ================================================
# CONFIGURACIÓN DEL BOT
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURANDO OPCIONES...${NC}"

read -p "📲 Link de descarga para Android (Enter para omitir): " APP_LINK
APP_LINK=${APP_LINK:-"https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"}

read -p "🆘 Número de WhatsApp para representante (ej: 543435071016): " SUPPORT_NUMBER
SUPPORT_NUMBER=${SUPPORT_NUMBER:-"543435071016"}

echo -e "\n${YELLOW}💰 CONFIGURACIÓN DE PRECIOS (SOLO INFORMATIVO):${NC}"
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

read -p "🌐 Puerto para el panel VPS (3000): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-3000}

# Detectar IP
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
SERVER_IP=${SERVER_IP:-"127.0.0.1"}

# ================================================
# TEXTO DE INFORMACIÓN
# ================================================
cat > "$INFO_FILE" << 'EOF'
🔥 INTERNET ILIMITADO ⚡📱

Es una aplicación que te permite conectar y navegar en internet de manera ilimitada/infinita. Sin necesidad de tener saldo/crédito o MG/GB.

📢 Te ofrecemos internet Ilimitado para la empresa PERSONAL, tanto ABONO como PREPAGO a través de nuestra aplicación!

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
        "version": "1.0-GEMINI-PANEL",
        "server_ip": "$SERVER_IP",
        "test_hours": $TEST_HOURS,
        "info_file": "$INFO_FILE",
        "process_name": "wassh-bot",
        "panel_port": $PANEL_PORT
    },
    "gemini": {
        "api_key": "$GEMINI_API_KEY",
        "enabled": $(if [ -n "$GEMINI_API_KEY" ]; then echo "true"; else echo "false"; fi),
        "model": "gemini-1.5-flash",
        "prompt_file": "$PROMPT_FILE"
    },
    "prices": {
        "test_hours": $TEST_HOURS,
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
    "paths": {
        "database": "$DB_FILE",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "$SESSION_DIR"
    },
    "features": {
        "ssh_creation": false,
        "automatic_payments": false,
        "whatsapp_status": false,
        "panel_vps": true
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
    tipo TEXT DEFAULT 'test',
    test_start DATETIME,
    test_expires DATETIME,
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

CREATE TABLE IF NOT EXISTS user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
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
CREATE INDEX IF NOT EXISTS idx_conversations_created ON conversations(created_at);
SQL

echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# CREAR PACKAGE.JSON
# ================================================
echo -e "\n${CYAN}📦 Creando package.json...${NC}"

cat > "$INSTALL_DIR/package.json" << 'EOF'
{
    "name": "wassh-bot-gemini",
    "version": "1.0.0",
    "description": "Bot WhatsApp con Gemini AI y Panel VPS",
    "main": "bot.js",
    "scripts": {
        "start": "node bot.js",
        "pm2": "pm2 start bot.js --name wassh-bot",
        "pm2-stop": "pm2 stop wassh-bot",
        "pm2-logs": "pm2 logs wassh-bot"
    },
    "dependencies": {
        "@google/generative-ai": "^0.1.3",
        "whatsapp-web.js": "^1.23.0",
        "qrcode-terminal": "^0.12.0",
        "express": "^4.18.2",
        "sqlite3": "^5.1.6",
        "cors": "^2.8.5",
        "axios": "^1.6.0",
        "moment": "^2.29.4"
    }
}
EOF

# ================================================
# CREAR ARCHIVO PRINCIPAL DEL BOT
# ================================================
echo -e "\n${CYAN}📝 Creando archivo principal del bot...${NC}"

cat > "$INSTALL_DIR/bot.js" << 'EOF'
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');
const cors = require('cors');

// Configuración
const config = JSON.parse(fs.readFileSync('/sshbot/config/config.json'));
const promptSistema = fs.readFileSync(config.gemini.prompt_file, 'utf8');

// Inicializar Gemini
let genAI;
if (config.gemini.enabled) {
    genAI = new GoogleGenerativeAI(config.gemini.api_key);
}

// Base de datos
const db = new sqlite3.Database(config.paths.database);

// Express app
const app = express();
app.use(cors());
app.use(express.json());

// ================================================
// CLIENTE WHATSAPP
// ================================================
const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: config.paths.sessions
    }),
    puppeteer: {
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--disable-gpu'
        ]
    }
});

// ================================================
// FUNCIÓN GEMINI
// ================================================
async function procesarConGemini(mensaje, numero) {
    if (!config.gemini.enabled || !genAI) {
        return null;
    }

    try {
        const model = genAI.getGenerativeModel({ model: config.gemini.model });
        const fullPrompt = `${promptSistema}\n\nCliente: ${mensaje}\nAsistente:`;
        const result = await model.generateContent(fullPrompt);
        const response = await result.response;
        const text = response.text();
        
        db.run('INSERT INTO conversations (phone, message, response) VALUES (?, ?, ?)',
            [numero, mensaje, text]);
        
        return text;
    } catch (error) {
        console.error('Error con Gemini:', error);
        return "Lo siento, tuve un problema para procesar tu mensaje. Por favor, intenta de nuevo o contacta a un representante.";
    }
}

// ================================================
// MANEJAR COMANDOS
// ================================================
async function manejarComandos(message) {
    const comando = message.body.toLowerCase();
    const numero = message.from;
    
    switch(comando) {
        case '/info':
            const infoText = fs.readFileSync(config.bot.info_file, 'utf8');
            await message.reply(infoText);
            break;
            
        case '/precios':
            await message.reply(`💰 *PRECIOS*\n\n` +
                `📱 Servicio para *PERSONAL* (Abono y Prepago)\n` +
                `✅ Disponible para Android y iPhone\n\n` +
                `• 7 días: $${config.prices.price_7d}\n` +
                `• 15 días: $${config.prices.price_15d}\n` +
                `• 30 días: $${config.prices.price_30d}\n` +
                `• 50 días: $${config.prices.price_50d}\n\n` +
                `💳 Método de pago: Transferencia bancaria\n\n` +
                `Para contratar, escribe /soporte`);
            break;
            
        case '/soporte':
            await message.reply(`Te transfiero con un representante:\n\n` +
                `🔗 ${config.links.support}\n\n` +
                `🕐 Horario: 10:30 a 22:30`);
            break;
            
        case '/android':
            await message.reply(`📱 *DESCARGA ANDROID*\n\n` +
                `🔗 ${config.links.app_android}\n\n` +
                `Luego escribe /soporte para ayuda.`);
            break;
            
        case '/iphone':
            await message.reply(`📱 *DESCARGA IPHONE*\n\n` +
                `Contacta a un representante con /soporte para la instalación.`);
            break;
            
        default:
            await message.reply(`Comandos:\n` +
                `/info - Información\n` +
                `/precios - Ver precios\n` +
                `/soporte - Contactar\n` +
                `/android - Descarga Android\n` +
                `/iphone - Descarga iPhone`);
    }
}

// ================================================
// EVENTOS WHATSAPP
// ================================================
client.on('qr', (qr) => {
    console.log('\n📱 ESCANEA ESTE QR CON WHATSAPP:\n');
    qrcode.generate(qr, { small: true });
});

client.on('ready', () => {
    console.log('\n✅ BOT CONECTADO A WHATSAPP\n');
    db.run('INSERT INTO logs (type, message) VALUES (?, ?)', ['system', 'Bot conectado']);
});

client.on('message', async (message) => {
    try {
        if (message.from.includes('@g.us')) return;
        
        console.log(`📨 Mensaje de ${message.from}: ${message.body}`);
        
        if (message.body.startsWith('/')) {
            await manejarComandos(message);
            return;
        }
        
        const respuestaIA = await procesarConGemini(message.body, message.from);
        if (respuestaIA) {
            await message.reply(respuestaIA);
        }
    } catch (error) {
        console.error('Error:', error);
    }
});

// ================================================
// API ENDPOINTS
// ================================================
app.get('/api/stats', (req, res) => {
    db.get(`
        SELECT 
            (SELECT COUNT(*) FROM users) as total_users,
            (SELECT COUNT(*) FROM conversations WHERE date(created_at) = date('now')) as today_conversations,
            (SELECT COUNT(*) FROM conversations) as total_conversations
    `, (err, row) => {
        if (err) res.status(500).json({ error: err.message });
        else res.json(row || { total_users: 0, today_conversations: 0, total_conversations: 0 });
    });
});

app.get('/api/users/recent', (req, res) => {
    db.all(`SELECT * FROM users ORDER BY created_at DESC LIMIT 10`, (err, rows) => {
        if (err) res.status(500).json({ error: err.message });
        else res.json(rows || []);
    });
});

app.get('/api/conversations/recent', (req, res) => {
    db.all(`SELECT * FROM conversations ORDER BY created_at DESC LIMIT 20`, (err, rows) => {
        if (err) res.status(500).json({ error: err.message });
        else res.json(rows || []);
    });
});

app.get('/api/logs', (req, res) => {
    db.all(`SELECT * FROM logs ORDER BY created_at DESC LIMIT 20`, (err, rows) => {
        if (err) res.status(500).json({ error: err.message });
        else res.json(rows || []);
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
            <title>Panel VPS - ${config.bot.name}</title>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    font-family: Arial, sans-serif;
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
                .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
                .section h2 {
                    color: #333;
                    margin-bottom: 15px;
                    padding-bottom: 10px;
                    border-bottom: 2px solid #667eea;
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
                th {
                    background: #f5f5f5;
                }
                .badge {
                    padding: 3px 8px;
                    border-radius: 3px;
                    font-size: 0.85em;
                    font-weight: bold;
                }
                .badge-success { background: #28a745; color: white; }
                .badge-info { background: #17a2b8; color: white; }
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
                    font-size: 1em;
                }
                .refresh-btn:hover {
                    background: #5a67d8;
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
                <h1>🤖 Panel de Control - ${config.bot.name}</h1>
                
                <div class="stats-grid" id="stats">
                    <div class="stat-card">
                        <div>📱 Usuarios</div>
                        <div class="stat-value" id="totalUsers">0</div>
                    </div>
                    <div class="stat-card">
                        <div>💬 Conversaciones Hoy</div>
                        <div class="stat-value" id="todayChats">0</div>
                    </div>
                    <div class="stat-card">
                        <div>📊 Total Conversaciones</div>
                        <div class="stat-value" id="totalChats">0</div>
                    </div>
                    <div class="stat-card">
                        <div>🤖 Gemini</div>
                        <div class="stat-value" id="geminiStatus">${config.gemini.enabled ? '✅' : '❌'}</div>
                    </div>
                </div>

                <div class="sections">
                    <div class="section">
                        <h2>📱 Usuarios Recientes</h2>
                        <table>
                            <thead>
                                <tr><th>Teléfono</th><th>Tipo</th><th>Fecha</th></tr>
                            </thead>
                            <tbody id="usersBody">
                                <tr><td colspan="3">Cargando...</td></tr>
                            </tbody>
                        </table>
                    </div>
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
                </div>

                <div class="section" style="margin-top:20px;">
                    <h2>📋 Últimos Logs</h2>
                    <table>
                        <thead>
                            <tr><th>Tipo</th><th>Mensaje</th><th>Hora</th></tr>
                        </thead>
                        <tbody id="logsBody">
                            <tr><td colspan="3">Cargando...</td></tr>
                        </tbody>
                    </table>
                </div>

                <button class="refresh-btn" onclick="cargarDatos()">🔄 Actualizar Datos</button>
            </div>

            <script>
                async function cargarDatos() {
                    try {
                        // Estadísticas
                        const stats = await fetch('/api/stats').then(r => r.json());
                        document.getElementById('totalUsers').textContent = stats.total_users || 0;
                        document.getElementById('todayChats').textContent = stats.today_conversations || 0;
                        document.getElementById('totalChats').textContent = stats.total_conversations || 0;
                        
                        // Usuarios
                        const users = await fetch('/api/users/recent').then(r => r.json());
                        document.getElementById('usersBody').innerHTML = users.length ? 
                            users.map(u => \`<tr>
                                <td>\${u.phone}</td>
                                <td><span class="badge \${u.tipo === 'test' ? 'badge-info' : 'badge-success'}">\${u.tipo}</span></td>
                                <td>\${new Date(u.created_at).toLocaleString()}</td>
                            </tr>\`).join('') :
                            '<tr><td colspan="3">Sin usuarios</td></tr>';
                        
                        // Conversaciones
                        const chats = await fetch('/api/conversations/recent').then(r => r.json());
                        document.getElementById('conversationsBody').innerHTML = chats.length ?
                            chats.map(c => \`<tr>
                                <td>\${c.phone}</td>
                                <td>\${c.message.substring(0,30)}\${c.message.length > 30 ? '...' : ''}</td>
                                <td>\${new Date(c.created_at).toLocaleTimeString()}</td>
                            </tr>\`).join('') :
                            '<tr><td colspan="3">Sin conversaciones</td></tr>';
                        
                        // Logs
                        const logs = await fetch('/api/logs').then(r => r.json());
                        document.getElementById('logsBody').innerHTML = logs.length ?
                            logs.map(l => \`<tr>
                                <td>\${l.type}</td>
                                <td>\${l.message}</td>
                                <td>\${new Date(l.created_at).toLocaleTimeString()}</td>
                            </tr>\`).join('') :
                            '<tr><td colspan="3">Sin logs</td></tr>';
                    } catch (e) {
                        console.error('Error:', e);
                    }
                }
                
                // Cargar cada 30 segundos
                cargarDatos();
                setInterval(cargarDatos, 30000);
            </script>
        </body>
        </html>
    `);
});

// ================================================
// INICIAR SERVIDOR
// ================================================
app.listen(config.bot.panel_port, '0.0.0.0', () => {
    console.log(`
╔════════════════════════════════════════════════════╗
║  📊 PANEL VPS ACTIVADO                             ║
╠════════════════════════════════════════════════════╣
║  • URL: http://${config.bot.server_ip}:${config.bot.panel_port}  ║
║  • Gemini: ${config.gemini.enabled ? '✅ ACTIVADO' : '❌ DESACTIVADO'}                ║
║  • Bot: ${config.bot.name}                         ║
╚════════════════════════════════════════════════════╝
    `);
});

// Inicializar WhatsApp
client.initialize();

// Manejo de errores
process.on('uncaughtException', (error) => {
    console.error('Error no capturado:', error);
    db.run('INSERT INTO logs (type, message, data) VALUES (?, ?, ?)',
        ['error', error.message, JSON.stringify(error)]);
});
EOF

# ================================================
# INSTALAR DEPENDENCIAS NODE
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias de Node.js...${NC}"
cd "$INSTALL_DIR"
npm install

# ================================================
# CONFIGURAR NGINX
# ================================================
echo -e "\n${CYAN}🌐 Configurando Nginx...${NC}"
cat > /etc/nginx/sites-available/wassh-panel << EOF
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
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Activar configuración de Nginx
ln -sf /etc/nginx/sites-available/wassh-panel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx || echo -e "${YELLOW}⚠️  Nginx no se pudo configurar, pero el panel funciona en el puerto $PANEL_PORT${NC}"

# ================================================
# INICIAR BOT CON PM2
# ================================================
echo -e "\n${CYAN}🚀 Iniciando el bot con PM2...${NC}"
cd "$INSTALL_DIR"
pm2 start bot.js --name wassh-bot
pm2 save
pm2 startup

# Configurar PM2 para iniciar con el sistema
env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u root --hp /root

# ================================================
# CONFIGURAR CRON PARA MANTENIMIENTO
# ================================================
echo -e "\n${CYAN}⏰ Configurando mantenimiento automático...${NC}"
cat > /etc/cron.d/wassh-maintenance << EOF
# Limpiar logs cada día
0 0 * * * root find /sshbot/logs -type f -mtime +7 -delete
0 0 * * * root find /root/.pm2/logs -type f -mtime +7 -delete
# Limpiar QRs viejos
*/30 * * * * root find /sshbot/qr_codes -type f -mmin +30 -delete
EOF

chmod 644 /etc/cron.d/wassh-maintenance

# ================================================
# MOSTRAR INFORMACIÓN FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔════════════════════════════════════════════════════╗"
echo "║     ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE        ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}${BOLD}📱 BOT WHATSAPP${NC}"
echo -e "   • Nombre: ${GREEN}$BOT_NAME${NC}"
echo -e "   • Estado: ${GREEN}ACTIVO${NC}"
echo -e "   • Gemini AI: ${GREEN}$([ -n "$GEMINI_API_KEY" ] && echo "ACTIVADO" || echo "DESACTIVADO")${NC}"
echo

echo -e "${CYAN}${BOLD}📊 PANEL VPS${NC}"
echo -e "   • URL Directa: ${GREEN}http://$SERVER_IP:$PANEL_PORT${NC}"
echo -e "   • URL vía Nginx: ${GREEN}http://$SERVER_IP${NC}"
echo -e "   • Puerto: ${GREEN}$PANEL_PORT${NC}"
echo

echo -e "${CYAN}${BOLD}📁 RUTAS IMPORTANTES${NC}"
echo -e "   • Instalación: ${GREEN}/sshbot${NC}"
echo -e "   • Base de datos: ${GREEN}$DB_FILE${NC}"
echo -e "   • Prompt Gemini: ${GREEN}$PROMPT_FILE${NC}"
echo -e "   • Sesión WhatsApp: ${GREEN}$SESSION_DIR${NC}"
echo

echo -e "${CYAN}${BOLD}🔄 COMANDOS ÚTILES${NC}"
echo -e "   • Ver logs del bot: ${GREEN}pm2 logs wassh-bot${NC}"
echo -e "   • Ver estado: ${GREEN}pm2 status${NC}"
echo -e "   • Reiniciar bot: ${GREEN}pm2 restart wassh-bot${NC}"
echo -e "   • Detener bot: ${GREEN}pm2 stop wassh-bot${NC}"
echo -e "   • Ver QR (si es necesario): ${GREEN}pm2 logs wassh-bot | grep -A 10 \"ESCANEA\"${NC}"
echo

echo -e "${CYAN}${BOLD}📱 COMANDOS DEL BOT${NC}"
echo -e "   • ${GREEN}/info${NC}     - Información del servicio"
echo -e "   • ${GREEN}/precios${NC}  - Ver precios"
echo -e "   • ${GREEN}/soporte${NC}  - Contactar representante"
echo -e "   • ${GREEN}/android${NC}  - Descarga para Android"
echo -e "   • ${GREEN}/iphone${NC}   - Descarga para iPhone"
echo

echo -e "${YELLOW}${BOLD}⚠️  PRÓXIMOS PASOS:${NC}"
echo -e "   1. Espera a que aparezca el código QR en los logs"
echo -e "   2. Escanea el QR con WhatsApp (celular principal)"
echo -e "   3. Accede al panel VPS para monitorear"
echo -e "   4. Prueba los comandos enviando mensajes al bot"
echo

echo -e "${GREEN}${BOLD}✅ PARA VER EL QR AHORA MISMO, EJECUTA:${NC}"
echo -e "   ${CYAN}pm2 logs wassh-bot${NC}"
echo

# Mostrar el QR inmediatamente si ya está disponible
echo -e "${YELLOW}Mostrando logs en tiempo real (esperando QR)...${NC}"
echo -e "${BLUE}Presiona Ctrl+C para salir de los logs cuando veas el QR${NC}"
sleep 3
pm2 logs wassh-bot
