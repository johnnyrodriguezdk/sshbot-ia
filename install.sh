#!/bin/bash
# ================================================
# BOT WHATSAPP - VERSIÓN CON PANEL VPS Y GEMINI AI
# ================================================
# CARACTERÍSTICAS:
# ✅ GEMINI AI INTEGRADO CON PROMPT PERSONALIZADO
# ✅ PANEL VPS COMPLETO CON ESTADÍSTICAS
# ✅ SIN CREACIÓN AUTOMÁTICA DE USUARIOS SSH
# ✅ SIN PAGOS AUTOMÁTICOS (MERCADOPAGO DESACTIVADO)
# ✅ SIN ESTADOS AUTOMÁTICOS EN WHATSAPP
# ✅ BASE DE DATOS SQLITE
# ✅ RUTA FIJA: /sshbot (EL NOMBRE DINÁMICO ES SOLO VISUAL)
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
# CONFIGURACIÓN DEL NOMBRE (SOLO VISUAL)
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT${NC}"

# Pedir nombre (solo visual)
read -p "📝 NOMBRE PARA TU BOT (ej: TIENDA LIBRE|AR o SERVERTUC): " BOT_NAME
BOT_NAME=${BOT_NAME:-"TIENDA LIBRE|AR"}

# Ya no afecta rutas, solo es visual
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
# LIMPIEZA TOTAL
# ================================================
echo -e "\n${CYAN}${BOLD}🧹 LIMPIEZA TOTAL...${NC}"

# Detener procesos
pm2 list | grep -E "(wassh-bot|bot|libre|serv|tienda)" | awk '{print $2}' | xargs -r pm2 delete 2>/dev/null
pm2 kill 2>/dev/null
pkill -f chrome 2>/dev/null
pkill -f node 2>/dev/null

