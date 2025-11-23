#!/bin/bash

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        🔑 Obtener SHA-1 para Google Sign-In        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar si keytool está instalado
if ! command -v keytool &> /dev/null; then
    echo -e "${RED}❌ keytool no está instalado${NC}"
    echo "keytool viene con Java JDK"
    echo "Instala Java JDK y vuelve a intentar"
    exit 1
fi

# Buscar debug.keystore en ubicaciones comunes
KEYSTORE_LOCATIONS=(
    "$HOME/.android/debug.keystore"
    "$USERPROFILE/.android/debug.keystore"
    "C:\\Users\\$USERNAME\\.android\\debug.keystore"
)

KEYSTORE_PATH=""
for location in "${KEYSTORE_LOCATIONS[@]}"; do
    if [ -f "$location" ]; then
        KEYSTORE_PATH="$location"
        break
    fi
done

if [ -z "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}⚠️  No se encontró debug.keystore${NC}"
    echo ""
    echo "Necesitas compilar la app primero para generar el keystore:"
    echo -e "${GREEN}cd sumly_app${NC}"
    echo -e "${GREEN}flutter build apk --debug${NC}"
    echo ""
    echo "Después ejecuta este script nuevamente"
    exit 1
fi

echo -e "${GREEN}✅ Keystore encontrado en: $KEYSTORE_PATH${NC}"
echo ""

# Obtener SHA-1
echo -e "${BLUE}📋 Obteniendo SHA-1...${NC}"
echo ""

SHA1=$(keytool -list -v -keystore "$KEYSTORE_PATH" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | awk '{print $2}')

if [ -z "$SHA1" ]; then
    echo -e "${RED}❌ Error al obtener SHA-1${NC}"
    exit 1
fi

echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  ✅ SHA-1 OBTENIDO                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Tu SHA-1 (debug):${NC}"
echo -e "${BLUE}$SHA1${NC}"
echo ""

# También obtener SHA-256 por si acaso
SHA256=$(keytool -list -v -keystore "$KEYSTORE_PATH" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA256:" | awk '{print $2}')

if [ -n "$SHA256" ]; then
    echo -e "${YELLOW}Tu SHA-256 (opcional):${NC}"
    echo -e "${BLUE}$SHA256${NC}"
    echo ""
fi

echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              CÓMO AGREGAR A FIREBASE               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo "1. Ve a Firebase Console: https://console.firebase.google.com/"
echo "2. Selecciona tu proyecto 'sumly'"
echo "3. Haz clic en el ícono de engranaje ⚙️  > Project Settings"
echo "4. Desplázate hasta 'Your apps' y selecciona tu app Android"
echo "5. En 'SHA certificate fingerprints', haz clic en 'Add fingerprint'"
echo "6. Pega el SHA-1 de arriba"
echo "7. Guarda"
echo ""
echo -e "${YELLOW}IMPORTANTE:${NC} Espera 5-10 minutos después de agregar el SHA-1"
echo "antes de probar Google Sign-In"
echo ""
