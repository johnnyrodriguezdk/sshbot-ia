#!/bin/bash
# ================================================
# BOT WHATSAPP - VERSIÓN MENÚ INTERACTIVO + GEMINI AI
# ================================================
# CARACTERÍSTICAS:
# ✅ GEMINI AI OMNIPRESENTE (RESPONDE AUTOMÁTICAMENTE)
# ✅ MENÚ INTERACTIVO CON OPCIONES
# ✅ SIN CREACIÓN AUTOMÁTICA DE USUARIOS SSH
# ✅ SIN PAGOS AUTOMÁTICOS (MERCADOPAGO DESACTIVADO)
# ✅ SIN ESTADOS AUTOMÁTICOS EN WHATSAPP
# ✅ SIN PANEL WEB
# ✅ SQLITE3 INSTALADO AUTOMÁTICAMENTE
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
║              🤖 BOT WHATSAPP - VERSIÓN MENÚ                 ║
║         ✅ MENÚ INTERACTIVO · ✅ GEMINI OMNIPRESENTE        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS:${NC}"
echo -e "  🤖 ${CYAN}Gemini AI Omnipresente${NC} - Responde automáticamente"
echo -e "  📋 ${YELLOW}Menú interactivo${NC} - Opciones numeradas"
echo -e "  📱 ${PURPLE}Android/iPhone${NC} - Información para ambos sistemas"
echo -e "  🚫 ${RED}Sin SSH${NC} - Sin creación automática de usuarios"
echo -e "  🚫 ${RED}Sin MercadoPago${NC} - Sin pagos automáticos"
echo -e "  🚫 ${RED}Sin panel web${NC} - Solo bot de atención"
echo -e "  📁 ${CYAN}Ruta fija${NC} - /sshbot"
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
read -p "📝 NOMBRE PARA TU BOT (ej: LIBRE|AR): " BOT_NAME
BOT_NAME=${BOT_NAME:-"LIBRE|AR"}

echo -e "\n${GREEN}✅ NOMBRE CONFIGURADO:${NC}"
echo -e "   • Nombre visible: ${CYAN}$BOT_NAME${NC}"

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

if command -v pm2 &> /dev/null; then
    pm2 list | grep -E "(wassh-bot|bot)" | awk '{print $2}' | xargs -r pm2 delete 2>/dev/null || true
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
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$SESSION_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 "$SESSION_DIR"
echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# CONFIGURACIÓN DE GEMINI AI
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CONFIGURACIÓN DE IA GEMINI${NC}"
read -p "🔑 Ingresa tu API Key de Google Gemini: " GEMINI_API_KEY
GEMINI_API_KEY=${GEMINI_API_KEY:-""}

if [ -n "$GEMINI_API_KEY" ]; then
    echo -e "${GREEN}✅ API Key de Gemini configurada${NC}"
else
    echo -e "${RED}❌ Es necesaria una API Key para el funcionamiento del bot${NC}"
    exit 1
fi

# ================================================
# GUARDAR PROMPT DE GEMINI
# ================================================
echo -e "\n${CYAN}💬 Guardando prompt personalizado...${NC}"
cat > "$PROMPT_FILE" << 'PROMPT_EOF'
Eres un asistente virtual de una empresa que vende servicio de internet ilimitado para celulares Android y iPhone llamada $BOT_NAME.

INFORMACIÓN IMPORTANTE QUE DEBES SABER:
- El servicio funciona SOLO para la empresa PERSONAL (abono y prepago)
- NO disponible para Movistar, Tuenti o Claro
- El servicio se vende como archivos de configuración (servidores, servers, o "llavecita")
- El método de pago es por transferencia bancaria
- NO debes realizar ventas ni pedir comprobantes
- Si el cliente quiere contratar, debes ofrecer transferirlo con un representante
- Horario de representantes: 10:30 a 22:30
- Los precios son: 7 días: $PRICE_7D, 15 días: $PRICE_15D, 30 días: $PRICE_30D, 50 días: $PRICE_50D
- Link de descarga Android: $APP_LINK
- Link de representante: https://wa.me/$SUPPORT_NUMBER

REGLAS DE CONVERSACIÓN:
1. SIEMPRE que un cliente envíe un mensaje, debes responder con el menú principal:

*⚙️ $BOT_NAME ChatBot* 🧑‍💻
             ⸻↓⸻
> 🕋 BIENVENIDO A TIENDA $BOT_NAME

1 ⁃📢 INFORMACIÓN
2 ⁃🏷️ PRECIOS
3 ⁃🛍️ REVENDER SERVICIO
4 ⁃👥 HABLAR CON UN REPRESENTANTE

👉 Elige una opción (1-4):