# Limpiar directorios
rm -rf /sshbot 2>/dev/null
rm -rf /root/.wppconnect 2>/dev/null
rm -rf /root/.pm2/logs/* 2>/dev/null

echo -e "${GREEN}✅ Limpieza completada${NC}"

# ================================================
# CREAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes,public,views}
mkdir -p "$SESSION_DIR"
mkdir -p "$INSTALL_DIR/panel/static"
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
echo -e "\n${CYAN}💬 Guardando prompt personalizado para el asistente...${NC}"
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
echo -e "${GREEN}✅ Prompt guardado en $PROMPT_FILE${NC}"

# ================================================
# CONFIGURACIÓN DEL BOT
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURANDO OPCIONES...${NC}"

# Link de la APP
read -p "📲 Link de descarga para Android: " APP_LINK
APP_LINK=${APP_LINK:-"https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"}

# Número de soporte
read -p "🆘 Número de WhatsApp para representante (sin +): " SUPPORT_NUMBER
SUPPORT_NUMBER=${SUPPORT_NUMBER:-"543435071016"}

# Precios (solo informativos, sin procesar pagos)
echo -e "\n${YELLOW}💰 CONFIGURACIÓN DE PRECIOS (ARS) - SOLO INFORMATIVO:${NC}"
read -p "Precio 7 días (3000): " PRICE_7D
PRICE_7D=${PRICE_7D:-3000}
read -p "Precio 15 días (4000): " PRICE_15D
PRICE_15D=${PRICE_15D:-4000}
read -p "Precio 30 días (7000): " PRICE_30D
PRICE_30D=${PRICE_30D:-7000}
read -p "Precio 50 días (9700): " PRICE_50D
PRICE_50D=${PRICE_50D:-9700}

# Horas de prueba
read -p "⏰ Horas de prueba gratis (2): " TEST_HOURS
TEST_HOURS=${TEST_HOURS:-2}

# Puerto para el panel VPS
read -p "🌐 Puerto para el panel VPS (3000): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-3000}

# Detectar IP
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
SERVER_IP=${SERVER_IP:-"127.0.0.1"}

# ================================================
# TEXTO DE INFORMACIÓN PERSONALIZADO
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
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "public_key": ""
    },
    "links": {
        "app_android": "$APP_LINK",
        "support": "https://wa.me/$SUPPORT_NUMBER"
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "$SESSION_DIR",
        "panel_static": "$INSTALL_DIR/panel/static",
        "panel_views": "$INSTALL_DIR/views"
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
# CREAR BASE DE DATOS SIMPLIFICADA
# ================================================
echo -e "\n${CYAN}🗄️ Creando base de datos SQLite...${NC}"

sqlite3 "$DB_FILE" << 'SQL'
-- Tabla de usuarios (solo para registro, sin creación SSH)
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT UNIQUE,
    name TEXT,
    tipo TEXT DEFAULT 'test',
    test_start DATETIME,
    test_expires DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Control de pruebas diarias
CREATE TABLE daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);

-- Registro de conversaciones para Gemini
CREATE TABLE conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    message TEXT,
    response TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Sistema de estados del menú
CREATE TABLE user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Logs del sistema
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_conversations_phone ON conversations(phone);
CREATE INDEX idx_conversations_created ON conversations(created_at);
SQL

echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# INSTALAR DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias del sistema...${NC}"
apt-get update -y
apt-get upgrade -y

# Node.js 18.x
echo -e "${YELLOW}📦 Instalando Node.js 18.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs gcc g++ make

# Chrome
echo -e "${YELLOW}🌐 Instalando Google Chrome...${NC}"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Otras dependencias
echo -e "${YELLOW}📦 Instalando utilidades...${NC}"
apt-get install -y sqlite3 jq curl wget git unzip nginx

# ================================================
# INSTALAR PM2
# ================================================
echo -e "\n${CYAN}📦 Instalando PM2...${NC}"
npm install -y -g pm2
pm2 update

# ================================================
# CREAR ARCHIVO PRINCIPAL DEL BOT
# ================================================
echo -e "\n${CYAN}📝 Creando archivo principal del bot...${NC}"

cat > "$INSTALL_DIR/bot.js" << 'EOF'
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');
const cors = require('cors');

// Configuración
const config = JSON.parse(fs.readFileSync('/sshbot/config/config.json'));
const promptSistema = fs.readFileSync(config.gemini.prompt_file, 'utf8');

// Inicializar Gemini si está configurado
let genAI;
if (config.gemini.enabled) {
    genAI = new GoogleGenerativeAI(config.gemini.api_key);
}

// Base de datos
const db = new sqlite3.Database(config.paths.database);

// Inicializar Express para el panel VPS
const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(config.paths.panel_static));

// ================================================
// CONFIGURACIÓN DEL CLIENTE WHATSAPP
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
            '--single-process',
            '--disable-gpu'
        ],
        executablePath: config.paths.chromium
    }
});

// ================================================
// MANEJADOR DE MENSAJES CON GEMINI
// ================================================
async function procesarConGemini(mensaje, numero) {
    if (!config.gemini.enabled || !genAI) {
        return null;
    }

    try {
        const model = genAI.getGenerativeModel({ model: config.gemini.model });
        
        // Combinar prompt del sistema con el mensaje del usuario
        const fullPrompt = `${promptSistema}\n\nCliente: ${mensaje}\nAsistente:`;
        
        const result = await model.generateContent(fullPrompt);
        const response = await result.response;
        const text = response.text();
        
        // Guardar conversación en DB
        db.run(
            'INSERT INTO conversations (phone, message, response) VALUES (?, ?, ?)',
            [numero, mensaje, text]
        );
        
        return text;
    } catch (error) {
        console.error('Error con Gemini:', error);
        
        db.run(
            'INSERT INTO logs (type, message, data) VALUES (?, ?, ?)',
            ['gemini_error', error.message, JSON.stringify(error)]
        );
        
        return "Lo siento, tuve un problema para procesar tu mensaje. Por favor, intenta de nuevo o contacta a un representante.";
    }
}

// ================================================
// EVENTOS DEL CLIENTE WHATSAPP
// ================================================
client.on('qr', (qr) => {
    console.log('📱 ESCANEA ESTE QR CON WHATSAPP:');
    qrcode.generate(qr, { small: true });
    
    // Guardar QR como imagen
    const qrPath = path.join(config.paths.qr_codes, 'qr_latest.png');
    // Aquí iría la lógica para guardar el QR
});

client.on('ready', () => {
    console.log('✅ BOT CONECTADO A WHATSAPP');
    
    db.run(
        'INSERT INTO logs (type, message) VALUES (?, ?)',
        ['system', 'Bot conectado a WhatsApp']
    );
});

client.on('message', async (message) => {
    try {
        const numero = message.from;
        const texto = message.body.toLowerCase();
        
        // Ignorar mensajes de grupos
        if (message.from.includes('@g.us')) return;
        
        console.log(`📨 Mensaje de ${numero}: ${message.body}`);
        
        // Verificar si es un comando
        if (texto.startsWith('/')) {
            await manejarComandos(message);
            return;
        }
        
        // Si no es comando y Gemini está activado, procesar con IA
        const respuestaIA = await procesarConGemini(message.body, numero);
        
        if (respuestaIA) {
            await message.reply(respuestaIA);
        } else {
            // Respuesta por defecto si Gemini no está activado
            await message.reply(`Hola! Soy el asistente de *${config.bot.name}*. ¿En qué puedo ayudarte?\n\nComandos disponibles:\n/info - Información del servicio\n/precios - Ver precios\n/soporte - Contactar representante`);
        }
    } catch (error) {
        console.error('Error procesando mensaje:', error);
    }
});

// ================================================
// COMANDOS BÁSICOS
// ================================================
async function manejarComandos(message) {
    const comando = message.body.toLowerCase();
    const numero = message.from;
    
    switch(comando) {
        case '/info':
        case '/info':
            const infoText = fs.readFileSync(config.bot.info_file, 'utf8');
            await message.reply(infoText);
            break;
            
        case '/precios':
        case '/precios':
            await message.reply(`💰 *PRECIOS*\n\n` +
                `📱 Servicio para *PERSONAL* (Abono y Prepago)\n` +
                `✅ Disponible para Android y iPhone\n\n` +
                `• 7 días: $${config.prices.price_7d}\n` +
                `• 15 días: $${config.prices.price_15d}\n` +
                `• 30 días: $${config.prices.price_30d}\n` +
                `• 50 días: $${config.prices.price_50d}\n\n` +
                `💳 Método de pago: Transferencia bancaria\n\n` +
                `Para contratar, escribe /soporte y te transferiré con un representante (disponibles de 10:30 a 22:30)`);
            break;
            
        case '/soporte':
        case '/soporte':
            await message.reply(`Te transfiero con un representante para que puedas contratar el servicio.\n\n` +
                `🔗 *Enlace directo:* ${config.links.support}\n\n` +
                `🕐 Horario de atención: 10:30 a 22:30`);
            break;
            
        case '/android':
        case '/android':
            await message.reply(`📱 *DESCARGA PARA ANDROID*\n\n` +
                `✅ Compatible con PERSONAL Abono y Prepago\n\n` +
                `🔗 Link de descarga:\n${config.links.app_android}\n\n` +
                `Después de instalar, escribe /soporte para que te ayuden con la configuración.`);
            break;
            
        case '/iphone':
        case '/apple':
        case '/iphone':
            await message.reply(`📱 *DESCARGA PARA IPHONE*\n\n` +
                `✅ Compatible con PERSONAL Abono y Prepago\n\n` +
                `Para iPhone, el proceso es diferente. Por favor, contacta a un representante con /soporte para que te guíen en la instalación.`);
            break;
            
        default:
            await message.reply(`Comando no reconocido. Comandos disponibles:\n` +
                `/info - Información del servicio\n` +
                `/precios - Ver precios\n` +
                `/soporte - Contactar representante\n` +
                `/android - Descarga Android\n` +
                `/iphone - Descarga iPhone`);
    }
}

// ================================================
// PANEL VPS - API ENDPOINTS
// ================================================
// Estadísticas generales
app.get('/api/stats', (req, res) => {
    db.get(`
        SELECT 
            (SELECT COUNT(*) FROM users) as total_users,
            (SELECT COUNT(*) FROM users WHERE tipo='test') as test_users,
            (SELECT COUNT(*) FROM conversations WHERE date(created_at) = date('now')) as today_conversations,
            (SELECT COUNT(*) FROM conversations) as total_conversations
    `, (err, row) => {
        if (err) {
            res.status(500).json({ error: err.message });
        } else {
            res.json(row);
        }
    });
});

// Usuarios recientes
app.get('/api/users/recent', (req, res) => {
    db.all(`
        SELECT * FROM users 
        ORDER BY created_at DESC 
        LIMIT 10
    `, (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
        } else {
            res.json(rows);
        }
    });
});

// Conversaciones recientes
app.get('/api/conversations/recent', (req, res) => {
    db.all(`
        SELECT * FROM conversations 
        ORDER BY created_at DESC 
        LIMIT 20
    `, (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
        } else {
            res.json(rows);
        }
    });
});

// Logs del sistema
app.get('/api/logs', (req, res) => {
    db.all(`
        SELECT * FROM logs 
        ORDER BY created_at DESC 
        LIMIT 50
    `, (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
        } else {
            res.json(rows);
        }
    });
});

// Información del bot
app.get('/api/bot/info', (req, res) => {
    res.json({
        name: config.bot.name,
        status: 'online',
        uptime: process.uptime(),
        gemini_enabled: config.gemini.enabled,
        version: config.bot.version
    });
});

// ================================================
// PANEL VPS - PÁGINA PRINCIPAL
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
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
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
                    font-size: 2.5em;
                    text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
                }
                .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                    gap: 20px;
                    margin-bottom: 30px;
                }
                .stat-card {
                    background: white;
                    padding: 25px;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                    text-align: center;
                    transition: transform 0.3s;
                }
                .stat-card:hover {
                    transform: translateY(-5px);
                    box-shadow: 0 6px 12px rgba(0,0,0,0.15);
                }
                .stat-value {
                    font-size: 2.5em;
                    font-weight: bold;
                    color: #667eea;
                    margin: 10px 0;
                }
                .stat-label {
                    color: #666;
                    font-size: 1.1em;
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
                    margin-bottom: 20px;
                    padding-bottom: 10px;
                    border-bottom: 2px solid #667eea;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                }
                th, td {
                    padding: 12px;
                    text-align: left;
                    border-bottom: 1px solid #ddd;
                }
                th {
                    background: #f8f9fa;
                    color: #333;
                    font-weight: 600;
                }
                tr:hover {
                    background: #f5f5f5;
                }
                .badge {
                    display: inline-block;
                    padding: 3px 8px;
                    border-radius: 3px;
                    font-size: 0.85em;
                    font-weight: 600;
                }
                .badge-success {
                    background: #28a745;
                    color: white;
                }
                .badge-info {
                    background: #17a2b8;
                    color: white;
                }
                .refresh-btn {
                    display: block;
                    width: 200px;
                    margin: 20px auto;
                    padding: 10px 20px;
                    background: #667eea;
                    color: white;
                    border: none;
                    border-radius: 5px;
                    cursor: pointer;
                    font-size: 1em;
                    transition: background 0.3s;
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
                        <div>📱 Usuarios Totales</div>
                        <div class="stat-value" id="totalUsers">-</div>
                    </div>
                    <div class="stat-card">
                        <div>🧪 En Prueba</div>
                        <div class="stat-value" id="testUsers">-</div>
                    </div>
                    <div class="stat-card">
                        <div>💬 Conversaciones Hoy</div>
                        <div class="stat-value" id="todayChats">-</div>
                    </div>
                    <div class="stat-card">
                        <div>📊 Total Conversaciones</div>
                        <div class="stat-value" id="totalChats">-</div>
                    </div>
                </div>

                <div class="sections">
                    <div class="section">
                        <h2>📱 Usuarios Recientes</h2>
                        <table id="usersTable">
                            <thead>
                                <tr>
                                    <th>Teléfono</th>
                                    <th>Tipo</th>
                                    <th>Fecha</th>
                                </tr>
                            </thead>
                            <tbody id="usersBody">
                                <tr><td colspan="3">Cargando...</td></tr>
                            </tbody>
                        </table>
                    </div>

                    <div class="section">
                        <h2>💬 Últimas Conversaciones</h2>
                        <table id="conversationsTable">
                            <thead>
                                <tr>
                                    <th>Teléfono</th>
                                    <th>Mensaje</th>
                                    <th>Hora</th>
                                </tr>
                            </thead>
                            <tbody id="conversationsBody">
                                <tr><td colspan="3">Cargando...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <button class="refresh-btn" onclick="cargarDatos()">🔄 Actualizar Datos</button>
            </div>

            <script>
                async function cargarDatos() {
                    try {
                        // Cargar estadísticas
                        const statsRes = await fetch('/api/stats');
                        const stats = await statsRes.json();
                        document.getElementById('totalUsers').textContent = stats.total_users || 0;
                        document.getElementById('testUsers').textContent = stats.test_users || 0;
                        document.getElementById('todayChats').textContent = stats.today_conversations || 0;
                        document.getElementById('totalChats').textContent = stats.total_conversations || 0;

                        // Cargar usuarios
                        const usersRes = await fetch('/api/users/recent');
                        const users = await usersRes.json();
                        const usersBody = document.getElementById('usersBody');
                        if (users.length === 0) {
                            usersBody.innerHTML = '<tr><td colspan="3">No hay usuarios</td></tr>';
                        } else {
                            usersBody.innerHTML = users.map(user => 
                                \`<tr>
                                    <td>\${user.phone}</td>
                                    <td><span class="badge \${user.tipo === 'test' ? 'badge-info' : 'badge-success'}">\${user.tipo}</span></td>
                                    <td>\${new Date(user.created_at).toLocaleString()}</td>
                                </tr>\`
                            ).join('');
                        }

                        // Cargar conversaciones
                        const convRes = await fetch('/api/conversations/recent');
                        const conversations = await convRes.json();
                        const convBody = document.getElementById('conversationsBody');
                        if (conversations.length === 0) {
                            convBody.innerHTML = '<tr><td colspan="3">No hay conversaciones</td></tr>';
                        } else {
                            convBody.innerHTML = conversations.map(conv => 
                                \`<tr>
                                    <td>\${conv.phone}</td>
                                    <td>\${conv.message.substring(0, 30)}\${conv.message.length > 30 ? '...' : ''}</td>
                                    <td>\${new Date(conv.created_at).toLocaleTimeString()}</td>
                                </tr>\`
                            ).join('');
                        }
                    } catch (error) {
                        console.error('Error cargando datos:', error);
                    }
                }

                // Cargar datos cada 30 segundos
                cargarDatos();
                setInterval(cargarDatos, 30000);
            </script>
        </body>
        </html>
    `);
});

// ================================================
// INICIAR SERVIDOR Y BOT
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

client.initialize();

// Manejo de errores no capturados
process.on('uncaughtException', (error) => {
    console.error('Error no capturado:', error);
    db.run('INSERT INTO logs (type, message, data) VALUES (?, ?, ?)',
        ['uncaught_exception', error.message, JSON.stringify(error)]);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Promesa rechazada no manejada:', reason);
    db.run('INSERT INTO logs (type, message, data) VALUES (?, ?, ?)',
        ['unhandled_rejection', reason.toString(), JSON.stringify({reason, promise})]);
});
EOF

# ================================================
# CREAR PACKAGE.JSON
# ================================================
echo -e "\n${CYAN}📦 Creando package.json...${NC}"

cat > "$INSTALL_DIR/package.json" << EOF
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
# INSTALAR DEPENDENCIAS NODE
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias de Node.js...${NC}"
cd "$INSTALL_DIR"
npm install

# ================================================
# CONFIGURAR NGINX (OPCIONAL)
# ================================================
echo -e "\n${CYAN}🌐 Configurando Nginx para el panel...${NC}"
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

ln -sf /etc/nginx/sites-available/wassh-panel /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# ================================================
# INICIAR EL BOT CON PM2
# ================================================
echo -e "\n${CYAN}🚀 Iniciando el bot con PM2...${NC}"
cd "$INSTALL_DIR"
pm2 start bot.js --name wassh-bot
pm2 save
pm2 startup

# ================================================
# CONFIGURAR LOGS AUTOMÁTICOS
# ================================================
echo -e "\n${CYAN}📝 Configurando limpieza automática de logs...${NC}"
cat > /etc/cron.d/wassh-clean << EOF
# Limpiar logs viejos cada día
0 0 * * * root find /sshbot/logs -type f -mtime +7 -delete
0 0 * * * root find /root/.pm2/logs -type f -mtime +7 -delete
EOF

# ================================================
# MOSTRAR INFORMACIÓN FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}${BOLD}📱 BOT WHATSAPP${NC}"
echo -e "   • Nombre: ${GREEN}$BOT_NAME${NC}"
echo -e "   • Estado: ${GREEN}ACTIVO${NC}"
echo -e "   • Gemini AI: ${GREEN}$([ -n "$GEMINI_API_KEY" ] && echo "ACTIVADO" || echo "DESACTIVADO")${NC}"
echo

echo -e "${CYAN}${BOLD}📊 PANEL VPS${NC}"
echo -e "   • URL: ${GREEN}http://$SERVER_IP:$PANEL_PORT${NC}"
echo -e "   • Puerto: ${GREEN}$PANEL_PORT${NC}"
echo -e "   • Nginx: ${GREEN}http://$SERVER_IP${NC} (si está configurado)"
echo

echo -e "${CYAN}${BOLD}📁 RUTAS${NC}"
echo -e "   • Instalación: ${GREEN}/sshbot${NC}"
echo -e "   • Base de datos: ${GREEN}$DB_FILE${NC}"
echo -e "   • Prompt Gemini: ${GREEN}$PROMPT_FILE${NC}"
echo

echo -e "${CYAN}${BOLD}🔄 COMANDOS PM2${NC}"
echo -e "   • Ver logs: ${GREEN}pm2 logs wassh-bot${NC}"
echo -e "   • Reiniciar: ${GREEN}pm2 restart wassh-bot${NC}"
echo -e "   • Detener: ${GREEN}pm2 stop wassh-bot${NC}"
echo

echo -e "${CYAN}${BOLD}📱 ESCANEA EL QR${NC}"
echo -e "   Ejecuta: ${GREEN}pm2 logs wassh-bot${NC} para ver el código QR"
echo

echo -e "${YELLOW}${BOLD}⚠️  IMPORTANTE:${NC}"
echo -e "   1. Escanea el QR con WhatsApp para conectar el bot"
echo -e "   2. El panel VPS está en ${GREEN}http://$SERVER_IP:$PANEL_PORT${NC}"
echo -e "   3. Los representantes atienden de ${GREEN}10:30 a 22:30${NC}"
echo -e "   4. Número de soporte: ${GREEN}https://wa.me/$SUPPORT_NUMBER${NC}"
echo

echo -e "${BLUE}${BOLD}📱 COMANDOS DEL BOT:${NC}"
echo -e "   • /info     - Información del servicio"
echo -e "   • /precios  - Ver precios"
echo -e "   • /soporte  - Contactar representante"
echo -e "   • /android  - Descarga para Android"
echo -e "   • /iphone   - Descarga para iPhone"
echo

echo -e "${GREEN}${BOLD}✨ INSTALACIÓN COMPLETADA - DISFRUTA TU BOT CON GEMINI AI${NC}"
