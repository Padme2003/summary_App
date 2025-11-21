@echo off
REM Script para iniciar SUMLY con ngrok en Windows
echo ========================================================
echo      Iniciando SUMLY Backend con ngrok
echo ========================================================
echo.

cd sumly_backend

REM Instalar dependencias si no existen
if not exist "node_modules" (
    echo Instalando dependencias...
    call npm install
)

REM Iniciar el servidor en segundo plano
echo Iniciando servidor backend...
start "SUMLY Backend" cmd /k "npm run dev"

REM Esperar a que el servidor esté listo
echo Esperando a que el servidor inicie...
timeout /t 5 /nobreak > nul

echo Servidor backend iniciado
echo.

REM Volver al directorio raíz
cd ..

REM Iniciar ngrok
echo Iniciando tunel ngrok...
echo.
echo ========================================================
echo   IMPORTANTE: Copia la URL de ngrok que aparecera
echo   abajo y usala en:
echo   sumly_app/lib/config/api_config.dart
echo ========================================================
echo.

ngrok http 5000