⚠️ Si necesitas hablar con un representante nuestro horario de atención es 10:30 a 22:30hs.

2. Cuando el cliente responda con un número:
   - Opción 1: Dar información detallada del servicio (qué es, cómo funciona, disponibilidad Android/iPhone, solo Personal)
   - Opción 2: Mostrar los precios y mencionar que el pago es por transferencia
   - Opción 3: Explicar que para revender deben contactar directamente con un representante
   - Opción 4: Proporcionar el enlace del representante y recordar el horario

3. Si el cliente escribe algo que no sea un número, muestra el menú nuevamente.

Sé amable, servicial y mantén siempre el enfoque en la empresa $BOT_NAME.
PROMPT_EOF

echo -e "${GREEN}✅ Prompt guardado${NC}"

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

# Reemplazar variables en el prompt
sed -i "s/\$BOT_NAME/$BOT_NAME/g" "$PROMPT_FILE"
sed -i "s/\$PRICE_7D/$PRICE_7D/g" "$PROMPT_FILE"
sed -i "s/\$PRICE_15D/$PRICE_15D/g" "$PROMPT_FILE"
sed -i "s/\$PRICE_30D/$PRICE_30D/g" "$PROMPT_FILE"
sed -i "s/\$PRICE_50D/$PRICE_50D/g" "$PROMPT_FILE"
sed -i "s/\$APP_LINK/$APP_LINK/g" "$PROMPT_FILE"
sed -i "s/\$SUPPORT_NUMBER/$SUPPORT_NUMBER/g" "$PROMPT_FILE"

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
        "version": "2.0-MENU-GEMINI",
        "test_hours": $TEST_HOURS,
        "info_file": "$INFO_FILE",
        "process_name": "$PROCESS_NAME"
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
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "$SESSION_DIR"
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

