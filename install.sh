#!/bin/bash
# ================================================
# BOT WHATSAPP - VERSIÓN SOLO BOT CON GEMINI AI
# ================================================
# CARACTERÍSTICAS:
# ✅ GEMINI AI INTEGRADO
# ✅ SIN CREACIÓN AUTOMÁTICA DE USUARIOS SSH
# ✅ SIN PAGOS AUTOMÁTICOS (MERCADOPAGO DESACTIVADO)
# ✅ SIN ESTADOS AUTOMÁTICOS EN WHATSAPP
# ✅ SIN PANEL WEB
# ✅ SQLITE3 INSTALADO AUTOMÁTICAMENTE
# ✅ NOMBRE DINÁMICO (SOLO VISUAL, RUTA FIJA /sshbot)
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
║              🤖 BOT WHATSAPP - VERSIÓN GEMINI               ║
║            ✅ SOLO BOT · SIN PANEL · SIN SSH                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS:${NC}"
echo -e "  🤖 ${CYAN}Gemini AI${NC} - Integración con Google Gemini"
echo -e "  💬 ${YELLOW}Prompt personalizado${NC} - Asistente de ventas configurado"
echo -e "  📱 ${PURPLE}Android/iPhone${NC} - Información para ambos sistemas"
echo -e "  🚫 ${RED}Sin SSH${NC} - Sin creación automática de usuarios"
echo -e "  🚫 ${RED}Sin MercadoPago${NC} - Sin pagos automáticos"
echo -e "  🚫 ${RED}Sin estados${NC} - No publica estados en WhatsApp"
echo -e "  🚫 ${RED}Sin panel web${NC} - Solo bot de atención"
echo -e "  📁 ${CYAN}Ruta fija${NC} - /sshbot (el nombre es solo visual)"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    exit 1
fi

# ================================================
# INSTALAR SQLITE3 (NECESARIO PARA LA BASE DE DATOS)
# ================================================
echo -e "\n${CYAN}${BOLD}📦 INSTALANDO SQLITE3...${NC}"
apt-get update -y
apt-get install -y sqlite3

# Verificar instalación
if command -v sqlite3 &> /dev/null; then
    echo -e "${GREEN}✅ SQLite3 instalado correctamente: $(sqlite3 --version)${NC}"
else
    echo -e "${RED}❌ Error instalando SQLite3${NC}"
    exit 1
fi

# ================================================
# CONFIGURACIÓN DEL NOMBRE
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT${NC}"

# Pedir nombre
read -p "📝 NOMBRE PARA TU BOT (ej: TIENDA LIBRE|AR o SERVERTUC): " BOT_NAME
BOT_NAME=${BOT_NAME:-"TIENDA LIBRE|AR"}

# Crear versión segura para procesos
SAFE_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
SAFE_NAME=${SAFE_NAME:-"bot"}

echo -e "\n${GREEN}✅ NOMBRE CONFIGURADO:${NC}"
echo -e "   • Nombre visible: ${CYAN}$BOT_NAME${NC}"
echo -e "   • Nombre para procesos: ${CYAN}$SAFE_NAME${NC}"

# ================================================
# RUTAS FIJAS
# ================================================
INSTALL_DIR="/sshbot"
PROCESS_NAME="wassh-bot"
SESSION_DIR="/root/.wppconnect/session"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
INFO_FILE="$INSTALL_DIR/config/info.txt"
PROMPT_FILE="$INSTALL_DIR/config/gemini_prompt.txt"

echo -e "\n${YELLOW}📁 RUTAS FIJAS:${NC}"
echo -e "   • Instalación: ${CYAN}$INSTALL_DIR${NC}"
echo -e "   • Proceso PM2: ${CYAN}$PROCESS_NAME${NC}"
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
if command -v pm2 &> /dev/null; then
    pm2 list | grep -E "(wassh-bot|bot)" | awk '{print $2}' | xargs -r pm2 delete 2>/dev/null || true
    pm2 kill 2>/dev/null || true
fi
pkill -f chrome 2>/dev/null || true
pkill -f node 2>/dev/null || true

