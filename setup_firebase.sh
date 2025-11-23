#!/bin/bash

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🔥 Configuración de Firebase para SUMLY   🔥   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar si Firebase CLI está instalada
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Firebase CLI no está instalada${NC}"
    echo ""
    echo "Para instalar Firebase CLI, ejecuta:"
    echo -e "${GREEN}npm install -g firebase-tools${NC}"
    echo ""
    read -p "¿Quieres instalarla ahora? (s/n): " install_choice
    if [ "$install_choice" = "s" ] || [ "$install_choice" = "S" ]; then
        npm install -g firebase-tools
    else
        echo -e "${RED}❌ Firebase CLI es necesaria para continuar${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Firebase CLI instalada${NC}"
echo ""

# Login a Firebase
echo -e "${BLUE}📝 Paso 1: Login a Firebase${NC}"
firebase login
echo ""

# Crear proyecto Firebase
echo -e "${BLUE}📝 Paso 2: Seleccionar/Crear Proyecto Firebase${NC}"
echo "Ve a https://console.firebase.google.com/ y:"
echo "1. Crea un nuevo proyecto llamado 'Sumly' (o usa uno existente)"
echo "2. Habilita Google Sign-In en Authentication > Sign-in method"
echo ""
read -p "Presiona ENTER cuando hayas creado el proyecto..."

# Listar proyectos
echo ""
echo -e "${BLUE}Proyectos disponibles:${NC}"
firebase projects:list
echo ""
read -p "Ingresa el ID del proyecto Firebase (ej: sumly-12345): " project_id

# Configurar proyecto
firebase use "$project_id"
echo ""

# Verificar si FlutterFire CLI está instalada
if ! command -v flutterfire &> /dev/null; then
    echo -e "${YELLOW}⚠️  FlutterFire CLI no está instalada${NC}"
    echo ""
    echo "Para instalar FlutterFire CLI, ejecuta:"
    echo -e "${GREEN}dart pub global activate flutterfire_cli${NC}"
    echo ""
    read -p "¿Quieres instalarla ahora? (s/n): " install_flutterfire
    if [ "$install_flutterfire" = "s" ] || [ "$install_flutterfire" = "S" ]; then
        dart pub global activate flutterfire_cli

        # Agregar al PATH si no está
        export PATH="$PATH:$HOME/.pub-cache/bin"
        echo ""
        echo -e "${GREEN}✅ FlutterFire CLI instalada${NC}"
        echo ""
        echo -e "${YELLOW}NOTA: Es posible que necesites cerrar y abrir la terminal para que el comando 'flutterfire' funcione${NC}"
    else
        echo -e "${RED}❌ FlutterFire CLI es necesaria para continuar${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}📝 Paso 3: Configurar Flutter con Firebase${NC}"
cd sumly_app

# Ejecutar flutterfire configure
flutterfire configure \
  --project="$project_id" \
  --out=lib/firebase_options.dart \
  --ios-bundle-id=com.example.sumlyApp \
  --android-package-name=com.example.sumly_app

echo ""
echo -e "${GREEN}✅ Configuración de Firebase completada!${NC}"
echo ""

# Verificar archivos de configuración
echo -e "${BLUE}📝 Paso 4: Verificar archivos de configuración${NC}"
echo ""

if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✅ google-services.json encontrado${NC}"
else
    echo -e "${YELLOW}⚠️  google-services.json NO encontrado${NC}"
    echo "   Descárgalo desde Firebase Console y colócalo en:"
    echo "   sumly_app/android/app/google-services.json"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ GoogleService-Info.plist encontrado${NC}"
else
    echo -e "${YELLOW}⚠️  GoogleService-Info.plist NO encontrado${NC}"
    echo "   Descárgalo desde Firebase Console y colócalo en:"
    echo "   sumly_app/ios/Runner/GoogleService-Info.plist"
fi

echo ""
echo -e "${BLUE}📝 Paso 5: Configurar SHA-1 para Google Sign-In (Android)${NC}"
echo ""
echo "Para obtener el SHA-1, ejecuta:"
echo -e "${GREEN}cd android && ./gradlew signingReport${NC}"
echo ""
echo "Luego:"
echo "1. Copia el SHA-1 del bloque 'Task :app:signingReport' > 'Variant: debug'"
echo "2. Ve a Firebase Console > Project Settings > Tu app Android"
echo "3. Agrega el SHA-1 en 'SHA certificate fingerprints'"
echo ""
read -p "Presiona ENTER para ver el SHA-1..."

cd android
if [ -f "gradlew" ]; then
    ./gradlew signingReport | grep "SHA1:"
else
    echo -e "${RED}❌ gradlew no encontrado${NC}"
fi
cd ..

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            ✅ CONFIGURACIÓN COMPLETADA ✅           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo "1. Agrega el SHA-1 a Firebase Console (instrucciones arriba)"
echo "2. Ejecuta: flutter pub get"
echo "3. Ejecuta: flutter run"
echo "4. Prueba el botón 'Continuar con Google' en login"
echo ""
echo -e "${YELLOW}NOTA: Si tienes problemas, consulta FIREBASE_SETUP.md${NC}"
echo ""