CREATE TABLE IF NOT EXISTS conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    message TEXT,
    response TEXT,
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
# INSTALAR DEPENDENCIAS DEL SISTEMA
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias del sistema...${NC}"
apt-get update -y
apt-get install -y curl wget git unzip

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
    "name": "wassh-bot-menu",
    "version": "2.0.0",
    "description": "Bot WhatsApp con menú interactivo y Gemini AI",
    "main": "bot.js",
    "scripts": {
        "start": "node bot.js",
        "pm2": "pm2 start bot.js --name wassh-bot",
        "pm2-logs": "pm2 logs wassh-bot"
    },
    "dependencies": {
        "@google/generative-ai": "^0.1.3",
        "whatsapp-web.js": "^1.23.0",
        "qrcode-terminal": "^0.12.0",
        "sqlite3": "^5.1.6"
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
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

// Configuración
const config = JSON.parse(fs.readFileSync('/sshbot/config/config.json'));
const promptSistema = fs.readFileSync(config.gemini.prompt_file, 'utf8');

// Inicializar Gemini
const genAI = new GoogleGenerativeAI(config.gemini.api_key);
const model = genAI.getGenerativeModel({ model: "gemini-pro" });

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
// FUNCIÓN PARA PROCESAR CON GEMINI
// ================================================
async function procesarConGemini(mensaje, numero, nombreUsuario = 'Cliente') {
    try {
        // Obtener información del usuario
        const user = await new Promise((resolve) => {
            db.get('SELECT * FROM users WHERE phone = ?', [numero], (err, row) => {
                resolve(row);
            });
        });

        // Crear contexto para Gemini
        const contexto = `
Información del usuario:
- Nombre: ${nombreUsuario}
- Número: ${numero}
- Primera vez: ${!user ? 'Sí' : 'No'}
- Fecha registro: ${user?.created_at || 'Nuevo'}
- Hora actual: ${new Date().toLocaleTimeString()}

Mensaje del cliente: "${mensaje}"

Instrucciones: Basado en el mensaje del cliente y la información de la empresa, genera una respuesta apropiada. Recuerda siempre incluir el menú cuando sea apropiado.
`;

        const fullPrompt = `${promptSistema}\n\n${contexto}`;
        
        // Generar respuesta
        const result = await model.generateContent(fullPrompt);
        const response = await result.response;
        const text = response.text();
        
        // Guardar conversación
        db.run(
            'INSERT INTO conversations (phone, message, response) VALUES (?, ?, ?)',
            [numero, mensaje.substring(0, 500), text.substring(0, 500)]
        );
        
        return text;
    } catch (error) {
        console.error('Error con Gemini:', error);
        
        // Respuesta de respaldo en caso de error
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
// EVENTOS WHATSAPP
// ================================================
client.on('qr', (qr) => {
    console.log('\n📱 ESCANEA ESTE QR CON WHATSAPP:\n');
    qrcode.generate(qr, { small: true });
    
    // Guardar QR
    const qrPath = path.join(config.paths.qr_codes, 'qr_latest.txt');
    fs.writeFileSync(qrPath, qr);
    console.log(`📁 QR también guardado en: ${qrPath}`);
});

client.on('ready', () => {
    console.log('\n✅ BOT CONECTADO A WHATSAPP\n');
    console.log(`🤖 Bot: ${config.bot.name}`);
    console.log(`🤖 Gemini: ACTIVADO (modelo: gemini-pro)`);
    console.log(`📱 Modo: Menú interactivo + IA Omnipresente`);
    console.log(`⏰ Los representantes atienden de 10:30 a 22:30hs\n`);
    
    db.run('INSERT INTO logs (type, message) VALUES (?, ?)',
        ['system', 'Bot conectado a WhatsApp']);
});

client.on('message', async (message) => {
    try {
        const numero = message.from;
        
        // Ignorar mensajes de grupos y estados
        if (message.from.includes('@g.us') || message.from.includes('status')) return;
        
        console.log(`📨 Mensaje de ${numero}: ${message.body.substring(0, 50)}${message.body.length > 50 ? '...' : ''}`);
        
        // Registrar o actualizar usuario
        db.get('SELECT * FROM users WHERE phone = ?', [numero], async (err, user) => {
            if (!user) {
                db.run('INSERT INTO users (phone, name, last_menu) VALUES (?, ?, ?)',
                    [numero, message._data?.notifyName || 'Cliente', 'main']);
                console.log(`👤 Nuevo usuario: ${numero}`);
            }
            
            // Marcar que el usuario está escribiendo (simulado)
            await message.sendTyping();
            
            // Procesar mensaje con Gemini
            const respuesta = await procesarConGemini(
                message.body, 
                numero, 
                message._data?.notifyName || 'Cliente'
            );
            
            if (respuesta) {
                await message.reply(respuesta);
                console.log(`✅ Respuesta enviada a ${numero}`);
            }
        });
        
    } catch (error) {
        console.error('Error procesando mensaje:', error);
    }
});

// ================================================
// INICIAR BOT
// ================================================
console.log('🚀 Iniciando bot con menú interactivo...');
client.initialize();

// Manejo de errores
process.on('uncaughtException', (error) => {
    console.error('❌ Error no capturado:', error.message);
    db.run('INSERT INTO logs (type, message, data) VALUES (?, ?, ?)',
        ['error', error.message, JSON.stringify(error)]);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ Promesa rechazada:', reason);
});

// Mensaje de inicio
console.log('📱 Bot iniciado. Esperando QR...');
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
# CONFIGURAR CRON
# ================================================
echo -e "\n${CYAN}📝 Configurando limpieza automática...${NC}"
cat > /etc/cron.d/wassh-clean << EOF
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
echo "╔════════════════════════════════════════════════════╗"
echo "║     ✅ INSTALACIÓN COMPLETADA                      ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}${BOLD}📱 BOT WHATSAPP CON MENÚ${NC}"
echo -e "   • Nombre: ${GREEN}$BOT_NAME${NC}"
echo -e "   • Estado: ${GREEN}ACTIVO${NC}"
echo -e "   • Gemini: ${GREEN}ACTIVADO (modelo: gemini-pro)${NC}"
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
echo -e ""
echo -e "   👉 Elige una opción (1-4):"
echo -e ""
echo -e "   ⚠️ Horario representantes: 10:30 a 22:30hs"
echo

echo -e "${CYAN}${BOLD}🔄 COMANDOS ÚTILES:${NC}"
echo -e "   • Ver QR: ${GREEN}pm2 logs wassh-bot${NC}"
echo -e "   • Ver logs: ${GREEN}pm2 logs wassh-bot${NC}"
echo -e "   • Reiniciar: ${GREEN}pm2 restart wassh-bot${NC}"
echo -e "   • Detener: ${GREEN}pm2 stop wassh-bot${NC}"
echo

echo -e "${YELLOW}${BOLD}⚠️  IMPORTANTE:${NC}"
echo -e "   • El bot responde AUTOMÁTICAMENTE a TODOS los mensajes"
echo -e "   • Usa el modelo gemini-pro (más estable)"
echo -e "   • Siempre mostrará el menú y procesará las opciones"
echo -e "   • Número de soporte: ${GREEN}https://wa.me/$SUPPORT_NUMBER${NC}"
echo

echo -e "${GREEN}${BOLD}✅ MOSTRANDO LOGS (ESPERA EL QR)...${NC}"
echo -e "${BLUE}Presiona Ctrl+C para salir de los logs (el bot sigue corriendo)${NC}"
sleep 2
pm2 logs wassh-bot