# Limpiar directorios
rm -rf /sshbot 2>/dev/null
rm -rf /root/.wppconnect 2>/dev/null
rm -rf /root/.pm2/logs/* 2>/dev/null

echo -e "${GREEN}✅ Limpieza completada${NC}"

# ================================================
# CREAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
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

# Precios (solo informativos)
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
        "safe_name": "$SAFE_NAME",
        "version": "1.0-GEMINI-ONLY",
        "server_ip": "$SERVER_IP",
        "test_hours": $TEST_HOURS,
        "info_file": "$INFO_FILE",
        "process_name": "$PROCESS_NAME"
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
        "sessions": "$SESSION_DIR"
    },
    "features": {
        "ssh_creation": false,
        "automatic_payments": false,
        "whatsapp_status": false,
        "panel_vps": false
    }
}
EOF

# ================================================
# CREAR BASE DE DATOS SIMPLIFICADA
# ================================================
echo -e "\n${CYAN}🗄️ Creando base de datos SQLite...${NC}"

sqlite3 "$DB_FILE" << 'SQL'
-- Tabla de usuarios (solo para registro)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT UNIQUE,
    name TEXT,
    tipo TEXT DEFAULT 'test',
    test_start DATETIME,
    test_expires DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Control de pruebas diarias
CREATE TABLE IF NOT EXISTS daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);

-- Registro de conversaciones para Gemini
CREATE TABLE IF NOT EXISTS conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    message TEXT,
    response TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Sistema de estados del menú
CREATE TABLE IF NOT EXISTS user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Logs del sistema
CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_conversations_phone ON conversations(phone);
CREATE INDEX IF NOT EXISTS idx_conversations_created ON conversations(created_at);
SQL

echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# INSTALAR DEPENDENCIAS DEL SISTEMA
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
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - 2>/dev/null || true
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Otras dependencias
echo -e "${YELLOW}📦 Instalando utilidades...${NC}"
apt-get install -y jq curl wget git unzip

# ================================================
# INSTALAR PM2
# ================================================
echo -e "\n${CYAN}📦 Instalando PM2...${NC}"
npm install -g pm2

# ================================================
# CREAR PACKAGE.JSON
# ================================================
echo -e "\n${CYAN}📦 Creando package.json...${NC}"

cat > "$INSTALL_DIR/package.json" << 'EOF'
{
    "name": "wassh-bot-gemini",
    "version": "1.0.0",
    "description": "Bot WhatsApp con Gemini AI",
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
        "sqlite3": "^5.1.6",
        "axios": "^1.6.0",
        "moment": "^2.29.4"
    }
}
EOF

# ================================================
# CREAR ARCHIVO PRINCIPAL DEL BOT (SIN EXPRESS)
# ================================================
echo -e "\n${CYAN}📝 Creando archivo principal del bot...${NC}"

cat > "$INSTALL_DIR/bot.js" << 'EOF'
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

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
        ],
        executablePath: config.paths.chromium
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
        
        // Combinar prompt del sistema con el mensaje del usuario
        const fullPrompt = `${promptSistema}\n\nCliente: ${mensaje}\nAsistente:`;
        
        const result = await model.generateContent(fullPrompt);
        const response = await result.response;
        const text = response.text();
        
        // Guardar conversación
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
                `Para contratar, escribe /soporte y te transferiré con un representante (disponibles de 10:30 a 22:30)`);
            break;
            
        case '/soporte':
            await message.reply(`Te transfiero con un representante para que puedas contratar el servicio.\n\n` +
                `🔗 *Enlace directo:* ${config.links.support}\n\n` +
                `🕐 Horario de atención: 10:30 a 22:30`);
            break;
            
        case '/android':
            await message.reply(`📱 *DESCARGA PARA ANDROID*\n\n` +
                `✅ Compatible con PERSONAL Abono y Prepago\n\n` +
                `🔗 Link de descarga:\n${config.links.app_android}\n\n` +
                `Después de instalar, escribe /soporte para que te ayuden con la configuración.`);
            break;
            
        case '/iphone':
            await message.reply(`📱 *DESCARGA PARA IPHONE*\n\n` +
                `✅ Compatible con PERSONAL Abono y Prepago\n\n` +
                `Para iPhone, el proceso es diferente. Por favor, contacta a un representante con /soporte para que te guíen en la instalación.`);
            break;
            
        default:
            await message.reply(`Comandos disponibles:\n` +
                `/info - Información del servicio\n` +
                `/precios - Ver precios\n` +
                `/soporte - Contactar representante\n` +
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
    
    // Guardar QR como imagen (opcional)
    const qrPath = path.join(config.paths.qr_codes, 'qr_latest.txt');
    fs.writeFileSync(qrPath, qr);
});

client.on('ready', () => {
    console.log('\n✅ BOT CONECTADO A WHATSAPP\n');
    console.log(`🤖 Bot: ${config.bot.name}`);
    console.log(`🤖 Gemini: ${config.gemini.enabled ? 'ACTIVADO' : 'DESACTIVADO'}`);
    console.log(`📱 Comandos: /info, /precios, /soporte, /android, /iphone\n`);
    
    db.run(
        'INSERT INTO logs (type, message) VALUES (?, ?)',
        ['system', 'Bot conectado a WhatsApp']
    );
});

client.on('message', async (message) => {
    try {
        const numero = message.from;
        
        // Ignorar mensajes de grupos
        if (message.from.includes('@g.us')) return;
        
        console.log(`📨 Mensaje de ${numero}: ${message.body}`);
        
        // Registrar usuario si no existe
        db.run(
            'INSERT OR IGNORE INTO users (phone, created_at) VALUES (?, CURRENT_TIMESTAMP)',
            [numero]
        );
        
        // Verificar si es un comando
        if (message.body.startsWith('/')) {
            await manejarComandos(message);
            return;
        }
        
        // Si no es comando y Gemini está activado, procesar con IA
        const respuestaIA = await procesarConGemini(message.body, numero);
        
        if (respuestaIA) {
            await message.reply(respuestaIA);
        }
    } catch (error) {
        console.error('Error procesando mensaje:', error);
    }
});

// ================================================
// INICIAR BOT
// ================================================
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

console.log('🚀 Iniciando bot WhatsApp...');
EOF

# ================================================
# INSTALAR DEPENDENCIAS NODE
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias de Node.js...${NC}"
cd "$INSTALL_DIR"
npm install

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
echo -e "\n${CYAN}📝 Configurando limpieza automática...${NC}"
cat > /etc/cron.d/wassh-clean << EOF
# Limpiar logs viejos cada día
0 0 * * * root find /sshbot/logs -type f -mtime +7 -delete
0 0 * * * root find /root/.pm2/logs -type f -mtime +7 -delete
0 0 * * * root find /sshbot/qr_codes -type f -mtime +1 -delete
EOF

chmod 644 /etc/cron.d/wassh-clean 2>/dev/null || true

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

echo -e "${CYAN}${BOLD}📁 RUTAS${NC}"
echo -e "   • Instalación: ${GREEN}/sshbot${NC}"
echo -e "   • Base de datos: ${GREEN}$DB_FILE${NC}"
echo -e "   • Prompt Gemini: ${GREEN}$PROMPT_FILE${NC}"
echo

echo -e "${CYAN}${BOLD}🔄 COMANDOS PM2${NC}"
echo -e "   • Ver logs: ${GREEN}pm2 logs wassh-bot${NC}"
echo -e "   • Ver QR: ${GREEN}pm2 logs wassh-bot | grep -A 10 \"ESCANEA\"${NC}"
echo -e "   • Reiniciar: ${GREEN}pm2 restart wassh-bot${NC}"
echo -e "   • Detener: ${GREEN}pm2 stop wassh-bot${NC}"
echo

echo -e "${CYAN}${BOLD}📱 COMANDOS DEL BOT${NC}"
echo -e "   • ${GREEN}/info${NC}     - Información del servicio"
echo -e "   • ${GREEN}/precios${NC}  - Ver precios"
echo -e "   • ${GREEN}/soporte${NC}  - Contactar representante"
echo -e "   • ${GREEN}/android${NC}  - Descarga para Android"
echo -e "   • ${GREEN}/iphone${NC}   - Descarga para iPhone"
echo

echo -e "${YELLOW}${BOLD}⚠️  IMPORTANTE:${NC}"
echo -e "   • Escanea el QR que aparece en los logs"
echo -e "   • Los representantes atienden de ${GREEN}10:30 a 22:30${NC}"
echo -e "   • Número de soporte: ${GREEN}https://wa.me/$SUPPORT_NUMBER${NC}"
echo

echo -e "${GREEN}${BOLD}✅ MOSTRANDO LOGS (ESPERA EL QR)...${NC}"
echo -e "${BLUE}Presiona Ctrl+C para salir de los logs cuando veas el QR${NC}"
sleep 2
pm2 logs wassh-bot
