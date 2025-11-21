#!/bin/bash

# Script para iniciar SUMLY con ngrok
echo "╔════════════════════════════════════════════════╗"
echo "║     🚀 Iniciando SUMLY Backend con ngrok      ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

cd sumly_backend

# Instalar dependencias si no existen
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias..."
    npm install
fi

# Iniciar el servidor en segundo plano
echo "🔧 Iniciando servidor backend..."
npm run dev &
BACKEND_PID=$!

# Esperar a que el servidor esté listo
echo "⏳ Esperando a que el servidor inicie..."
sleep 5

# Verificar si el servidor está corriendo
if ! ps -p $BACKEND_PID > /dev/null; then
   echo "❌ Error: El servidor no pudo iniciarse"
   exit 1
fi

echo "✅ Servidor backend iniciado (PID: $BACKEND_PID)"
echo ""

# Iniciar ngrok
echo "🌐 Iniciando túnel ngrok..."
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  IMPORTANTE: Copia la URL de ngrok que        ║"
echo "║  aparecerá abajo y úsala en:                   ║"
echo "║  sumly_app/lib/config/api_config.dart         ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

cd ..
ngrok http 5000

# Cuando ngrok se cierre, también cerrar el backend
echo ""
echo "🛑 Cerrando servidor backend..."
kill $BACKEND_PID
echo "✅ Servidor cerrado correctamente"
